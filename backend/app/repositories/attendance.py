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

    async def get_today_stats(self, org_id: str, start_of_today: datetime, late_threshold: datetime) -> dict:
        pipeline = [
            {
                "$match": {
                    "org_id": org_id,
                    "timestamp": {"$gte": start_of_today},
                    "status": "success"
                }
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
        dept_id: Optional[str] = None
    ) -> Tuple[List[dict], int]:
        match_query = {"org_id": org_id}
        
        if start_date or end_date:
            timestamp_filter = {}
            if start_date:
                timestamp_filter["$gte"] = datetime.fromisoformat(start_date)
            if end_date:
                # If only date is provided, include the whole day
                if len(end_date) <= 10:
                    timestamp_filter["$lte"] = datetime.fromisoformat(f"{end_date}T23:59:59.999Z")
                else:
                    timestamp_filter["$lte"] = datetime.fromisoformat(end_date)
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
            {"$unwind": "$employee"}
        ]

        if dept_id:
            pipeline.append({"$match": {"employee.department_id": dept_id}})

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
                            "employee_name": "$employee.full_name",
                            "department_id": "$employee.department_id",
                            "timestamp": 1,
                            "status": 1,
                            "confidence": 1
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

    async def get_logs_cursor(self, org_id: str):
        pipeline = [
            {"$match": {"org_id": org_id}},
            {
                "$lookup": {
                    "from": "employees",
                    "localField": "employee_id",
                    "foreignField": "_id",
                    "as": "employee"
                }
            },
            {"$unwind": "$employee"},
            {
                "$lookup": {
                    "from": "departments",
                    "localField": "employee.department_id",
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
                    "employee_name": "$employee.full_name",
                    "department_name": {"$ifNull": ["$department.name", "N/A"]},
                    "status": 1,
                    "confidence": 1
                }
            }
        ]
        return self.collection.aggregate(pipeline)
