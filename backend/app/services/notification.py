import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings
import logging
from typing import List, Optional

logger = logging.getLogger(__name__)

class NotificationService:
    _instance = None
    _initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(NotificationService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not NotificationService._initialized:
            self._initialize_firebase()
            NotificationService._initialized = True

    def _initialize_firebase(self):
        if settings.FIREBASE_CREDENTIALS_PATH:
            try:
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase initialized successfully.")
            except Exception as e:
                logger.error(f"Failed to initialize Firebase: {e}")
        else:
            logger.warning("FIREBASE_CREDENTIALS_PATH not set. Push notifications will be disabled.")

    async def send_push_notification(
        self, 
        tokens: List[str], 
        title: str, 
        body: str, 
        data: Optional[dict] = None
    ) -> bool:
        """
        Sends a push notification to a list of device tokens.
        """
        if not tokens:
            return False

        if not firebase_admin._apps:
            logger.warning("Firebase not initialized. Skipping notification.")
            return False

        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data,
            tokens=tokens,
        )

        try:
            response = messaging.send_each_for_multicast(message)
            logger.info(f"Successfully sent {response.success_count} messages.")
            if response.failure_count > 0:
                logger.warning(f"Failed to send {response.failure_count} messages.")
            return True
        except Exception as e:
            logger.error(f"Error sending push notification: {e}")
            return False

    async def notify_late_arrival(
        self, 
        admin_tokens: List[str], 
        employee_name: str, 
        org_name: str,
        log_id: str
    ):
        """
        Convenience method to notify admins of a late arrival.
        """
        title = "Late Arrival Alert"
        body = f"{employee_name} arrived late at {org_name}."
        data = {
            "type": "late_arrival",
            "log_id": log_id,
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
        }
        await self.send_push_notification(admin_tokens, title, body, data)
