#!/bin/bash
source ./commoncode.sh

App_Name=shipping

#checking app is running with root access or not and calling function
check_root

#Setting up shipping ROOT PASSWORD - RoboShop@1
echo "Please enter the root password"
read -s MYSQL_ROOT_PASSWORD
echo -e "$MYSQL_ROOT_PASSWORD"

#Installling maven along with java
dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing Maven"

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

# Creating app directory to store our shipping code info
mkdir -p /app # if already create also, it ll not show error at run time [-p]
VALIDATE $? "Creating app directory"

#Downloading shipping code in tmp folder
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping code"

#Unzipping shipping code info into app directory
rm -rf /app/* # i am deleteing the content in app directory, because in log files , its asking for oveeride the previous content, so simply ll delete the data, so no ovveride needed.
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping shipping code info into app directory"

#maven clean package, packing everything to run our application, mvn life cycle also ll come here
mvn clean package  &>> $LOG_FILE
VALIDATE $? "Packaging the shipping application"

#Moving and renaming the Jar file
mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE
VALIDATE $? "Moving and renaming the Jar file"

#Copying of Setup SystemD Shipping Service
cp $SCRIPT_DIR/9-shipping.service /etc/systemd/system/shipping.service

#Loading the sevice, for to know systemd folder, where the data has loaded for systemctl
systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Reloading daemon service"

# Enabling and starting shipping service
systemctl enable shipping &>> $LOG_FILE
VALIDATE $? "Enabling shipping"
systemctl start shipping &>> $LOG_FILE
VALIDATE $? "Starting shipping"

# installing mysql client. We need to load the schema to mysql db
dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Installing MYSQL client"

#loading data to mysql db by the help of below query
mysql -h mysql.muruga.site -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities'
if [ $? -ne 0 ]
then
    #Load Schema, Schema in database is the structure to it like what tables to be created and their necessary application layouts.
    mysql -h mysql.muruga.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql  &>> $LOG_FILE
    # Create app user, MySQL expects a password authentication, Hence we need to create the user in mysql database for shipping app to connect.
    mysql -h mysql.muruga.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>> $LOG_FILE
    #Load Master Data, This includes the data of all the countries and their cities with distance to those cities.
    mysql -h mysql.muruga.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>> $LOG_FILE
    VALIDATE $? "Loading data into mysql"
else
    echo -e "Data is already loaded into mysql DB.. $Y SKIPPING $N"
fi



#Restarting shipping
systemctl restart shipping &>> $LOG_FILE
VALIDATE $? "Restarting shipping"

# endtime of script
print_time

