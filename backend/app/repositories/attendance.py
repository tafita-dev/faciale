from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.models.attendance import AttendanceLog
from typing import Optional, List, Tuple
from datetime import datetime

class AttendanceRepository:
    def __init__(self, db: AsyncIOMotorDatabase = None):
        self.db = db or get_database()
        self.collection = self.db["attendance_logs"]

    async def create_log(self, log: AttendanceLog) -> AttendanceLog:
        doc = log.model_dump(by_alias=True)
        await self.collection.insert_one(doc)
        return log

    async def init_indexes(self):
        import pymongo
        await self.collection.create_index([("timestamp", pymongo.DESCENDING)])
        await self.collection.create_index([("employee_id", pymongo.ASCENDING), ("timestamp", pymongo.DESCENDING)])
        await self.collection.create_index([("org_id", pymongo.ASCENDING)])

    async def count_logs_today(self, org_id: str, employee_id: str) -> int:
        """Count successful logs for an employee today."""
        from datetime import timezone
        now = datetime.now(timezone.utc)
        start_of_today = datetime.combine(now.date(), datetime.min.time()).replace(tzinfo=timezone.utc)
        
        return await self.collection.count_documents({
            "org_id": org_id,
            "employee_id": employee_id,
            "status": {"$in": ["success", "present", "late"]},
            "timestamp": {"$gte": start_of_today}
        })

    async def get_last_success_log(self, org_id: str, employee_id: str) -> Optional[AttendanceLog]:
        import pymongo
        doc = await self.collection.find_one(
            {
                "org_id": org_id,
                "employee_id": employee_id,
                "status": {"$in": ["success", "present", "late"]}
            },
            sort=[("timestamp", pymongo.DESCENDING)]
        )
        if doc:
            return AttendanceLog(**doc)
        return None

    async def find_open_log(self, org_id: str, employee_id: str) -> Optional[AttendanceLog]:
        """Find a log that has a check_in but no check_out for today."""
        now = datetime.now()
        start_of_today = datetime.combine(now.date(), datetime.min.time())
        
        doc = await self.collection.find_one({
            "org_id": org_id,
            "employee_id": employee_id,
            "status": {"$in": ["success", "present", "late"]},
            "check_in": {"$exists": True, "$gte": start_of_today},
            "check_out": None
        })
        if doc:
            return AttendanceLog(**doc)
        return None

    async def update_log(self, log_id: str, update_data: dict):
        await self.collection.update_one(
            {"_id": log_id},
            {"$set": update_data}
        )

    async def get_today_stats(self, org_id: str, start_of_today: datetime, late_threshold: datetime, user_id: Optional[str] = None) -> dict:
        match_query = {
            "org_id": org_id,
            "timestamp": {"$gte": start_of_today},
            "status": {"$in": ["success", "present", "late"]}
        }
        if user_id:
            match_query["user_id"] = user_id

        pipeline = [
            {
                "$match": match_query
            },
            {
                "$group": {
                    "_id": "$employee_id",
                    "first_check_in": {"$min": "$timestamp"}
                }
            },
            {
                "$facet": {
                    "present": [{"$count": "count"}],
                    "late": [
                        {"$match": {"first_check_in": {"$gt": late_threshold}}},
                        {"$count": "count"}
                    ]
                }
            }
        ]
        
        cursor = self.collection.aggregate(pipeline)
        result = await cursor.to_list(length=1)
        
        if not result:
            return {"present": 0, "late": 0}
        
        data = result[0]
        present_count = data["present"][0]["count"] if data["present"] else 0
        late_count = data["late"][0]["count"] if data["late"] else 0
        
        return {"present": present_count, "late": late_count}

    async def get_logs_with_employee_info(
        self,
        org_id: str,
        page: int = 1,
        size: int = 10,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        dept_id: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Tuple[List[dict], int]:
        match_query = {"org_id": org_id}
        if user_id:
            match_query["user_id"] = user_id
        
        if start_date or end_date:
            timestamp_filter = {}
            if start_date:
                timestamp_filter["$gte"] = datetime.fromisoformat(start_date.replace("Z", "+00:00"))
            if end_date:
                # If only date is provided, include the whole day
                if len(end_date) <= 10:
                    timestamp_filter["$lte"] = datetime.fromisoformat(f"{end_date}T23:59:59.999Z".replace("Z", "+00:00"))
                else:
                    timestamp_filter["$lte"] = datetime.fromisoformat(end_date.replace("Z", "+00:00"))
            match_query["timestamp"] = timestamp_filter

        pipeline = [
            {"$match": match_query},
            {
                "$lookup": {
                    "from": "employees",
                    "localField": "employee_id",
                    "foreignField": "_id",
                    "as": "employee"
                }
            },
            {"$unwind": {
                "path": "$employee",
                "preserveNullAndEmptyArrays": True
            }}
        ]

        if dept_id:
            pipeline.append({"$match": {"employee.dept_id": dept_id}}) # Fixed dept_id field name if needed

        # Add sorting
        pipeline.append({"$sort": {"timestamp": -1}})

        # Facet for total count and paginated results
        pipeline.append({
            "$facet": {
                "metadata": [{"$count": "total"}],
                "data": [
                    {"$skip": (page - 1) * size},
                    {"$limit": size},
                    {
                        "$project": {
                            "id": {"$toString": "$_id"},
                            "employee_id": 1,
                            "employee_name": "$employee.name",
                            "department_id": "$employee.dept_id",
                            "timestamp": 1,
                            "status": 1,
                            "reason": 1,
                            "confidence": "$confidence_score",
                            "check_in": 1,
                            "check_out": 1,
                            "type": {
                                "$cond": {
                                    "if": {"$eq": ["$status", "failed"]},
                                    "then": "failure",
                                    "else": {"$ifNull": ["$attendance_type", "entry"]}
                                }
                            }
                        }
                    }
                ]
            }
        })

        cursor = self.collection.aggregate(pipeline)
        result = await cursor.to_list(length=1)
        
        if not result or not result[0]["data"]:
            return [], 0
            
        total = result[0]["metadata"][0]["total"] if result[0]["metadata"] else 0
        items = result[0]["data"]
        
        return items, total

    async def get_logs_cursor(self, org_id: str, user_id: Optional[str] = None, start_date: Optional[str] = None, end_date: Optional[str] = None):
        match_query = {"org_id": org_id}
        if user_id:
            match_query["user_id"] = user_id
            
        if start_date or end_date:
            timestamp_filter = {}
            if start_date:
                timestamp_filter["$gte"] = datetime.fromisoformat(start_date.replace("Z", "+00:00"))
            if end_date:
                if len(end_date) <= 10:
                    timestamp_filter["$lte"] = datetime.fromisoformat(f"{end_date}T23:59:59.999Z".replace("Z", "+00:00"))
                else:
                    timestamp_filter["$lte"] = datetime.fromisoformat(end_date.replace("Z", "+00:00"))
            match_query["timestamp"] = timestamp_filter

        pipeline = [
            {"$match": match_query},
            {
                "$lookup": {
                    "from": "employees",
                    "localField": "employee_id",
                    "foreignField": "_id",
                    "as": "employee"
                }
            },
            {"$unwind": {
                "path": "$employee",
                "preserveNullAndEmptyArrays": True
            }},
            {
                "$lookup": {
                    "from": "departments",
                    "localField": "employee.dept_id",
                    "foreignField": "_id",
                    "as": "department"
                }
            },
            {
                "$unwind": {
                    "path": "$department",
                    "preserveNullAndEmptyArrays": True
                }
            },
            {"$sort": {"timestamp": -1}},
            {
                "$project": {
                    "timestamp": 1,
                    "employee_name": "$employee.name",
                    "department_name": {"$ifNull": ["$department.name", "N/A"]},
                    "status": 1,
                    "confidence": "$confidence_score"
                }
            }
        ]
        return self.collection.aggregate(pipeline)

    async def get_analytics_data(
        self,
        org_id: str,
        start_date: datetime,
        end_date: datetime,
        dept_id: Optional[str] = None
    ) -> dict:
        match_query = {
            "org_id": org_id,
            "timestamp": {"$gte": start_date, "$lte": end_date}
        }
        
        # If dept_id is provided, we need to join with employees first
        pipeline_match = [{"$match": match_query}]
        
        if dept_id:
            pipeline_match.extend([
                {
                    "$lookup": {
                        "from": "employees",
                        "localField": "employee_id",
                        "foreignField": "_id",
                        "as": "employee"
                    }
                },
                {"$unwind": "$employee"},
                {"$match": {"employee.dept_id": dept_id}}
            ])

        # Aggregate metrics
        metrics_pipeline = pipeline_match + [
            {
                "$facet": {
                    "status_counts": [
                        {"$match": {"status": {"$in": ["present", "late", "success"]}}},
                        {"$group": {"_id": "$status", "count": {"$sum": 1}}}
                    ],
                    "daily_trends": [
                        {"$match": {"status": {"$in": ["present", "late", "success"]}, "attendance_type": "entry"}},
                        {
                            "$group": {
                                "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$timestamp"}},
                                "count": {"$sum": 1}
                            }
                        },
                        {"$sort": {"_id": 1}},
                        {"$project": {"date": "$_id", "count": 1, "_id": 0}}
                    ],
                    "punctuality": [
                        {"$match": {"attendance_type": "entry", "status": {"$in": ["present", "late"]}}},
                        {
                            "$group": {
                                "_id": None,
                                "total": {"$sum": 1},
                                "present": {"$sum": {"$cond": [{"$eq": ["$status", "present"]}, 1, 0]}}
                            }
                        }
                    ],
                    "peak_arrival": [
                        {"$match": {"attendance_type": "entry", "status": {"$in": ["present", "late"]}}},
                        {
                            "$project": {
                                "hour": {"$hour": "$timestamp"},
                                "minute": {"$minute": "$timestamp"}
                            }
                        },
                        {
                            "$project": {
                                "slot": {
                                    "$concat": [
                                        {"$toString": "$hour"},
                                        ":",
                                        {"$cond": [{"$lt": ["$minute", 30]}, "00", "30"]}
                                    ]
                                }
                            }
                        },
                        {"$group": {"_id": "$slot", "count": {"$sum": 1}}},
                        {"$sort": {"count": -1}},
                        {"$limit": 1}
                    ],
                    "hours_worked": [
                        {"$match": {"status": {"$in": ["present", "late", "success"]}}},
                        {"$sort": {"timestamp": 1}},
                        {
                            "$group": {
                                "_id": {
                                    "employee_id": "$employee_id",
                                    "date": {"$dateToString": {"format": "%Y-%m-%d", "date": "$timestamp"}}
                                },
                                "logs": {"$push": {"t": "$timestamp", "type": "$attendance_type"}}
                            }
                        },
                        {
                            "$project": {
                                "day_duration": {
                                    "$reduce": {
                                        "input": "$logs",
                                        "initialValue": {"sum": 0, "last_entry": None},
                                        "in": {
                                            "$cond": [
                                                {"$eq": ["$$this.type", "entry"]},
                                                {"sum": "$$value.sum", "last_entry": "$$this.t"},
                                                {
                                                    "$cond": [
                                                        {"$ne": ["$$value.last_entry", None]},
                                                        {
                                                            "sum": {"$add": ["$$value.sum", {"$subtract": ["$$this.t", "$$value.last_entry"]}]},
                                                            "last_entry": None
                                                        },
                                                        {"sum": "$$value.sum", "last_entry": None}
                                                    ]
                                                }
                                            ]
                                        }
                                    }
                                }
                            }
                        },
                        {
                            "$group": {
                                "_id": None,
                                "total_ms": {"$sum": "$day_duration.sum"}
                            }
                        }
                    ]
                }
            }
        ]

        cursor = self.collection.aggregate(metrics_pipeline)
        result = await cursor.to_list(length=1)
        
        if not result:
            return {}
            
        data = result[0]
        
        # Format status breakdown
        status_breakdown = {"present": 0, "late": 0, "absent": 0}
        for item in data["status_counts"]:
            if item["_id"] in status_breakdown:
                status_breakdown[item["_id"]] = item["count"]
            elif item["_id"] == "success":
                # success logs might be 'present' if they are 'entry'?
                pass

        # Calculate avg punctuality
        avg_punctuality = 0
        if data["punctuality"]:
            p = data["punctuality"][0]
            if p["total"] > 0:
                avg_punctuality = round((p["present"] / p["total"]) * 100, 2)

        # Peak arrival
        peak_arrival = "N/A"
        if data["peak_arrival"]:
            peak_arrival = data["peak_arrival"][0]["_id"]
            # Ensure HH:mm format
            if ":" in peak_arrival:
                h, m = peak_arrival.split(":")
                peak_arrival = f"{int(h):02d}:{m}"

        # Total hours
        total_hours = 0
        if data["hours_worked"]:
            total_ms = data["hours_worked"][0]["total_ms"]
            total_hours = round(total_ms / (1000 * 60 * 60), 2)

        return {
            "avg_punctuality": avg_punctuality,
            "peak_arrival_time": peak_arrival,
            "total_hours_worked": total_hours,
            "daily_trends": data["daily_trends"],
            "status_breakdown": status_breakdown
        }
