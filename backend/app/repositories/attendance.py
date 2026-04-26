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
        await self.collection.create_index([("employee_id", pymongo.ASCENDING)])
        await self.collection.create_index([("org_id", pymongo.ASCENDING)])

    async def get_last_success_log(self, org_id: str, employee_id: str) -> Optional[AttendanceLog]:
        import pymongo
        doc = await self.collection.find_one(
            {
                "org_id": org_id,
                "employee_id": employee_id,
                "status": "success"
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
            "status": "success",
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
            "status": "success"
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
                            "confidence": "$confidence_score"
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
