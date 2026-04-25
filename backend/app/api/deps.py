from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from app.core import security
from app.core.config import settings
from app.db.mongodb import get_database
from app.models.token import TokenData
from app.services.recognition import RecognitionService
from app.services.attendance import AttendanceService
from app.services.reporting_service import ReportingService
from app.repositories.attendance import AttendanceRepository
from app.repositories.employee import EmployeeRepository
from app.repositories.org import OrgRepository
from app.repositories.department import DepartmentRepository

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login"
)

async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = security.decode_token(token)
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(email=username, role=payload.get("role"), org_id=payload.get("org_id"))
    except JWTError:
        raise credentials_exception
    
    db = get_database()
    user = await db["users"].find_one({"email": token_data.email})
    if user is None:
        raise credentials_exception
    return user

def get_recognition_service() -> RecognitionService:
    return RecognitionService()

def get_attendance_repository() -> AttendanceRepository:
    return AttendanceRepository()

def get_employee_repository() -> EmployeeRepository:
    return EmployeeRepository()

def get_org_repository() -> OrgRepository:
    return OrgRepository()

def get_department_repository() -> DepartmentRepository:
    return DepartmentRepository()

def get_reporting_service(
    attendance_repo: AttendanceRepository = Depends(get_attendance_repository),
    employee_repo: EmployeeRepository = Depends(get_employee_repository),
    org_repo: OrgRepository = Depends(get_org_repository)
) -> ReportingService:
    return ReportingService(attendance_repo, employee_repo, org_repo)

async def check_superadmin(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user["role"] != "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Super Admins can access this resource"
        )
    return current_user

async def check_org_admin(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only organization admins can perform this action",
        )
    if not current_user.get("org_id"):
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin must belong to an organization",
        )
    return current_user

async def check_org_user(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user.get("role") not in ["admin", "user"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user doesn't have enough privileges",
        )
    if not current_user.get("org_id"):
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User must belong to an organization",
        )
    return current_user

def get_attendance_service(
    recognition_service: RecognitionService = Depends(get_recognition_service),
    attendance_repo: AttendanceRepository = Depends(get_attendance_repository)
) -> AttendanceService:
    return AttendanceService(recognition_service, attendance_repo)
