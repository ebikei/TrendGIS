x<-c("dplyr","ggplot2","data.table")
lapply(x, require, character.only=T)

drive=c("K:\\AirData\\OriginalData")
setwd(drive)

######################
############Download AQS Site
######################
PM10_AQS=data.frame(matrix(nrow=0,ncol=0))
PM10_Monitor=data.frame(matrix(nrow=0,ncol=0))
test2=c(1980:2019)

ptm <- proc.time()
for (i in 1:length(test2)){  
       tryCatch({
	url=paste("https://aqs.epa.gov/aqsweb/airdata/daily_81102_",test2[i],".zip",sep='')
	download.file(url,'temp2.zip')
	temp=read.csv(unz('temp2.zip',paste("daily_81102_",test2[i],".csv",sep='')),header=TRUE)
	names(temp)=c('StateCode','CountyCode','SiteID','Parameter','POC','Latitude','Longitude','Datum','Name','SampleDuration',
		'PollutantStandard','Date','Unit','EventType','ObsCount','ObsPercent','Value','MaxValue','MaxHour','AQI','MethodCode',
		'MethodName','SiteName','Address','StateName','CountyName','CityName','CBSAName','DateChange')
	temp$Value[temp$Unit=='Nanograms/cubic meter (25 C)']=temp$Value/1000
	temp$Unit=as.character(temp$Unit)
	temp$Unit[temp$Unit=='Nanograms/cubic meter (25 C)']='Micrograms/cubic meter (25 C)'
	obs_range=c(1,16:24)
	temp=filter(temp,ObsCount %in% obs_range,Unit=='Micrograms/cubic meter (25 C)')
	temp$Date=as.Date(as.character(temp$Date),format="%Y-%m-%d")
	temp2=temp[,c(1:7,12,13,15,17,20,25:27)]
	temp2=filter(temp2,StateCode!='CC')
	temp2$FIPS_C=paste(sprintf("%02d",as.numeric(as.character(temp2$StateCode))),sprintf("%03d",as.numeric(as.character(temp2$CountyCode))),sep='')
	temp2$FIPS_C[temp2$FIPS_C=='12086']='12025'
	temp2$FIPS=paste(temp2$FIPS_C,sprintf("%04d",temp2$SiteID),sep='')
	temp2$FIPSPOC=paste(temp2$FIPS,sprintf("%02d",temp2$POC),sep='')
	
	#Take average by Monitor, POC, and Date
	temp3=aggregate(Value~FIPSPOC+Date,temp2,mean,na.rm=TRUE)
	PM10_AQS=rbind(PM10_AQS,temp3)
	temp4=select(temp2,FIPSPOC,Latitude,Longitude) %>%
		distinct(FIPSPOC, .keep_all = TRUE)
	PM10_Monitor=rbind(PM10_Monitor,temp4)

	rm(url,temp,temp2,temp3,temp4)
       }, error=function(e){})	
}
proc.time() - ptm #This takes about 6min

PM10_AQS=rename(PM10_AQS,PM10_Value=Value)

dim(PM10_AQS)
PM10_Monitor=distinct(PM10_Monitor,FIPSPOC, .keep_all = TRUE)
dim(PM10_Monitor)

##Take Out Off-mainland
Outside_main=c('02','15','66','72','78','80')
PM10_AQS=PM10_AQS[!(substr(PM10_AQS$FIPSPOC,1,2) %in% Outside_main),]
PM10_Monitor=PM10_Monitor[!(substr(PM10_Monitor$FIPSPOC,1,2) %in% Outside_main),]

PM10_AQS=arrange(PM10_AQS,FIPSPOC,Date)
PM10_Monitor=arrange(PM10_Monitor,FIPSPOC)

test=substr(PM10_AQS$Date,1,4)
table(test)
rm(test)

test=substr(PM10_Monitor$FIPSPOC,1,2)
table(test)
rm(test)

test=substr(PM10_Monitor$FIPSPOC,1,5)
table(test)
rm(test)

save(PM10_AQS,file="PM10_Data_20160120.RData") #Units are in PPM
save(PM10_Monitor,file="PM10_Monitor_20160120.RData") #Units are in PPM

rm(list=ls())

