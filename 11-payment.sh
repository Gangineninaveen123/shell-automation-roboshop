#!/bin/bash
source ./commoncode.sh

App_Name=payment

#checking app is running with root access or not and calling function
check_root


#Installoing Python 3
dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installoing Python 3"


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


# Creating app directory to store our user code info
mkdir -p /app # if already create also, it ll not show error at run time [-p]
VALIDATE $? "Creating app directory"

#Downloading user code in tmp folder
curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user code"

#Unzipping user code info into app directory
rm -rf /app/* # i am deleteing the content in app directory, because in log files , its asking for oveeride the previous content, so simply ll delete the data, so no ovveride needed.
cd /app 
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzipping payment code info into app directory"

#Installoing Dependencies - Every application is developed by development team will have some common softwares that they use as libraries. This application also have the same way of defined dependencies in the application configuration.
cd /app
pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing requirements.txt Build file"


#setting up a new service in systemd so systemctl can manage this service
cp $SCRIPT_DIR/11-payment.service /etc/systemd/system/payment.service

#Loading the daemon to tell the ssyetm d folder that services are loaded
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Loading daemon services"

#Enable and start the payment services
systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling payment services"
systemctl start payment &>>$LOG_FILE
VALIDATE $? "Starting Payment server"

# endtime of script
print_time

