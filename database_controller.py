import sqlite3 # pip install sqlite3

database_name = "_database.db"
users_table_name = "users"
report_table_name = "reports"
model_table_name = "model"
drone_images_table = "drone_images"

try:
    conn = sqlite3.connect(database_name,uri=True)
    conn.execute('CREATE TABLE IF NOT EXISTS ' + users_table_name + '(id INTEGER PRIMARY KEY AUTOINCREMENT,email TEXT UNIQUE NOT NULL,password TEXT NOT NULL,admin boolean default False , name TEXT )')
    conn.execute('CREATE TABLE IF NOT EXISTS ' + report_table_name + '(id INTEGER PRIMARY KEY AUTOINCREMENT,email TEXT NOT NULL,name TEXT NOT NULL,reportname TEXT NOT NULL,status TEXT default "pending",submitdate TEXT default "",finishdate TEXT default "", conf REAL default 0, bestimage TEXT default "", bestimageroimarked TEXT default "", bestimageroi TEXT default "", report_lat TEXT default "", report_lng TEXT default "", result_lat TEXT default "", result_lng TEXT default "" , color_r INTEGER default 0, color_g INTEGER default 0, color_b INTEGER default 0 , same_color_images TEXT default "" ,  shirt_color TEXT default "")')
    conn.execute('CREATE TABLE IF NOT EXISTS ' + drone_images_table + '(id INTEGER PRIMARY KEY AUTOINCREMENT,img_name TEXT NOT NULL,attached_reportname TEXT default "",match_count INTEGER default 0,scaned_model TEXT default "false",scaned_color TEXT default "false")')
    cur = conn.cursor()
    cur.execute('select * from '+ users_table_name )
    records = cur.fetchall()
    if len(records)==0:
        sqlite_insert_query = 'INSERT INTO '+ users_table_name +' (email,password,admin) VALUES (?,?,?);'
        data_tuple = ("admin@test.com","12345678",True,)
        cur.execute(sqlite_insert_query,data_tuple)
        conn.commit()
        sqlite_insert_query = 'INSERT INTO '+ users_table_name +' (email,password,admin) VALUES (?,?,?);'
        data_tuple = ("user1@test.com","12345678",False,)
        cur.execute(sqlite_insert_query,data_tuple)
        conn.commit()
except Exception as err:
    print('Query Failed, Error: %s' % (str(err)))
finally:
    cur.close()
    conn.close() 

def check_if_user_exists(email):
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT * FROM ' + users_table_name + ' where email = ? ' , (email,))
    records = cur.fetchall()
    cur.close()
    con.close()

    if len(records) == 0 :
        return False
    else:
        return True
    
def create_user(email,password,name):
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('INSERT INTO ' + users_table_name + ' (email,password,name) VALUES (?,?,?) ' , (email,password,name))
    con.commit()
    cur.close()
    con.close()   

def get_unscaned_color_image_count():
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT img_name,attached_reportname FROM ' + drone_images_table + ' where scaned_color = ? ' , ("false",))
    drone_images_records = cur.fetchall()
    cur.close()
    con.close()   
    return len(drone_images_records)

def set_all_searching_to_not_found():
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('UPDATE ' + report_table_name + ' SET status = ? where status = ? ', ("not found","searching",))
    con.commit() 
    cur.close()
    con.close()   
    return

def get_reports_count():
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor() 
    cur.execute('SELECT * FROM ' + report_table_name)
    records = cur.fetchall()
    cur.close()
    con.close()  
    return len(records)

def get_reports_count_by_status(status):
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor() 
    cur.execute('SELECT * FROM ' + report_table_name + ' where status = ? ' , (status,))
    records = cur.fetchall()
    cur.close()
    con.close()  
    return len(records)

def set_all_pending_to_searching():
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('UPDATE ' + report_table_name + ' SET status = ? where status = ? ', ("searching","pending",))
    con.commit() 
    cur.close()
    con.close()   
    return