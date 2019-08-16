#!/bin/sh
#echo ">>>>>>>>>>>>>>>>>>>>JAVA_HOME=$JAVA_HOME"
if [ $JAVA_HOME ];then
 echo "JAVA_HOME=$JAVA_HOME"
#else
# JAVA_HOME="/usr/java/jdk1.8.0_131"
fi
if [ -n "$JAVA_OPTS" ];then
	echo "JAVA_OPTS=$JAVA_OPTS"
else
	JAVA_OPTS="-Xms512m -Xmx512m -Xmn192m -XX:MaxPermSize=256m"
fi

APP_PATH=$(cd "$(dirname "$0")";pwd)
APP_JARNAME="$2"
SPRING_PROFILES_ACTIVE="$4"
if [ -n $SPRING_PROFILES_ACTIVE ] && [ ! -z $SPRING_PROFILES_ACTIVE ]; then
	echo "spring.profiles.active="$SPRING_PROFILES_ACTIVE
else
	SPRING_PROFILES_ACTIVE="dev"
fi


echo "APP_JARNAME="$APP_JARNAME
APP_LOG="$3"
psid=0

 
checkpid() {
    psid=`ps -ef|grep java |grep  $APP_JARNAME|grep -v 'grep'|awk '{print $2}'`
    if [ -z "$psid" ]; then
        psid=0
    fi
}

start() {
   checkpid
 
   if [ $psid -ne 0 ]; then
      echo "================================"
      echo "warn: $APP_JARNAME already started! (pid=$psid)"
      echo "================================"
   else
      echo -n "Starting $APP_JARNAME ..."
      if [ $JAVA_HOME ];then
       nohup $JAVA_HOME/bin/java $JAVA_OPTS -jar $APP_PATH/$APP_JARNAME --spring.profiles.active=$SPRING_PROFILES_ACTIVE > $APP_PATH/$APP_LOG 2>&1 &
      else
       nohup java $JAVA_OPTS -jar $APP_PATH/$APP_JARNAME --spring.profiles.active=$SPRING_PROFILES_ACTIVE > $APP_PATH/$APP_LOG 2>&1 &
      fi

      checkpid
      if [ $psid -ne 0 ]; then
         echo "(pid=$psid) [OK]"
      else
         echo "[Failed]"
      fi
   fi
}
 
stop() {
   checkpid
 
   if [ $psid -ne 0 ]; then
      echo -n "Stopping $APP_JARNAME ...(pid=$psid) "
      kill -9 $psid
      if [ $? -eq 0 ]; then
         echo "[OK]"
      else
         echo "[Failed]"
      fi
 
      checkpid
      if [ $psid -ne 0 ]; then
         stop
      fi
   else
      echo "================================"
      echo "warn: $APP_JARNAME is not running"
      echo "================================"
   fi
}
 
status() {
   checkpid
 
   if [ $psid -ne 0 ];  then
      echo "$APP_JARNAME is running! (pid=$psid)"
   else
      echo "$APP_JARNAME is not running"
   fi
}
 
info() {
   echo "System Information:"
   echo "****************************"
   echo `head -n 1 /etc/issue`
   echo `uname -a`
   echo
   echo "APP_JARNAME=$APP_JARNAME"
   echo "****************************"
}

case "$1" in
   'start')
      start
      ;;
   'stop')
     stop
     ;;
   'restart')
     stop
     start
     ;;
   'status')
     status
     ;;
   'info')
     info
     ;;
  *)
echo "Usage: $0 {start|stop|restart|status|info}"
esac
