

import datetime
import sqlite3

def trainmodel(showplot = False):
    # reader class ( to read and change in the pictures)
    from keras.preprocessing.image import ImageDataGenerator
    train_gen = ImageDataGenerator(shear_range=0.1,zoom_range=.1,horizontal_flip=True)
    import os
    
    train_folder = 'images/'
    valid = 'Validation Images/'

    # reading images
    train_data = train_gen.flow_from_directory(train_folder,target_size=(64,64),batch_size=32,class_mode='categorical')   # data
    
    # copying class names 
    train_classes = train_data.class_indices  
    print(train_classes)                       

    # class names to a dictionary (mapping the train class names with indix)
    result_map = {}
    for faceValue,faceName in zip(train_classes.values(),train_classes.keys()): 
        result_map[faceValue] = faceName  



    #import keras model and implement the 3 layers cnn model 
    import keras
    from keras.models import Sequential
    from keras.layers import Convolution2D,MaxPool2D,Flatten,Dense
    model_cnn = Sequential()
    model_cnn.add(Convolution2D(32,kernel_size=(5,5),strides=(1,1),input_shape=(64,64,3),activation="relu")) # split the image to seperate information images
    model_cnn.add(MaxPool2D(pool_size=(2,2))) #select the highest value
    model_cnn.add(Convolution2D(64,kernel_size=(5,5),strides=(1,1),activation="relu"))
    model_cnn.add(MaxPool2D(pool_size=(2,2)))
    model_cnn.add(Convolution2D(128,kernel_size=(5,5),strides=(1,1),activation="relu"))
    model_cnn.add(MaxPool2D(pool_size=(2,2)))   
    model_cnn.add(Flatten())  # 2D to 1D
    model_cnn.add(Dense(len(result_map),activation='softmax')) # softmax sigmoid
    model_cnn.compile(loss="categorical_crossentropy",optimizer='adam',metrics=["accuracy"]) #configuring it for training and read to be train 
    
    # reproducable results
    keras.utils.set_random_seed(555)  # to give the same result 
    
    # monitor for heighest accuracy (check if the accuracy did not improve stop)
    from keras.callbacks import EarlyStopping
    earlystop= EarlyStopping(monitor='val_accuracy',mode="max",patience=50,restore_best_weights=True)


    #start training using cnn model with the choosen parameter 
    import time
    start_time = time.time()
    history = model_cnn.fit(train_data,steps_per_epoch=5,epochs=50,validation_data=train_data,callbacks=[earlystop])
    end_time = time.time()

    import matplotlib.pyplot as plt  

    print("Total training time= " , round((end_time-start_time)/60) ," minutes")

    
    # save model
    model_cnn.save("model.keras")

    # save dictionary 
    import pickle
    with open("result_map.pkl",'wb') as fileWriteStream:
        pickle.dump(result_map,fileWriteStream)