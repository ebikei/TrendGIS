
x<-c("dplyr","ggplot2","data.table")
lapply(x, require, character.only=T)

drive=c("K:\\AirData\\OriginalData")
setwd(drive)

######################
############Download AQS Site
######################

Temp_AQS=data.frame()
Temp_Monitor=data.frame()
#CO_AQS=data.frame(matrix(nrow=0,ncol=0))
#CO_Monitor=data.frame(matrix(nrow=0,ncol=0))
test2=c(1990:2015)


ptm <- proc.time()
for (i in 1:length(test2)){  
	url=paste("http://aqsdr1.epa.gov/aqsweb/aqstmp/airdata/daily_TEMP_",test2[i],".zip",sep='')
	download.file(url,'temp2.zip')
	temp=read.csv(unz('temp2.zip',paste("daily_TEMP_",test2[i],".csv",sep='')),header=TRUE)
	names(temp)=c('StateCode','CountyCode','SiteID','Parameter','POC','Latitude','Longitude','Datum','Name','SampleDuration',
		'PollutantStandard','Date','Unit','EventType','ObsCount','ObsPercent','Value','MaxValue','MaxHour','AQI','MethodCode',
		'MethodName','SiteName','Address','StateName','CountyName','CityName','CBSAName','DateChange')
	#temp$Value[temp$Unit=='Parts per billion']=temp$Value/1000
	temp$Unit=as.character(temp$Unit)
	#temp$Unit[temp$Unit=='Parts per billion']='Parts per million'
	temp=filter(temp,ObsCount>=16,Unit=='Degrees Fahrenheit')
	temp$Date=as.Date(as.character(temp$Date),format="%Y-%m-%d")
	temp2=temp[,c(1:7,12,13,15,17,20,25:27)]
	temp2=filter(temp2,StateCode!='CC')
	temp2$FIPS_C=paste(sprintf("%02d",as.numeric(as.character(temp2$StateCode))),sprintf("%03d",as.numeric(as.character(temp2$CountyCode))),sep='')
	temp2$FIPS_C[temp2$FIPS_C=='12086']='12025'
	temp2$FIPS=paste(temp2$FIPS_C,sprintf("%04d",temp2$SiteID),sep='')
	temp2$FIPSPOC=paste(temp2$FIPS,sprintf("%02d",temp2$POC),sep='')
	
	#Take average by Monitor, POC, and Date
	temp3=aggregate(Value~FIPSPOC+Date,temp2,mean,na.rm=TRUE)
	Temp_AQS=rbind(Temp_AQS,temp3)
	temp4=select(temp2,FIPSPOC,Latitude,Longitude) %>%
		distinct(FIPSPOC)
	Temp_Monitor=rbind(Temp_Monitor,temp4)

	rm(url,temp,temp2,temp3,temp4)
}
proc.time() - ptm #This takes about 10min
Temp_AQS=rename(Temp_AQS,Temp_Value=Value)

dim(Temp_AQS)
Temp_Monitor=distinct(Temp_Monitor,FIPSPOC)
dim(Temp_Monitor)

##Take Out Off-mainland
Outside_main=c('02','15','66','72','78','80')
Temp_AQS=Temp_AQS[!(substr(Temp_AQS$FIPSPOC,1,2) %in% Outside_main),]
Temp_Monitor=Temp_Monitor[!(substr(Temp_Monitor$FIPSPOC,1,2) %in% Outside_main),]

Temp_AQS=arrange(Temp_AQS,FIPSPOC,Date)
Temp_Monitor=arrange(Temp_Monitor,FIPSPOC)

test=substr(Temp_AQS$Date,1,4)
table(test)
rm(test)

test=substr(Temp_Monitor$FIPSPOC,1,2)
table(test)
rm(test)

test=substr(Temp_Monitor$FIPSPOC,1,5)
table(test)
rm(test)

save(Temp_AQS,file="Temp_Data_20160120.RData") 
save(Temp_Monitor,file="Temp_Monitor_20160120.RData") 
