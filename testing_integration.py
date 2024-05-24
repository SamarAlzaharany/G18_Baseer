
import database_controller

#1- check if user exists (False)
assert database_controller.check_if_user_exists("saraa@integrationtest.com") == False

#2- check if user exists (True) (why is it far and wait? to give database time to write)
assert database_controller.check_if_user_exists("layla32@gmail.com") == True

print("\033[1;32;40m ran all tests successfully with no errors \033[0m")


