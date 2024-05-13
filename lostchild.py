from flask import Flask, request, jsonify, redirect, url_for,make_response  
import os
from werkzeug.utils import secure_filename
import base64
import datetime
from datetime import datetime, timedelta
from trainmodel import trainmodel
from find_child import predict_child_folder_by_face ,is_shirt_color_in_pic , validate_password , validate_email
import cv2 
from threading import Thread
import shutil
from pprint import pprint
from PIL import Image
import piexif
from flask import send_from_directory
from PIL import Image, ExifTags
from datetime import datetime
import threading
import pickle
import time
from GPSPhoto import gpsphoto  # py -3.7 -m pip install GPSPhoto exifread
from database_controller import * # check_if_user_exists,create_user,set_all_searching_to_not_found,get_reports_count,get_reports_count_by_status,set_all_pending_to_searching
import sqlite3 # pip install sqlite3


database_name = "_database.db"
users_table_name = "users"
report_table_name = "reports"
model_table_name = "model"
drone_images_table = "drone_images"

app = Flask(__name__)

global model_is_being_trained 
model_is_being_trained = False
global searching
searching = False
global model_need_training
model_need_training = False
global system_idle_time_not_found  # starting time relative to which all reports are set to not found
system_idle_time_not_found = time.time()
drone_search_images_directory = "TestingImages/"
drone_results_images_directory = "results_images/"
training_images_directory = "images/"

  

@app.route('/status', methods=['GET'])   # endpoint
def home():
    return "Server is running"

def train():
    global system_idle_time_not_found
    # skip_training = True  # do not train
    skip_training = False # train
    if not skip_training:
        global model_is_being_trained
        if not model_is_being_trained:
            model_is_being_trained = True
            trainmodel()            

            # reset idle timer 
            system_idle_time_not_found = time.time()   # after traing store the time 
            model_is_being_trained = False
            
def search_using_model():
    global searching
    global system_idle_time_not_found # 
    if not searching:
        searching = True
        conn = sqlite3.connect(database_name,uri=True)
        curr = conn.cursor()     
        
        # insert new images to table
        for img_filename in os.listdir(drone_search_images_directory): # loop on all drone images and save images to table
            curr.execute('SELECT img_name FROM ' + drone_images_table + ' where img_name = ? ' , (img_filename,))
            records = curr.fetchall()
            if len(records) == 0:
                curr.execute('INSERT INTO ' + drone_images_table + ' (img_name) VALUES (?) ' , (img_filename,))
                conn.commit()

        # select images not scanned by model yet.
        curr.execute('SELECT img_name,attached_reportname FROM ' + drone_images_table + ' where scaned_model = ? ' , ("false",))
        drone_images_records = curr.fetchall()
        
        # if found not scanned images
        if len(drone_images_records) > 0 :
            
            for drone_image_record in drone_images_records:        # loop on not scanned images
                folders,confs,rois,image_with_marked_rois = predict_child_folder_by_face(drone_search_images_directory+drone_image_record[0])
                #--- marking image as searched
                curr.execute('UPDATE ' + drone_images_table + ' SET scaned_model = ? , match_count = ? where img_name = ? ', ("true",len(folders),drone_image_record[0],))
                conn.commit() 
                

                for index,conf in enumerate(confs):  
                    curr.execute('SELECT conf,reportname FROM ' + report_table_name + ' where reportname = ? ' , (folders[index],))
                    records = curr.fetchall()
                    if len(records) > 0:
                        conf_old = records[0][0]
                        reportname = records[0][1]
                        if confs[index] * 100 > conf_old:  # 99 > 80
                            print("hi")
                            bestimageroi_filename = drone_image_record[0][:-4] + reportname + "roi" + drone_image_record[0][-4:] # img(.jpg) + namecolordate + roi + .jpg
                            bestimageroimarked_filename = drone_image_record[0][:-4] + reportname + "roimarked" + drone_image_record[0][-4:] # img(.jpg) + asdahmedcolordate + roimarked + .jpg
                            cv2.imwrite(drone_results_images_directory + bestimageroi_filename, rois[index]) 
                            cv2.imwrite(drone_results_images_directory + bestimageroimarked_filename, image_with_marked_rois[index]) 
                            result_lat , result_lng = get_image_coordinates(drone_search_images_directory+drone_image_record[0])
                            curr.execute('UPDATE ' + report_table_name + ' SET status = ? , conf = ? , bestimage = ? , finishdate = ? , result_lat = ? , result_lng = ? ,bestimageroimarked = ?, bestimageroi = ? WHERE reportname = ? ', ("found",int(confs[index]*100),drone_image_record[0],datetime.now() ,result_lat , result_lng,bestimageroimarked_filename,bestimageroi_filename,folders[index],))
                            conn.commit() 
                            #--- drone image attached to child
                            if drone_image_record[1] != "":
                                attached_reportname = drone_image_record[1] + "," + folders[index]
                            else:
                                attached_reportname = folders[index]
                            curr.execute('UPDATE ' + drone_images_table + ' SET attached_reportname = ? where img_name = ? ', (attached_reportname,drone_image_record[0],))
                            conn.commit()
                            # reset idle timer 
                            system_idle_time_not_found = time.time()  # reset the time if found a match 9:04:00

            # mark all model scaned images as scaned
            for drone_image_record in drone_images_records: 
                curr.execute('UPDATE ' + drone_images_table + ' SET scaned_model = ? where img_name = ? ', ("true",drone_image_record[0],))
                conn.commit() 

        curr.close()
        conn.close()
        searching = False 


#searching by shirt color
def search_using_color():
    global searching
    global system_idle_time_not_found
    if not searching:
        searching = True
        conn = sqlite3.connect(database_name,uri=True)
        curr = conn.cursor() 
        # searching with color for those who were not found
        curr.execute('SELECT img_name,attached_reportname FROM ' + drone_images_table + ' where scaned_color = ? ' , ("false",))
        drone_images_records = curr.fetchall()
        
        if len(drone_images_records) > 0 :
            for drone_image_record in drone_images_records:  
                curr.execute('SELECT reportname,color_r,color_g,color_b,same_color_images FROM ' + report_table_name + ' where conf = ? ' , (0,))
                records = curr.fetchall()
                images_with_same_shirt_color = ""
                if len(records) > 0:
                    for record in records:
                        reportname = record[0]
                        color_r = record[1]
                        color_g = record[2]
                        color_b = record[3]
                       
                        same_color_images = record[4]
                        if is_shirt_color_in_pic(drone_search_images_directory+drone_image_record[0],color_r,color_g,color_b):
                            images_with_same_shirt_color = same_color_images + "," + drone_image_record[0] 
                            result_lat , result_lng = get_image_coordinates(drone_search_images_directory+drone_image_record[0])
                            curr.execute('UPDATE ' + report_table_name + ' SET status = ? , same_color_images = ? , result_lat = ? , result_lng = ? WHERE reportname = ? ', ("found",images_with_same_shirt_color, result_lat , result_lng,reportname,))
                            conn.commit() 
                            if drone_image_record[1] != "":
                                attached_reportname = drone_image_record[1] + "," + reportname
                            else:
                                attached_reportname = reportname
                            curr.execute('UPDATE ' + drone_images_table + ' SET attached_reportname = ? where img_name = ? ', (attached_reportname,drone_image_record[0],))
                            conn.commit()
                            # reset idle timer 
                            system_idle_time_not_found = time.time()  # reset the time if found a match 

            # mark all color scaned images as scaned
            for drone_image_record in drone_images_records: 
                curr.execute('UPDATE ' + drone_images_table + ' SET scaned_color = ? where img_name = ? ', ("true",drone_image_record[0],))
                conn.commit() 

        # idle timer  mark  the rest as not found
        if time.time() - system_idle_time_not_found > 180:    
            set_all_searching_to_not_found()
            system_idle_time_not_found = time.time()

        curr.close()
        conn.close()    
        searching = False

def auto_search():
  # checking if model does not need training by matching the plk file to folders in images
    global model_is_being_trained
    global searching
    global model_need_training  

    # make sure we have repoerts to search 
    

    if not model_is_being_trained and not searching and get_reports_count() > 0:
        with open("result_map.pkl",'rb') as fileWriteStream:  
            result_map = pickle.load(fileWriteStream)
        
        if sorted(list(result_map.values())) == sorted(os.listdir(training_images_directory)):
            model_need_training = False
        else:
            model_need_training = True
            print("auto search not started, model needs training ")

        if not model_need_training:
            print("auto search in progress")
            search_using_model()
            search_using_color()

    if model_is_being_trained:
        print("auto search not started, model is being trained ")
    if searching:
        print("auto search not started, a search is running, probably after the train search ")

    if get_reports_count() == 0 :
        print("auto search not started, no records ")
    
    threading.Timer(1.0, auto_search).start()



@app.route('/gettrainingstatus', methods=['POST'])
def gettrainingstatus():
    global model_is_being_trained
    global model_need_training
    global searching
    message = ""
    
    message = "There are " +  str(get_reports_count()) + " reports, " + str(get_reports_count_by_status("pending")) + " pending, " + str(get_reports_count_by_status("found")) + " found, and " + str(get_reports_count_by_status("not found")) + " not found."
    if model_is_being_trained:
        message += "\nModel is currently being trained."
    if model_need_training:
        message += "\nModel needs training."
    if searching:
        message += "\nA search is in progress."

    resp = jsonify(model_is_being_trained = model_is_being_trained ,reports_count = get_reports_count(), found_count = get_reports_count_by_status("found") , not_found_count = get_reports_count_by_status("not found") , pending_count = get_reports_count_by_status("pending") , message = message)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/acceptrequestsearch', methods=['POST'])
def acceptrequestsearch():
    global model_is_being_trained
    already_training = False
    started_training = False
    message = ""
    if not model_is_being_trained:
        t = Thread(target=train)
        t.start()
        started_training = True
        message = "Started Traing and searcing successfully , results will be ready after 1 minute ISA."
        set_all_pending_to_searching()
    else:
        already_training = True
        message = "Already Traing and searcing ... , results will be ready after 1 minute ISA."
    
    
    resp = jsonify(started_training = started_training , already_training = already_training , message = message)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/deletereport', methods=['POST'])
def deletereport():
    reportname = request.args.get('report_name')
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('DELETE from ' + report_table_name + ' where reportname = ? ' , (reportname,))
    con.commit()

    cur.execute('SELECT bestimageroimarked , bestimageroi FROM ' + report_table_name + ' where reportname = ? ' , (reportname,))
    records = cur.fetchall()
    for record in records:
        os.remove(training_images_directory + record[0])
        os.remove(training_images_directory + record[1])
    cur.close()
    con.close()

    shutil.rmtree(training_images_directory + reportname)

    resp = jsonify(message = "")
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/clear_wrong_results', methods=['POST'])
def clear_wrong_results():
    success = True
    message = ""

    reportname = request.args.get('report_name')
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('UPDATE ' + report_table_name + ' SET conf = ? , status = ? , same_color_images = ? , bestimage = ? where reportname = ? ', (0,"not found","","",reportname,))
    con.commit() 
    
    cur.close()
    con.close()

    resp = jsonify(success = success ,message = message )
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/getreport', methods=['POST'])
def getreport():
    reportname = request.args.get('reportname')

    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT name,status,submitdate,finishdate,conf,bestimage,bestimageroimarked,bestimageroi,report_lat,report_lng,same_color_images,shirt_color FROM ' + report_table_name + ' where reportname = ? ' , (reportname,))

# TEXT default "",finishdate TEXT default "", rejected BOOLEAN default False ,conf REAL default 0, bestimage TEXT default "", bestimageroimarked TEXT default "", bestimageroi TEXT default "", report_lat TEXT default "", report_lng TEXT default "", result_lat TEXT default "", result_lng TEXT default "" , color_r INTEGER default 0, color_g INTEGER default 0, color_b INTEGER default 0 , same_color_images TEXT default "" ,  shirt_color TEXT default ""
    records = cur.fetchall()
    name = records[0][0]
    status = records[0][1]
    submitdate = records[0][2]
    finishdate = records[0][3]
    conf = records[0][4]
    
    # print(conf)
    if records[0][5]!="":
        bestimage = drone_search_images_directory + records[0][5]
        bestimageroimarked = drone_results_images_directory + records[0][6]
        bestimageroi = drone_results_images_directory + records[0][7]
    else:
        bestimage = ""
        bestimageroimarked = ""
        bestimageroi = ""
    report_lat = records[0][8]
    report_lng = records[0][9]
    result_lat =""
    result_lng =""
    if conf > 0:
        gps_data = gpsphoto.getGPSData(drone_search_images_directory + records[0][5])
        if gps_data:
            result_lat = str(gps_data["Latitude"])
            result_lng = str(gps_data["Longitude"])
        else:
            result_lat = ""
            result_lng = ""
        
    same_color_images = records[0][10].split(",") # ",img1,img2"
    if len(same_color_images) > 0:
        same_color_images.pop(0)
    shirt_color = records[0][11]
    cur.close()
    con.close()

    if bestimage != "":
        bestimage_takendate = get_date_taken(bestimage)
    else:
        bestimage_takendate = ""

    report_images = os.listdir("images/"+reportname)
    if len(same_color_images) >0:
        same_color_images_locations_lat = [] 
        same_color_images_locations_lng = []
        for img in same_color_images:
            gps_data = gpsphoto.getGPSData("TestingImages/"+img)
            if gps_data:
                lat = str(gps_data["Latitude"])
                lng = str(gps_data["Longitude"])
            else:
                lat = ""
                lng = ""
            same_color_images_locations_lat.append(lat)
            same_color_images_locations_lng.append(lng)
        same_color_images_takendate = [get_date_taken("TestingImages/"+img) for img in same_color_images]
    else:
        same_color_images_locations_lat = [] 
        same_color_images_locations_lng = []
        same_color_images_takendate = []
    resp = jsonify(name = name , status = status , submitdate = submitdate , finishdate = finishdate ,  conf = conf , bestimage = bestimage , bestimageroimarked = bestimageroimarked , bestimageroi = bestimageroi , report_lat = report_lat , report_lng = report_lng , result_lat = result_lat , result_lng = result_lng, same_color_images = same_color_images , report_images = report_images , shirt_color = shirt_color , same_color_images_locations_lat = same_color_images_locations_lat , same_color_images_locations_lng = same_color_images_locations_lng , same_color_images_takendate = same_color_images_takendate , bestimage_takendate = bestimage_takendate)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    resp.headers.add("Connection", "Keep-Alive") 
    resp.headers.add('Accept-Encoding', 'gzip, deflate, br') 
    return resp



@app.route('/getreports', methods=['POST'])
def getreports():
    email = request.args.get('email')
    admin = request.args.get('admin')
    name_list=[]
    reportname_list=[]
    status_list=[]
    submitdate_list = []
    finishdate_list = []
    
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    if admin == "true":
        cur.execute('SELECT * FROM ' + report_table_name )
    else:
        cur.execute('SELECT * FROM ' + report_table_name + ' where email = ? ' , (email,))

    records = cur.fetchall()
    for record in records:
        name_list.append(record[2])
        reportname_list.append(record[3])
        status_list.append(record[4])
        submitdate_list.append(record[5])
        finishdate_list.append(record[6])
    
    cur.close()
    con.close()

    resp = jsonify(name_list = name_list , status_list = status_list,reportname_list=reportname_list,submitdate_list=submitdate_list,finishdate_list=finishdate_list)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/signin', methods=['POST'])
def signin():
    success = False
    admin = False
    message = "Wrong Email or Password."
    email = request.args.get('email')
    password = request.args.get('password')

    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT * FROM ' + users_table_name + ' where email = ? and password = ? ' , (email,password,))
    records = cur.fetchall()
    if len(records) > 0 :
        success = True
        message = ""
        if records[0][3] == True:
            admin = True
    cur.close()
    con.close()

    resp = jsonify(success = success ,message = message ,admin = admin)
    resp.headers.add("Access-Control-Allow-Origin","*")
    return resp



@app.route('/signup', methods=['POST'])
def signup():
    success = True
    message = ""
    name = request.args.get('name').strip()
    email = request.args.get('email').strip()
    password = request.args.get('password').strip()
    confirmpassword = request.args.get('confirmpassword').strip()
    status = 0
    good_input = True

    valid_email , message_email = validate_email(email)
    if  not valid_email:
        success = False
        message = message_email
        good_input = False

    valid_password , message_password = validate_password(password)
    if  not valid_password:
        success = False
        message = message_password
        good_input = False

    if  confirmpassword != password:
        message = "passwords doesn't match"
        success = False
        good_input = False

    if good_input:
        if not check_if_user_exists(email) :
            # sign up user to DB
            create_user(email,password,name)
            message = " signed up successfully"     
        else:
            # print("email already used")
            success = False
            message = "email already used"

    resp = jsonify(success = success ,message = message , status = status)
    resp.headers.add("Access-Control-Allow-Origin","*")
    return resp

def store_face(img_full_name):
    img = cv2.imread(img_full_name, cv2.COLOR_BGR2GRAY)
    height, width = img.shape[:2]
    face_classifier = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    if height > 2000:
        scaleFactor = height/2000
    else:
        scaleFactor = 1

    scaleFactor=1.1
    
    faces = face_classifier.detectMultiScale(img, scaleFactor=1.1, minNeighbors=5, minSize=(100, 100))            
    print("len(faces) ", len(faces))
    if len(faces)>0:     
        biggest_face_size = 0       
        biggest_face = []
        for (x, y, w, h) in faces:
            if (x+w) * (y+h) > biggest_face_size:
                biggest_face_size = (x+w) * (y+h) 
                biggest_face = (x, y, w, h)            
        roi = img[ int(biggest_face[1]) : int(biggest_face[1])+int(biggest_face[3]) , int(biggest_face[0]) : int(biggest_face[0])+int(biggest_face[2]) , :]
        cv2.imwrite(img_full_name, roi) 
    
    return

@app.route('/submitimage', methods=['POST'])
def submitimage():
    success = True
    message = "Report Submitted Successfully"

    if request.method == 'POST':        
        name = request.args.get('name')
        email = request.args.get('email')
        color = request.args.get('color')
        images_save_directory= request.args.get('images_save_directory')
        if images_save_directory == "":
            images_save_directory = secure_filename(email + name + color + str(datetime.now()))
        
        if not os.path.exists(training_images_directory + images_save_directory):    
            os.makedirs(training_images_directory + images_save_directory)

        images = os.listdir(training_images_directory + images_save_directory)        
        with open(training_images_directory + images_save_directory + "/" + str(len(images)) + ".jpg", "wb") as fh:
            fh.write(base64.decodebytes(request.data))
        
        # re-reading the image , extracting face and saving only face.
        t = Thread(target=store_face,args=[training_images_directory + images_save_directory + "/" + str(len(images)) + ".jpg",])
        t.start()

    resp = jsonify(images_save_directory = images_save_directory, success = success , message = message)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/requestdirectory', methods=['POST'])
def requestdirectory():
    # if request.method == 'POST':        
    name = request.args.get('name')
    email = request.args.get('email')
    color = request.args.get('color')
    report_lat = request.args.get('report_lat')
    report_lng = request.args.get('report_lng')
    images_save_directory = secure_filename(email + name + color + str(datetime.now()))
    if color.lower() == "red":
        color_r = 255;color_g = 0;color_b = 0
    if color.lower() == "green":
        color_r = 0;color_g = 255;color_b = 0
    if color.lower() == "blue":
        color_r = 0;color_g = 0;color_b = 255
    if color.lower() == "white":
        color_r = 255;color_g = 255;color_b = 255    
    if color.lower() == "black":
        color_r = 0;color_g = 0;color_b = 0  
    if color.lower() == "pink":
        color_r = 255;color_g = 0;color_b = 255    
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('INSERT INTO ' + report_table_name + ' (email,name,reportname,submitdate,report_lat,report_lng,color_r,color_g,color_b,shirt_color) VALUES (?,?,?,?,?,?,?,?,?,?) ' , (email,name,images_save_directory,datetime.now(),report_lat,report_lng,color_r,color_g,color_b,color,))
    con.commit()
    cur.close()
    con.close()   

    resp = jsonify(images_save_directory = images_save_directory)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

def get_date_taken(filename):
    image_exif = Image.open(filename)._getexif()
    if image_exif:
        exif = { ExifTags.TAGS[k]: v for k, v in image_exif.items() if k in ExifTags.TAGS and type(v) is not bytes }
        date_obj = datetime.strptime(exif['DateTime'], '%Y:%m:%d %H:%M:%S')
        return date_obj
    else:
        return ""



@app.route('/TestingImages/<path:path>')
def send_TestingImages(path):
    resp = send_from_directory('TestingImages', path)
    resp.status_code = 200
    resp.headers = {'Connection': 'Keep-Alive','Access-Control-Allow-Origin': '*'}
    return resp

@app.route('/images/<path:path>')
def send_images(path):
    resp = send_from_directory('images', path)
    resp.status_code = 200
    resp.headers = {'Connection': 'Keep-Alive','Access-Control-Allow-Origin': '*'}
    return resp

@app.route('/results_images/<path:path>')
def send_results_images(path):
    resp = send_from_directory('results_images', path)
    resp.status_code = 200
    resp.headers = {'Connection': 'Keep-Alive','Access-Control-Allow-Origin': '*'}
    return resp

def decimal_coords(coords, ref):
    decimal_degrees = coords[0] + coords[1] / 60 + coords[2] / 3600
    if ref == "S" or ref =='W' :
        decimal_degrees = -decimal_degrees
    return decimal_degrees

codec = 'ISO-8859-1'  # or latin-1

def get_image_coordinates(filename):
    gps_data = gpsphoto.getGPSData(filename)
    if gps_data:
        lat = str(gps_data["Latitude"])
        lng = str(gps_data["Longitude"])
    else:
        lat = ""
        lng = ""
    return lat,lng

auto_search() 

if __name__ == '__main__':
    app.run(debug=True,port=13000,use_reloader=False,host='0.0.0.0')

# flutter run -d chrome --web-browser-flag "--disable-web-security"