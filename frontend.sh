#!/bin/bash
source ./commoncode.sh

App_Name=mysql

#checking app is running with root access or not and calling function
check_root
#Disabling nginx
dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling Default nginx"

#Enabling nginx version 1.24
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling nginx version:1.24"

#Installing nginx
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing nginx"

#enabling nginx
systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling nginx"

#Start nginx
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting nginx"

# Removing default content present in the html folder
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default content present in the html folder"

#Downloading frontend code
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend code"

#Unziping frontend code in html folder
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unziping front end code"

#Removing default content present in the nginx.conf file
rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing default content present in the nginx.conf folder"

#Adding new content to nginx to frontend with app tier connections
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx content"

#Restart nginx
systemctl restart nginx 
VALIDATE $? "Restarting nginx"

# endtime of script
print_time