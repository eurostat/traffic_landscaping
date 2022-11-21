
library(lubridate)
library(TSstudio)
library(tidyverse)
library(readxl)
library(dbplyr)

#path data to change
setwd("inpur_data")

#Port of Lisbon data Arrival and Departure of vessels from 2014-2022.

data_PA_LISBOA_2014=read.csv2("partidas_2014.csv",colClasses = "character")
data_PA_LISBOA_2015=read.csv2("partidas_2015.csv",colClasses = "character")
data_PA_LISBOA_2016=read.csv2("partidas_2016.csv",colClasses = "character")
data_PA_LISBOA_2017=read.csv2("partidas_2017.csv",colClasses = "character")
data_PA_LISBOA_2018=read.csv2("partidas_2018.csv",colClasses = "character")
data_PA_LISBOA_20191=read.csv2("partidas_20191.csv",colClasses = "character")
data_PA_LISBOA_20192=read.csv2("partidas_20192.csv",colClasses = "character")
data_PA_LISBOA_2020=read.csv2("partidas_2020.csv",colClasses = "character")
data_PA_LISBOA_2021=read.csv2("partidas_2021.csv",colClasses = "character")
data_PA_LISBOA_2022=read.csv2("partidas_2022.csv", colClasses = "character")

#format variables 

data_PA_LISBOA_2014=data_PA_LISBOA_2014%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"), YEAR_DATA='2014')
data_PA_LISBOA_2015=data_PA_LISBOA_2015%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"), YEAR_DATA='2015')
data_PA_LISBOA_2016=data_PA_LISBOA_2016%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"), YEAR_DATA='2016')
data_PA_LISBOA_2017=data_PA_LISBOA_2017%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"), YEAR_DATA='2017')
data_PA_LISBOA_2018=data_PA_LISBOA_2018%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"), YEAR_DATA='2018')
data_PA_LISBOA_20191=data_PA_LISBOA_20191%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"), YEAR_DATA='2019')
data_PA_LISBOA_20192=data_PA_LISBOA_20192%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"),YEAR_DATA='2019')
data_PA_LISBOA_2020=data_PA_LISBOA_2020%>%
  mutate(ATD=strptime(ATD,"%d/%m/%Y %H:%M"),ATA=strptime(ATA,"%d/%m/%Y %H:%M"),YEAR_DATA='2020')
data_PA_LISBOA_2021=data_PA_LISBOA_2021%>%
  mutate(ATD=strptime(ATD,"%Y-%m-%d %H:%M"),ATA=strptime(ATA,"%Y-%m-%d %H:%M"),YEAR_DATA='2021')
data_PA_LISBOA_2022=data_PA_LISBOA_2022%>%
 mutate(ATD=strptime(ATD,"%d/%m/%Y %H:%M"),ATA=strptime(ATA,"%d/%m/%Y %H:%M"),YEAR_DATA='2022')

data_PA_LISBOA=bind_rows(data_PA_LISBOA_2014,data_PA_LISBOA_2015,data_PA_LISBOA_2016,data_PA_LISBOA_2017,
                         data_PA_LISBOA_2018,data_PA_LISBOA_20191,data_PA_LISBOA_20192,data_PA_LISBOA_2020,
                         data_PA_LISBOA_2021,data_PA_LISBOA_2022)

data_PA_LISBOA=data_PA_LISBOA%>%
  mutate(GT=as.numeric(GT), DWT=as.numeric(DWT), TAL=as.numeric(TAL),
         Comprimento=as.numeric(Comprimento), Calado.Maximo=as.numeric(Calado.Maximo),
         Capacidade.Teus=as.numeric(Capacidade.Teus),
         month=month(ATD),day=day(ATD), year=year(ATD),TYPE_EU=substr(Tipo,1,2))

# Convert Type of vassels code 

METADATA_CODE=read.csv2("metadati_PA2.csv")
data_PA_LISBOA= data_PA_LISBOA %>% left_join(METADATA_CODE,by="Tipo.Navio")

data_PA_LISBOA$TYPE_EU= ifelse(data_PA_LISBOA$YEAR_DATA >2018,data_PA_LISBOA$CODE,data_PA_LISBOA$TYPE_EU)
# Convert dates to quarterly
table(data_PA_LISBOA$TYPE_EU,data_PA_LISBOA$year,useNA = "ifany")
data_PA_LISBOA$quarters=lubridate::quarter(data_PA_LISBOA$ATD, with_year = T)

###################################################
#QUALITY EVALUATION Of PORT AUTORITY DATA
# COMPARISONS WITH  TABLE F1 of DIRECTIVE 2009/42/EC 
##################################################

# eustat data 
#Vessels in main ports by type and size of vessels (based on inwards declarations) - quarterly data 2014 to 2021

#Gross tonnage (GT) in thousand
mar_tf_qm__LISBOA_GT=
  as.data.frame(read_xlsx("mar_tf_qm__LISBOA_GT.xlsx",sheet = "vessels"))
#Number of vessels
mar_tf_qm__LISBOA_VESSEL=
  as.data.frame(read_xlsx("mar_tf_qm__LISBOA_VESSELs.xlsx",sheet = "vessels"))

#Selext target population from Port Autorit data and buil the tables
data_PA_LISBOA_CO=data_PA_LISBOA%>%
  filter(TYPE_EU>0 & TYPE_EU<35 & year>2013) 

data_v=addmargins(table(data_PA_LISBOA_CO$quarters, data_PA_LISBOA_CO$TYPE_EU ,
                        useNA = "ifany"))

#plots comparing the two sources .VESSELS number
data_v=matrix(data_v,37,7)[-c(30:37),]
colnames(data_v)=paste("PA",colnames(mar_tf_qm__LISBOA_VESSEL)[-1],sep="_")
data_v=cbind(mar_tf_qm__LISBOA_VESSEL,data_v)




data_v1 <- data_v %>%
  mutate(Time2=row_number())%>%
  select(Time2,`Liquid_bulk_tanker`, PA_Liquid_bulk_tanker) %>%
  gather(key = "variable", value = "value", -Time2)
p1=ggplot(data_v1, aes(x = Time2, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
data_v1 <- data_v %>%
  mutate(Time2=row_number())%>%
  select(Time2, `Dry_bulk_carrier`, PA_Dry_bulk_carrier) %>%
  gather(key = "variable", value = "value", -Time2)
p2=ggplot(data_v1, aes(x = Time2, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
data_v1 <- data_v %>%
  mutate(Time2=row_number())%>%
  select(Time2, `Container_ship`, PA_Container_ship) %>%
  gather(key = "variable", value = "value", -Time2)
p3=ggplot(data_v1, aes(x = Time2, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
data_v1 <- data_v %>%
  mutate(Time2=row_number())%>%
  select(Time2, `General_cargo`, PA_General_cargo) %>%
  gather(key = "variable", value = "value", -Time2)
p4=ggplot(data_v1, aes(x = Time2, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()

ggpubr::ggarrange(p1,p2,p3,p4, 
          labels = c("A", "B", "C","D"),
          ncol = 2, nrow = 2)


#plots comparing the two sources .Gross tonnage (GT) in thousand

data_GT=addmargins(xtabs(GT ~ quarters+TYPE_EU, data=data_PA_LISBOA_CO))
data_GT=round(matrix(data_GT,37,7)[-c(30:37),]/1000)
quarter=seq(1:nrow(data_GT))
colnames(data_GT)=paste("PA",colnames(mar_tf_qm__LISBOA_GT)[-1],sep="_")
data_GT=cbind(quarter,mar_tf_qm__LISBOA_GT,data_GT)

data_v1 <- data_GT %>%
  select(quarter, `Liquid_bulk_tanker`, PA_Liquid_bulk_tanker) %>%
  gather(key = "variable", value = "value", -quarter)
p1g=ggplot(data_v1, aes(x = quarter, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
data_v1 <- data_GT %>%
  select(quarter, `Dry_bulk_carrier`, PA_Dry_bulk_carrier) %>%
  gather(key = "variable", value = "value", -quarter)
p2g=ggplot(data_v1, aes(x = quarter, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
data_v1 <- data_GT %>%
  select(quarter, `Container_ship`, PA_Container_ship) %>%
  gather(key = "variable", value = "value", -quarter)
p3g=ggplot(data_v1, aes(x = quarter, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
data_v1 <- data_GT %>%
  select(quarter, `General_cargo`, PA_General_cargo) %>%
  gather(key = "variable", value = "value", -quarter)
p4g=ggplot(data_v1, aes(x = quarter, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()

ggpubr::ggarrange(p1g,p2g,p3g, p4g,
                  labels = c("A", "B", "C","D"),
                  ncol = 2, nrow = 2)

###############################################
# indicators number of vassels and time_in port
###############################################

imp_exp_lisboa=read.csv2("import_LISBOA2.csv")

data_PA_LISBOA_CO$vessels=1
indicator_NV=aggregate(cbind(data_PA_LISBOA_CO$vessels),
                       by=list(data_PA_LISBOA_CO$year, data_PA_LISBOA_CO$month),sum)

names(indicator_NV)=c("YEAR","MONTH", "VESSELS" )
indicator_NV=indicator_NV[
  order( indicator_NV[,"YEAR"], indicator_NV[,"MONTH"] ),]
indicator_NV=indicator_NV %>%
  mutate(VAR_VESSELS = (VESSELS/lag(VESSELS) - 1) * 100)

indicator_NV= indicator_NV %>% left_join(imp_exp_lisboa,by=c("YEAR","MONTH"))
indicator_NV_A<- indicator_NV %>%
  mutate(Time=(YEAR+MONTH/10))%>%
  select(Time,  VAR_VESSELS, VAR_IMP) %>%
  gather(key = "variable", value = "value", -Time)

#Monthly percentage changes of number of vessels vs  
# International  Exports - Port of Lisbon
ggplot(indicator_NV_A, aes(x = Time, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
# indicator_NV_A <- ts(indicator_NV[,c("VAR_VESSELS","VAR_IMP")] , start=c(2014,1), end=c(2022,8), frequency=12)
# 
# ts_plot(indicator_NV_A,
#         title = "monthly percentage changes of number of vessels in Lisbon port Monthly International Trade Rate Variation Exports",
#         Xtitle = "month",
#         Ytitle = "percentage changes",
#         line.mode =  "lines+markers")


data_PA_LISBOA_CO=data_PA_LISBOA_CO %>%
  mutate(time = as.numeric(difftime(ATD, ATA, units='hours')))
indicator_time=aggregate(data_PA_LISBOA_CO$time[data_PA_LISBOA_CO$time<60],
                         by=list(data_PA_LISBOA_CO$year[data_PA_LISBOA_CO$time<60], 
                                 data_PA_LISBOA_CO$month[data_PA_LISBOA_CO$time<60]),sum)

names(indicator_time)=c("YEAR","MONTH", "Time_in_port" )
indicator_time=indicator_time[
  order( indicator_time[,"YEAR"], indicator_time[,"MONTH"] ),]

indicator_time=indicator_time %>%
  mutate(VAR_Time_in_port = (Time_in_port/lag(Time_in_port) - 1) * 100)


indicator_time= indicator_time %>% left_join(imp_exp_lisboa,by=c("YEAR","MONTH"))
indicator_time_a<- indicator_time %>%
  mutate(Time=(YEAR+MONTH/10))%>%
  select(Time,  VAR_Time_in_port, VAR_IMP) %>%
  gather(key = "variable", value = "value", -Time)

#Monthly percentage changes Vessels total time in port vs  
# International  Exports - Port of Lisbon
ggplot(indicator_time_a, aes(x = Time, y = value)) + 
  geom_line(aes(color = variable),size = 1) +
  scale_color_manual(values = c("#00AFBB", "#E7B800")) +
  theme_minimal()
# 
# indicator_time_a <- ts(indicator_time[-c(1,104,105),c("VAR_Time_in_port","VAR_IMP")] , start=c(2014,1), end=c(2022,8), frequency=12)
# 
# ts_plot(indicator_time_a,
#         title = "Monthly percentage changes of total time in port - Lisbon",
#         Xtitle = "month",
#         Ytitle = "percentage changes",
#         line.mode =  "lines+markers")

#seasonal adjustment

library(forecast)
indicator_time_a <- ts(indicator_time[c(45:105),c("VAR_Time_in_port","VAR_IMP")] , start=c(2017,9), end=c(2022,8), frequency=12)

indicator_time_filt<-ma(indicator_time_a,order=12)
colnames(indicator_time_filt)=c("Time_in_port","Interantional_import")
 ts_plot(indicator_time_filt,
         title = "",
         Xtitle = "Month",
         Ytitle = "percentage changes",
         line.mode =  "lines+markers")

# title = "Monthly percentage changes Vessels total time in port vs  International  Import - Port of Lisbon (Seasonally Adjusted Data)",
 ###################################
 #  indicator Drought
 ###################################
 
 mar_tf_qm__LISBOA_GOOD=
   as.data.frame(read_xlsx("mar_tf_qm__LISBOA_GOOD.xlsx",sheet = "GOOD"))
 
 data_PA_LISBOA_CO$Calado.Maximo=ifelse(data_PA_LISBOA_CO$Calado.Maximo>10,data_PA_LISBOA_CO$Calado.Maximo/10,data_PA_LISBOA_CO$Calado.Maximo)
 data_PA_LISBOA_CO=data_PA_LISBOA_CO%>%
   group_by(IMO)%>%
  mutate(max_drought=max(Calado.Maximo))
 
 data_PA_LISBOA_CO=data_PA_LISBOA_CO%>%
   mutate(index=DWT*Calado.Maximo/max_drought)

 
 indicator_dr=aggregate(data_PA_LISBOA_CO$index,
                          by=list(data_PA_LISBOA_CO$quarters),sum)
 
 names(indicator_dr)=c("Quarters", "Index_drought" )
 indicator_dr=indicator_dr[
   order( indicator_dr[,"Quarters"]),]
 
 
 
 indicator_dr=cbind(indicator_dr[1:29,],mar_tf_qm__LISBOA_GOOD$Good[1:29])
 names(indicator_dr)=c("Quarters", "Index_drought" , "Good")
 
 indicator_dr=indicator_dr %>%
   mutate(Gross_weight_goods = (as.numeric(Good)/lag(as.numeric(Good)) - 1) * 100,
          Index_drought  = (Index_drought /lag(Index_drought ) - 1) * 100)
 
 

 indicator_dr_a <- ts(indicator_dr[,c("Gross_weight_goods","Index_drought")] , start=c(2014,1), end=c(2021,1), frequency=4)
 indicator_dr_a_filt<-ma(indicator_dr_a,order=4)
 colnames(indicator_dr_a_filt)=c("Gross_weight_goods","Index_drought")
 ts_plot(indicator_dr_a_filt,
         title = "",
         Xtitle = "Month",
         Ytitle = "Percentage changes",
         line.mode =  "lines+markers") 
# Monthly Percentage Changes of Gross weight of goods handled in Lisbon ports