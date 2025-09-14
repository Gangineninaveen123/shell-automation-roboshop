#!/bin/bash
source ./commoncode.sh

App_Name=mysql

#checking app is running with root access or not and calling function
check_root
# Disabling default nodejs Version
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs Version"

#Enabling nodejs Version 20 as per developers choice
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs Version 20 as per developers choice"

#Installing Nodejs
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs 20 version"

#Creating system user roboshop to run the roboshop app
#while, running it on second time, i got an error at system user gort failed, so using idempotency : sol for this is idempotency->, which irrespective of the number of times you run, nothing changes

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user roboshop"
else
    echo -e "System user roboshop already created ... $Y Skipping $N"
fi


# Creating app directory to store our Catalogue code info
mkdir -p /app # if already create also, it ll not show error at run time [-p]
VALIDATE $? "Creating app directory"

#Downloading catalogue code in tmp folder
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue code"

#Unzipping Catalogue code info into app directory
rm -rf /app/* # i am deleteing the content in app directory, because in log files , its asking for oveeride the previous content, so simply ll delete the data, so no ovveride needed.
cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Catalogue code info into app directory"

#Installing npm depencies, which have some usefull libraies, which is used to run our application
npm install &>>$LOG_FILE
VALIDATE $? "Installing npm dependencies"

#From PWD to i can access the service file
#Copying catalogue service file for systemctl services like start, stop, restart and enable etc
cp $SCRIPT_DIR/3-catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service file for systemctl services"

#daemon-reload, enable and start catalogue
systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "daemon-reload, enable and start catalogue"

#Installing Mongodb Client , which is used to connect from catalogue server to mongodb server, with out mongodb client, can't connect
cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing Mongodb Client"

#Loading Master Data of the List of products we want to sell and their quantity information also there in the same master data.
STATUS=$(mongosh --host mongodb.muruga.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")') # if data is is already present in DB then the evalutaion ll be grater than zero, and if not data in db evaluation is lessthan 0 
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.muruga.site </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into Mongodb server"

else
    echo -e "Data is already loaded ... $Y SKIPPING"
fi

# endtime of script
print_time