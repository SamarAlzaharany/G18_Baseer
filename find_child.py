import keras
import cv2
import keras.utils as image
import numpy as np
import sqlite3
from ultralytics import YOLO
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
import matplotlib.patches as patches

def predict_child_folder_by_face(img_name):

    import pickle
    with open("result_map.pkl",'rb') as fileWriteStream:
        result_map = pickle.load(fileWriteStream)

    model_cnn = keras.models.load_model("model.keras")

    face_classifier = cv2.CascadeClassifier(  # faces
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )
    confs = []
    folders = []
    rois = []
    image_with_marked_rois = []

    img = cv2.imread(img_name)

    faces = face_classifier.detectMultiScale(
        cv2.imread( img_name , cv2.COLOR_BGR2GRAY), scaleFactor=1.1, minNeighbors=5, minSize=(200, 200)
    )

    for index,(x,y,w,h) in enumerate(faces):
        roi_face = img[y:y+h,x:x+w]
        roi_face = cv2.cvtColor(roi_face, cv2.COLOR_BGR2RGB)
        roi_face = cv2.resize(roi_face, (64, 64),interpolation = cv2.INTER_LINEAR)
        roi_face = image.img_to_array(roi_face)
        roi_face = np.expand_dims(roi_face,axis =0) # tensor
        
        results = model_cnn.predict(roi_face)  

        tmp_img = img.copy()
        cv2.rectangle(tmp_img, (x, y), (x+w, y+h), (0, 255, 0), 10)

        confs.append(results.max()) # [ 99%, 88%,....]
        folders.append(result_map[np.argmax(results)]) # [3 , 4 ,....]
        rois.append(img[y:y+h,x:x+w]) # [ croped imaged 1 ,cropped image 2 , ...... ]
        image_with_marked_rois.append(tmp_img) # [ marked imaged 1 ,marked image 2 , ...... ]
        
    return folders,confs,rois,image_with_marked_rois


def is_shirt_color_in_pic(img_name,color_r_required=0,color_g_required=0,color_b_required=0):
    tolerance = 50 # color tolerance of fault due to different lighting conditions
    
    model = YOLO("yolov8n.pt")   # for human detection 
    img = cv2.imread(img_name)
    people = model(img)

    face_classifier = cv2.CascadeClassifier(  # faces
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )
    print("img ", img_name ," using color")
    print("found ", len(people[0].boxes.xyxy) ," person")
    for child in people[0].boxes.xyxy: # [x y x+w y+h]
        child_roi = img[int(child[1]):int(child[3]),int(child[0]):int(child[2])] # region of interest
        faces = face_classifier.detectMultiScale(
            child_roi, scaleFactor=1.1, minNeighbors=5, minSize=(200, 200)
        )
        
        height, width, dim = child_roi.shape
        if len(faces)>0 :  # [ x y w h]
            x,y,w,h = faces[0]
            shirt_roi = child_roi[ y + h : y + h + int(height/2)  , int(width/4):int(3*width/4), :]
        else:
            shirt_roi = child_roi[int(height/5):int(height/2), int(width/4):int(3*width/4), :]

        height, width, dim = shirt_roi.shape

        img_vec = np.reshape(shirt_roi, [height * width, dim] )

        kmeans = KMeans(n_clusters=3)
        kmeans.fit( img_vec )
        unique_l, counts_l = np.unique(kmeans.labels_, return_counts=True)
        sort_ix = np.argsort(counts_l)
        sort_ix = sort_ix[::-1]


        for index,cluster_center in enumerate(kmeans.cluster_centers_[sort_ix]):
            if index == 0:
                if abs(cluster_center[2] - color_r_required) < tolerance and abs(cluster_center[1] - color_g_required) < tolerance and abs(cluster_center[0] - color_b_required) < tolerance :
                    return True
            else:
                break

    return False


#input validation
def validate_email(email):
    message = ""
    valid = True

    if email.strip() == "":
        message = "Email can't be empty"
        valid = False        
    else:
        if len(email) > 8:
            at = email.find('@')
            dot = email.find('.')
            if at == -1:
                message = "Email missing @"
                valid = False    
            if dot == -1:
                message = "Email missing dot(.)"
                valid = False    
        else:
            message = "Email too short"
            valid = False

    return valid , message

def validate_password(password):
    message = ""
    valid = True

    if  password.strip() == "":
        message = "password Empty"
        valid = False
    else:
        if len(password) < 8:
            message = "password too small"
            valid = False
        else:    
            if  len(list(set(password))) < 3:   # testing for unique characters  (121231231) = set (123) = list [1,2,3] = len (3)
                message = "password too simple"
                valid = False
    
    return valid , message
