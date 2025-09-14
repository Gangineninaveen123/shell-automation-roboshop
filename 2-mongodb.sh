#!/bin/bash
source ./commoncode.sh

App_Name=mysql

#checking app is running with root access or not and calling function
check_root
# copying the mongobd version which is in mongodb repo file
cp mongodb.repo /etc/yum.repos.d/mongodb.repo

# calling VALIDATE() function
VALIDATE $? "Copying mongodb repo file"

#Installing mongodb server
dnf install mongodb-org -y &>>$LOG_FILE  # THIS PASS OR FAIL The overall output or logs ll be stored in LOG_FILE
# Calling VALIDATE Function to check installation of mongodb server is sucessfull or not
VALIDATE $? "Installing Mongodb server"
#enabling mogodb server, for to tell that version details are in mongo.repo file which is in yum.repos.d folder
systemctl enable mongod &>>$LOG_FILE
# Calling VALIDATE Function to enable mongodb server is sucessfull or not
VALIDATE $? "Enabling Mongodb server"

# Starting mongodb server
systemctl start mongod &>>$LOG_FILE
# Calling VALIDATE Function to start of mongodb server is sucessfull or not
VALIDATE $? "Starting Mongodb server"

# Editing mongodb configuration file for remote connections in sed -> Stream Line editor, which is used for automation such as vim in manual
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
VALIDATE $? "Editing MongoDB configuration file for remote connections"

# Restarting Mongodb server
systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting Mogodb server"


# endtime of script
print_time