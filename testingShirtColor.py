from find_child import is_shirt_color_in_pic , validate_email , validate_password

import unittest

class TestSum(unittest.TestCase):


    # color recognition testing
    def test_white(self):
        assert is_shirt_color_in_pic("images for testing/child1.jpg",240,240,240) == True
    
    def test_not_black(self):
        assert is_shirt_color_in_pic("images for testing/child1.jpg",20,20,100) == False


if __name__ == "__main__":
    unittest.main()