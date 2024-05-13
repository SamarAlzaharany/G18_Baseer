from find_child import is_shirt_color_in_pic , validate_email , validate_password

import unittest

class TestSum(unittest.TestCase):

    # password validation testing
    def test_validate_password_empty(self):
        assert validate_password("") == (False,"password Empty")

    def test_validate_password_small(self):
        assert validate_password("hi") == (False,"password too small")

    def test_validate_password_weak1(self):
        assert validate_password("11111111") == (False,"password too simple")

    def test_validate_password_weak2(self):
        assert validate_password("11112222") == (False,"password too simple")
    
    def test_validate_password_correct2(self):
        assert validate_password("12341234") == (True,"")


if __name__ == "__main__":
    unittest.main()
