#!/bin/bash
source ./commoncode.sh

App_Name=catalogue

#checking app is running with root access or not and calling function
check_root

#Creating system user roboshop to run the roboshop app
#while, running it on second time, i got an error at system user gort failed, so using idempotency : sol for this is idempotency->, which irrespective of the number of times you run, nothing changes
app_setup
# installing npodejs, calling the function present in the common code installoing dependencies too
nodejs_setup

#From PWD to i can access the service file
#Copying catalogue service file for systemctl services like start, stop, restart and enable etc
systemd_setup

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