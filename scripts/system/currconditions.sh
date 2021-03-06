#!/bin/bash
# Script to gather Current_Conditions to monitor beehives
# see hivetool.net
# Version 1.0

#set -x #echo on
# Get Variables from central file
SHELL=/bin/bash
#LOG="/home/hivetool2/scripts/system/cronlog2"
#Get data from DB
/home/hivetool2/scripts/data/hiveconfig.sh

# Set some basics
PATH=/usr/local/sbin:/usr/local/bin:/bin:/sbin:/usr/sbin:/usr/bin:/home/hivetool2/scripts/weather:/home/hivetool2/scripts/system
HOST=`hostname`
#Load the results of the script above
source /home/hivetool2/scripts/hiveconfig.inc
DATE=$(TZ=":$TIMEZONE" date '+%F %T')

# ------ GET HIVE WEIGHT ----
# Easier to store this in our DB with the weather data

echo "--- WEIGHT --- "
if [ $ENABLE_HIVE_WEIGHT_CHK = "yes" ]; then
#echo "Checking Weight" >> $LOG
# Get the weight fool
HIVEWEIGHTSRC=`$HOMEDIR/scripts/weight/getweight.sh`
HIVEWEIGHT=$(echo $HIVEWEIGHTSRC |awk '{print $2}')
HIVERAWWEIGHT=$(echo $HIVEWEIGHTSRC |awk '{print $1}')
fi
if [ $ENABLE_HIVE_WEIGHT_CHK = "no" ]; then
HIVEWEIGHT=0
HIVERAWWEIGHT=0
fi

echo "--- WEIGHT DONE ---"
# ------ GET HIVE TEMP ------
echo "--- TEMP ---"
if [ $ENABLE_HIVE_TEMP_CHK = "yes" ]; then
# Data Fetchers/Parsers in one
#echo "Checking TEMP" >> $LOG
GETTEMP=`$HOMEDIR/scripts/temp/temperhum.sh`
HIVETEMPF=$(echo $GETTEMP |awk '{print $1}')
HIVETEMPC=`$HOMEDIR/scripts/temp/temperhumC.sh |awk '{print $1}'`
HIVEHUMIDITY=$(echo $GETTEMP |awk '{print $2}')
HIVEDEW=$(echo $GETTEMP |awk '{print $3}')
fi
if [ $ENABLE_HIVE_TEMP_CHK = "no" ]; then
HIVETEMPF=0
HIVETEMPC=0
HIVEHUMIDITY=0
HIVEDEW=0
fi

echo "--- TEMP DONE ---"

# Insert into data store
#echo "Inserting into DB - Success" >> $LOG
sqlite3 $HOMEDIR/data/hive-data.db "insert into hivedata (hiveid,date,hivetempf,hivetempc,hiveHum,hiveweight,hiverawweight,yardid,sync,beekeeperid) \
values (\"$HIVEID\",\"$DATE\",\"$HIVETEMPF\",\"$HIVETEMPC\",\"$HIVEHUMIDITY\",\"$HIVEWEIGHT\",\"$HIVERAWWEIGHT\",\"$YARDID\",1,\"$BEEKEEPERID\");"


# -------- END GET HIVE TEMP ----------

#---------- Get Ambient Weather--------
# Variables come from variable.inc
# Weather Data
echo "--- WX ---"
if [ $WEATHER_LEVEL = "hive" ]; then
echo "Getting from Wunderground"
GETNOW=`/usr/bin/curl --silent http://api.wunderground.com/api/$KEY/conditions/q/pws:$WXSTATION.json`
#echo $GETNOW > /var/www/weather.json

# Data Parsers
A_TEMP=`/bin/echo $GETNOW | JSON.sh -b |grep temp_f |awk '{print $2}'`
A_TEMP_C=`/bin/echo $GETNOW | JSON.sh -b |grep temp_c |awk '{print $2}'`
A_TIME=`/bin/echo $GETNOW | JSON.sh -b |grep observation_epoch |awk -F"\"" '{print $6}'`
A_HUMIDITY=`/bin/echo $GETNOW | JSON.sh -b |grep relative_humidity |awk -F"\"" '{print $6}'`
B_HUMIDITY=`/bin/echo $A_HUMIDITY | grep -o "\-*[0-9]*\.*[0-9]*"`
A_WIND_DIR=`/bin/echo $GETNOW | JSON.sh -b |grep wind_dir |awk -F"\"" '{print $6}'`
A_WIND_MPH=`/bin/echo $GETNOW | JSON.sh -b |grep wind_mph |awk '{print $2}'`
A_PRES_IN=`/bin/echo $GETNOW | JSON.sh -b |grep pressure_in |awk -F"\"" '{print $6}'`
A_PRES_TREND=`/bin/echo $GETNOW | JSON.sh -b |grep pressure_trend |awk -F"\"" '{print $6}'`
A_DEW=`/bin/echo $GETNOW | JSON.sh -b |grep dewpoint_f |awk '{print $2}'`
WEATHER_STATIONID=`/bin/echo $GETNOW | JSON.sh -b |grep station_id |awk '{print $2}'`
OBSERVATIONEPOCH=`/bin/echo $GETNOW | JSON.sh -b |grep observation_epoch |awk -F"\"" '{print $6}'`
OBSERVATIONDATETIME=`date -d @$OBSERVATIONEPOCH '+%F %T %Z'`
wind_degrees=`/bin/echo $GETNOW | JSON.sh -b |grep wind_degrees |awk  '{print $2}'`
wind_gust_mph=`/bin/echo $GETNOW | JSON.sh -b |grep wind_gust_mph |awk '{print $2}'`
wind_kph=`/bin/echo $GETNOW | JSON.sh -b |grep wind_kph |awk '{print $2}'`
wind_gust_kph=`/bin/echo $GETNOW | JSON.sh -b |grep wind_gust_kph |awk '{print $2}'`
pressure_mb=`/bin/echo $GETNOW | JSON.sh -b |grep pressure_mb |awk -F"\"" '{print $6}'`
weather_dewc=`/bin/echo $GETNOW | JSON.sh -b |grep dewpoint_c |awk '{print $2}'`
solarradiation=`/bin/echo $GETNOW | JSON.sh -b |grep solarradiation |awk -F"\"" '{print $6}'`
UV=`/bin/echo $GETNOW | JSON.sh -b |grep UV |awk -F"\"" '{print $6}'`
precip_1hr_in=`/bin/echo $GETNOW | JSON.sh -b |grep precip_1hr_in |awk -F"\"" '{print $6}'`
precip_1hr_metric=`/bin/echo $GETNOW | JSON.sh -b |grep precip_1hr_metric |awk -F"\"" '{print $6}'`
precip_today_string=`/bin/echo $GETNOW | JSON.sh -b |grep precip_today_string |awk -F"\"" '{print $6}'`
precip_today_in=`/bin/echo $GETNOW | JSON.sh -b |grep precip_today_in |awk -F"\"" '{print $6}'`
precip_today_metric=`/bin/echo $GETNOW | JSON.sh -b |grep precip_today_metric |awk -F"\"" '{print $6}'`

elif [ $WEATHER_LEVEL = "localws" ]; then
echo "Getting from LocalWS"
GETNOW=`$HOMEDIR/scripts/weather/ws1400/getWS1400.sh`
#echo "$GETNOW"
A_TEMP=`/bin/echo $GETNOW | JSON.sh -b |grep temp_f |awk '{print $2}'`
A_TEMP_C=`/bin/echo $GETNOW | JSON.sh -b |grep temp_c |awk '{print $2}'`
A_TIME=`/bin/echo $GETNOW | JSON.sh -b |grep observation_epoch |awk -F"\"" '{print $6}'`
A_HUMIDITY=`/bin/echo $GETNOW | JSON.sh -b |grep relative_humidity |awk -F"\"" '{print $6}'`
B_HUMIDITY=`/bin/echo $A_HUMIDITY | grep -o "\-*[0-9]*\.*[0-9]*"`
A_WIND_DIR=`/bin/echo $GETNOW | JSON.sh -b |grep wind_dir |awk -F"\"" '{print $6}'`
A_WIND_MPH=`/bin/echo $GETNOW | JSON.sh -b |grep wind_mph |awk -F"\"" '{print $6}'`
A_PRES_IN=`/bin/echo $GETNOW | JSON.sh -b |grep pressure_in |awk -F"\"" '{print $6}'`
A_PRES_TREND=`/bin/echo $GETNOW | JSON.sh -b |grep pressure_trend |awk -F"\"" '{print $6}'`
A_DEW=`/bin/echo $GETNOW | JSON.sh -b |grep dewpoint_f |awk '{print $2}'`
WEATHER_STATIONID=`/bin/echo $GETNOW | JSON.sh -b |grep station_id |awk '{print $2}'`
OBSERVATIONDATETIME=`/bin/echo $GETNOW | JSON.sh -b |grep observation_time |awk -F"\"" '{print $6}'`
wind_degrees=`/bin/echo $GETNOW | JSON.sh -b |grep wind_degrees |awk -F"\"" '{print $6}'`
wind_gust_mph=`/bin/echo $GETNOW | JSON.sh -b |grep wind_gust_mph |awk -F"\"" '{print $6}'`
wind_kph=`/bin/echo $GETNOW | JSON.sh -b |grep wind_kph |awk -F"\"" '{print $6}'`
wind_gust_kph=`/bin/echo $GETNOW | JSON.sh -b |grep wind_gust_kph |awk -F"\"" '{print $6}'`
pressure_mb=`/bin/echo $GETNOW | JSON.sh -b |grep pressure_mb |awk -F"\"" '{print $6}'`
weather_dewc=`/bin/echo $GETNOW | JSON.sh -b |grep dewpoint_c |awk -F"\"" '{print $6}'`
solarradiation=`/bin/echo $GETNOW | JSON.sh -b |grep solarradiation |awk -F"\"" '{print $6}'`
UV=`/bin/echo $GETNOW | JSON.sh -b |grep UV |awk -F"\"" '{print $6}'`
precip_1hr_in=`/bin/echo $GETNOW | JSON.sh -b |grep precip_1hr_in |awk -F"\"" '{print $6}'`
precip_1hr_metric=`/bin/echo $GETNOW | JSON.sh -b |grep precip_1hr_metric |awk -F"\"" '{print $6}'`
precip_today_string=`/bin/echo $GETNOW | JSON.sh -b |grep precip_today_string |awk -F"\"" '{print $6}'`
precip_today_in=`/bin/echo $GETNOW | JSON.sh -b |grep precip_today_in |awk -F"\"" '{print $6}'`
precip_today_metric=`/bin/echo $GETNOW | JSON.sh -b |grep precip_today_metric |awk -F"\"" '{print $6}'`


fi
echo "$YARDID,$WEATHER_STATIONID,'$OBSERVATIONDATETIME',$A_TEMP,$B_HUMIDITY,$A_DEW,'$A_TEMP_C','$A_WIND_MPH',$A_WIND_DIR','$wind_degrees','$wind_gust_mph','$wind_kph','$wind_gust_kph','$pressure_mb','$A_PRES_IN','$A_PRES_TREND','$weather_dewc','$solarradiation','$UV','$precip_1hr_in','$precip_1hr_metric','$precip_today_string','$precip_today_in','$precip_today_metric'"

# Insert Weather Data into local DB
sqlite3 $HOMEDIR/data/hive-data.db "insert into weather (yardid,weather_stationID,observationDateTime,weather_tempf,weather_humidity,weather_dewf,weather_tempc,wind_mph,wind_dir,wind_degrees,wind_gust_mph,wind_kph,wind_gust_kph,pressure_mb,pressure_in,pressure_trend,weather_dewc,solarradiation,UV,precip_1hr_in,precip_1hr_metric,precip_today_string,precip_today_in,precip_today_metric) values ($YARDID,$WEATHER_STATIONID,'$OBSERVATIONDATETIME',$A_TEMP,$B_HUMIDITY,$A_DEW,$A_TEMP_C,'$A_WIND_MPH','$A_WIND_DIR','$wind_degrees','$wind_gust_mph','$wind_kph','$wind_gust_kph','$pressure_mb','$A_PRES_IN','$A_PRES_TREND','$weather_dewc','$solarradiation','$UV','$precip_1hr_in','$precip_1hr_metric','$precip_today_string','$precip_today_in','$precip_today_metric');"


#echo "$YARDID,$WEATHER_STATIONID,'$OBSERVATIONDATETIME',$A_TEMP,$B_HUMIDITY,$A_DEW"

# ----------- END GET Ambient Weather ------------
#Advanced Analytics support
echo "Storing Advanced Analytics Data"
sqlite3 $HOMEDIR/data/hive-data.db "insert into allhivedata (hiveid,date,hivetempf,hivetempc,hiveHum,hiveweight,hiverawweight,yardid,sync,beekeeperid,weather_stationID,observationDateTime,weather_tempf,weather_humidity,weather_dewf,weather_tempc,wind_mph,wind_dir,wind_degrees,wind_gust_mph,wind_kph,wind_gust_kph,pressure_mb,pressure_in,pressure_trend,weather_dewc,solarradiation,UV,precip_1hr_in,precip_1hr_metric,precip_today_string,precip_today_in,precip_today_metric) \
values (\"$HIVEID\",\"$DATE\",\"$HIVETEMPF\",\"$HIVETEMPC\",\"$HIVEHUMIDITY\",\"$HIVEWEIGHT\",\"$HIVERAWWEIGHT\",\"$YARDID\",1,\"$BEEKEEPERID\", $WEATHER_STATIONID,'$OBSERVATIONDATETIME',$A_TEMP,$B_HUMIDITY,$A_DEW,$A_TEMP_C,'$A_WIND_MPH','$A_WIND_DIR','$wind_degrees','$wind_gust_mph','$wind_kph','$wind_gust_kph','$pressure_mb','$A_PRES_IN','$A_PRES_TREND','$weather_dewc','$solarradiation','$UV','$precip_1hr_in','$precip_1hr_metric','$precip_today_string','$precip_today_in','$precip_today_metric');"
echo "Success AAD"

if [ $DISPLAY_TYPE =  local ]; then
	# Being Lazy here, this will only be accurate if you are collecting both HiveTEMP and Weather at the hive level
# Generate a JSON file for use in the dashboards

WEBFILE=$PUBLIC_HTML_DIR/data/current.json

echo "[{" > $WEBFILE
echo "\"current_conditions\": {" >> $WEBFILE
echo "		\"observation_location\": {" >> $WEBFILE
echo "		\"full\":\"Beeyard, Fairfield, CT\"," >> $WEBFILE
echo "		\"yardname\":\"Beeyard\"," >> $WEBFILE
echo "		\"city\":\"Fairfield\"," >> $WEBFILE
echo "		\"state\":\"Connecticut\"," >> $WEBFILE
echo "		\"country\":\"US\"," >> $WEBFILE
echo "		\"country_iso3166\":\"US\"," >> $WEBFILE
echo "		\"latitude\":\"41.142033\"," >> $WEBFILE
echo "		\"longitude\":\"-73.241989\"," >> $WEBFILE
echo "		\"elevation\":\"11 ft\"" >> $WEBFILE
echo "		}," >> $WEBFILE
echo "		\"hive\": {" >> $WEBFILE
echo "		\"id\":\"$HIVENAME\"," >> $WEBFILE
echo "		\"observation_time\":\"$DATE\"," >> $WEBFILE
echo "		\"temp_f\":\"$HIVETEMPF\"," >> $WEBFILE
echo "		\"relative_humidity\":\"$HIVEHUMIDITY\"," >> $WEBFILE
echo "		\"dewpoint_f\":\"$HIVEDEW\"," >> $WEBFILE
echo "          \"rawweight\":\"$HIVERAWWEIGHT\"," >> $WEBFILE
echo "		\"weight_lbs\":\"$HIVEWEIGHT\"" >> $WEBFILE
echo "		}," >> $WEBFILE
echo "		\"weather\": {" >> $WEBFILE
echo "		\"a_temp_f\":$A_TEMP," >> $WEBFILE
echo "		\"a_relative_humidity\":\"$B_HUMIDITY\"," >> $WEBFILE
echo "		\"a_dewpoint_f\":$A_DEW" >> $WEBFILE
echo "}" >> $WEBFILE
echo "}" >> $WEBFILE
echo "}]" >> $WEBFILE

fi

#-------------------------------------
# If sharing, create file and send to other people
#-------------------------------------
if [ $SHARE_HIVETOOL = "yes" ]; then
echo "Sending to Hivetool"
	# Create XML file, since that is what they like to get
	SAVEFILE=$HOMEDIR/scripts/system/transmit.xml
	echo "<hive_data>" > $SAVEFILE
	echo "        <hive_observation>" >> $SAVEFILE
	echo "                <hive_id>$HIVENAME</hive_id>" >> $SAVEFILE
	echo "                <hive_observation_time>$DATE</hive_observation_time>" >> $SAVEFILE
	echo "                <hive_weight_lbs>$HIVERAWWEIGHT</hive_weight_lbs>" >> $SAVEFILE
	echo "                <hive_temp_c>$HIVETEMPC</hive_temp_c>" >> $SAVEFILE
	echo "                <hive_relative_humidity>$HIVEHUMIDITY</hive_relative_humidity>" >> $SAVEFILE
	echo "                <hive_ambient_temp_c>$A_TEMP_C</hive_ambient_temp_c>" >> $SAVEFILE
	echo "                <hive_ambient_relative_humidity>$B_HUMIDITY</hive_ambient_relative_humidity>" >> $SAVEFILE
	echo "        </hive_observation>" >> $SAVEFILE
	# hivetool likes to get straight wunderground data
	# so we make another call, TODO will be to parse the JSON we already collected, and send them XML
	# Maybe we can convince them to support JSON as well
        if [ $WEATHER_LEVEL = "hive" ]; then
	/usr/bin/curl --silent http://api.wunderground.com/api/$KEY/conditions/q/pws:$WXSTATION.xml > $HOMEDIR/scripts/system/wx.xml
	fi
	if [ $WEATHER_LEVEL = "localws" ]; then
	echo "Local ws Send"
	rm -rf $HOMEDIR/scripts/system/wx.xml
	cp $HOMEDIR/scripts/weather/ws1400/wx.xml $HOMEDIR/scripts/system/wx.xml 
	fi
	/usr/bin/xmlstarlet sel -t -c "/response/current_observation" $HOMEDIR/scripts/system/wx.xml >> $SAVEFILE
	echo "</hive_data>" >> $SAVEFILE



#====================
# Try to send to them
#====================
/usr/bin/curl --silent --retry 5 -k -u beehive:UcibucT -X POST --data-binary @$SAVEFILE https://hivetool.org/private/log_hive.pl  -H 'Accept: application/xml' -H 'Content-Type: application/xml' 1>$HOMEDIR/logs/hivetool-error.log
	

fi

# End Sharing
