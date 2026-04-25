from unittest.mock import MagicMock

def test_redis_mock():
    mock = MagicMock()
    mock.get.return_value = "value"

    assert mock.get("key") == "value"