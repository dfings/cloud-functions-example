from unittest.mock import Mock

from main import handle_request


def test_valid_number():
    req = Mock(path="/2.5")
    assert handle_request(req) == "7.853981633974483"


def test_invalid_number():
    req = Mock(path="/foo")
    assert handle_request(req) == "Invalid number: foo"
