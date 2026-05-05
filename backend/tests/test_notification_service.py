import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from app.services.notification import NotificationService

@pytest.fixture
def notification_service():
    # Reset singleton/initialized state for tests
    NotificationService._instance = None
    NotificationService._initialized = False
    with patch("app.services.notification.firebase_admin.initialize_app"):
        return NotificationService()

@pytest.mark.asyncio
async def test_send_push_notification_success(notification_service):
    with patch("app.services.notification.messaging.send_each_for_multicast") as mock_send:
        mock_send.return_value = MagicMock(success_count=1, failure_count=0)
        
        # Ensure firebase apps are "present"
        with patch("app.services.notification.firebase_admin._apps", {"default": "app"}):
            tokens = ["token1"]
            title = "Test Title"
            body = "Test Body"
            
            result = await notification_service.send_push_notification(tokens, title, body)
            
            assert result is True
            mock_send.assert_called_once()
            args, kwargs = mock_send.call_args
            message = args[0]
            assert message.notification.title == title
            assert message.notification.body == body
            assert message.tokens == tokens

@pytest.mark.asyncio
async def test_send_push_notification_empty_tokens(notification_service):
    result = await notification_service.send_push_notification([], "Title", "Body")
    assert result is False

@pytest.mark.asyncio
async def test_send_push_notification_firebase_not_initialized(notification_service):
    with patch("app.services.notification.firebase_admin._apps", {}):
        result = await notification_service.send_push_notification(["token1"], "Title", "Body")
        assert result is False

@pytest.mark.asyncio
async def test_notify_late_arrival_calls_send(notification_service):
    with patch.object(notification_service, "send_push_notification", new_callable=AsyncMock) as mock_send:
        mock_send.return_value = True
        
        await notification_service.notify_late_arrival(
            admin_tokens=["t1"],
            employee_name="John",
            org_name="Org",
            log_id="log123"
        )
        
        mock_send.assert_called_once()
        args = mock_send.call_args[0]
        assert args[0] == ["t1"]
        assert "John" in args[2]
        assert "Org" in args[2]
        assert mock_send.call_args[0][3]["log_id"] == "log123"
