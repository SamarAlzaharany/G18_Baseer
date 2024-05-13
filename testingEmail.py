from find_child import is_shirt_color_in_pic , validate_email , validate_password

import unittest

class TestSum(unittest.TestCase):
    
    # email validation testing

    def test_validate_email_correct1(self):
        assert validate_email("mona@gmail.com") == (True,"")

    def test_validate_email_empty(self):
        assert validate_email("") == (False,"Email can't be empty")
    
    def test_validate_email_short(self):
        assert validate_email("mona") == (False,"Email too short")
    
    def test_validate_email_no_dot(self):
        assert validate_email("mona@gmail") == (False,"Email missing dot(.)")
    
    def test_validate_email_no_at(self):
        assert validate_email("monagmail.com") == (False,"Email missing @")
        

if __name__ == "__main__":
    unittest.main()
