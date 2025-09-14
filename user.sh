#!/bin/bash
source ./commoncode.sh
#Appname or module name
App_Name=user

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

# endtime of script
print_time