library(lubridate)
library(tidyverse)
library(readxl)
library(OpenStreetMap)
library(ggplot2)
library(rgeos)
library(sf)
library(rgdal)

#-------------------------------------------
# Read input data
#------------------------------------------
#path data 
setwd("C:\\trasporti\\Dati\\out_final\\data")

#AISHUB data 30Aug2022 - 20nov2022
data_AH_LISBOA_2022=
  as.data.frame(read_xlsx("AISHUB_LISBONA.xlsx"))

#Data vessels info from Vessel Finder and metadata code on ship type (AISHUB data)

metadata_AH=read.csv2("METADATA_VF.csv")
vessels_info=read.csv("SHIP_INFO.csv")


#shape file of  oil_terminals from OpenStreetMap
shape_doc<- readOGR(dsn="oil_terminal",
                   layer="oil_terminals")

#Port autotity (PA) data 2022

data_PA_LISBOA_2022=read.csv2("partidas_2022.csv")
#metadata on type of vessels PA data
METADATA_PA=read.csv2("metadati_PA2.csv")

#map Port of Lisbon with oil terminals 

lat1 <- 38.4; lat2 <- 38.8; lon1 <- -9.5; lon2 <- -9.0
sa_map <- openmap( c(lat1, lon2),c(lat2, lon1), zoom = NULL,
                   type = "osm", mergeTiles = TRUE)

# reproject onto WGS84
sa_map2 <- openproj(sa_map)

sa_map2_plt <- OpenStreetMap::autoplot.OpenStreetMap(sa_map2) + 
  geom_polygon(data = shape_doc , aes(x = long, y = lat, group = group),
               colour = "black")+
  xlab("Longitude") + ylab("Latitude")
sa_map2_plt


#---------------------------------------------
# Derive port call fam AIS messages
#---------------------------------------------


#format variables 

data_AH_LISBOA_2022=data_AH_LISBOA_2022%>%
  mutate(TSTAMP=strptime(TSTAMP,"%Y-%m-%d %H:%M"),
         ETA=strptime(paste("2022",ETA,sep="-"),"%Y-%m-%d %H:%M"),
         LATITUDE=as.numeric(LATITUDE),
         LONGITUDE=as.numeric(LONGITUDE),
         DRAUGHT=as.numeric(DRAUGHT),
         COG=as.numeric(COG),SOG=as.numeric(SOG),
         A=as.numeric(A),B=as.numeric(B),
         C=as.numeric(C),D=as.numeric(D),
         Length = A + B,Width = C + D,
         month=month(TSTAMP),day=day(TSTAMP),
         NAVSTAT2=ifelse(NAVSTAT %in% c(1,4,5),1,0),
         CODE=if_else((TYPE>'69' & TYPE<'90'),TYPE,"0","0"))%>%
   filter(CODE>'0')

data_AH_LISBOA_2022 <-data_AH_LISBOA_2022[order(data_AH_LISBOA_2022$MMSI, data_AH_LISBOA_2022$TSTAMP),]
data=data_AH_LISBOA_2022




#Function to derive Port Calls



  data$TA=0
  data$TD=0
  data$id.trip=0
  data$diff_NAV_STAT=""
  data$stato=""
  data$inside=""
  data=data[data$LONGITUDE>-9.3 & data$LATITUDE>38.6,]
#first message of the vessels  

  data$id.trip[1]=1
  data$stato[1]="A"
  #data$inside[1]=point.in.polygon(data$LONGITUDE[1],data$LATITUDE[1],polig1,polig2)>0
  #data$inside[1]=(data$LONGITUDE[1]>-9.3 & data$LATITUDE[1]>38.6)
  
  if(data$NAVSTAT2[1] == 1 ){
      data$id.trip[1]=1
    data$TA[1]=1
  }
  
for(j in 2:nrow(data)){

#message of new vessels

    if(data$MMSI[j]!=data$MMSI[(j-1)]  ){
    data$id.trip[j]=1
    data$stato[j]="A"
    data$inside[j]=(data$LONGITUDE[j]>-9.3 & data$LATITUDE[j]>38.6)
    if(data$NAVSTAT2[j] == 1 ){  
    data$id.trip[j]=1
    data$TA[j]=1
    }}
    
#new message of  the same vessels
  
  if(data$MMSI[j]==data$MMSI[(j-1)] ){
    #data$diff_min[j]=as.numeric(difftime(data$TSTAMP[j], data$TSTAMP[(j-1)], units='mins'))
    #data$diff_distance[j]=round(sqrt((data$LATITUDE[j]-data$LATITUDE[(j-1)])^2+
    #                    (data$LONGITUDE[j]-data$LONGITUDE[(j-1)])^2),2)
    #data$diff_Spead[j]=data$SOG[j]-data$SOG[(j-1)]
    data$diff_NAV_STAT[j]=(data$NAVSTAT2[j]!=data$NAVSTAT2[(j-1)])
    data$inside[j]=(data$LONGITUDE[j]>-9.3 & data$LATITUDE[j]>38.6)
    
    if(data$diff_NAV_STAT[j]==FALSE ){
      data$id.trip[j]=data$id.trip[(j-1)]
      data$stato[j]=data$stato[j-1]
      }
    
    if(data$diff_NAV_STAT[j]==TRUE ){
        if(data$NAVSTAT2[j]==0){
          data$TD[j] = 1
          data$id.trip[j] = data$id.trip[(j-1)]
          data$stato[j]="D"
          }
        
        if(data$NAVSTAT2[j]==1 & data$stato[j-1]=="A"){
        data$TA[j]=1
        data$id.trip[j]=data$id.trip[j-1]
        data$stato[j]="A"
        }
       
       if(data$NAVSTAT2[j]==1 & data$stato[j-1]=="D"){
        data$TA[j]=1
        data$id.trip[j]=data$id.trip[j-1]+1
        data$stato[j]="A"}
      }
  }}

 
  data_plot=data_AH_LISBOA_2022%>%
    filter(MMSI==538008171)
  
  sa_map2_plt+
  geom_point(data =data_plot ,
              aes(x = LONGITUDE + 0.002, y = LATITUDE - 0.007), 
              colour = "red", size =  1)
#selection of  ARRIVAL(A) and DEPARTURE(D)
  
data_A_D=data%>%
  select(MMSI,    Length, Width, id.trip,   stato,
         month, day, TSTAMP, LATITUDE, LONGITUDE, TA,TD,IMO)%>%
  filter(TA==1 | TD==1)%>%
  mutate(diff=as.numeric(difftime(TSTAMP, lag(TSTAMP),units="hours")),
         warning=((id.trip>1 & stato=="A" & diff<12)| 
        (lead(id.trip)>1 & lead(stato)=="A" & lead(diff)<12)))%>%
        filter(!warning)%>%
        mutate(id.trip=if_else((lag(stato)=="A" & stato=="D" &
        id.trip != lag(id.trip) & lag(MMSI)==MMSI), lag(id.trip),id.trip,id.trip))



#JOIN the infomation on vessels type 
#data_A_D dataset  to produce statistics on   vessels
data_A_D$MMSI=as.numeric(data_A_D$MMSI)
data_A_D= data_A_D %>% 
left_join(vessels_info[,names(vessels_info) != "IMO"],by="MMSI")
data_A_D= data_A_D %>% 
  left_join(metadata_AH,by="TYPE")


#IDENTIFICATION OF VESSELS NOT DEPATURE

xx=reshape2::dcast(data_A_D, MMSI + id.trip ~ stato, value.var = "day")
table(xx$A,useNA = "ifany")
xx=xx%>%
  filter(!is.na(D))%>%
  select (MMSI,id.trip)
data_A_D= data_A_D %>% 
  right_join(xx,by=c("MMSI","id.trip"))


#IDENTIFICATION OF TERMINALS FOR FUEL SUPPLY TO IDENTIFY VESSELS THAT  load/unload goods


#poligin FUEL
lon_f=c(-9.19320,-9.18567)
lat_f=c(38.682,38.68548)

data_A_D$FUEL_EST=ifelse(!is.na(data_A_D$LONGITUDE) & data_A_D$LONGITUDE>=lon_f[1] & data_A_D$LONGITUDE<=lon_f[2] &
                           data_A_D$LATITUDE>=lat_f[1] & data_A_D$LATITUDE<=lat_f[2], 1,0)

addmargins(table(data_A_D$CODE,data_A_D$stato))




#-------------------------------------------
# comparison  with   Port of Lisbon (DA) data
#------------------------------------------

#Classification of infomation on vessels type 
data_PA_LISBOA_2022= data_PA_LISBOA_2022 %>% 
  left_join(METADATA_PA,by="Tipo.Navio")

# Format variable
data_PA_LISBOA_20222=data_PA_LISBOA_2022%>%
   mutate(ATD=strptime(ATD,"%d/%m/%Y %H:%M"),
          ATA=strptime(ATA,"%d/%m/%Y %H:%M"),
           month=month(ATA),day=day(ATA),TYPE="PA",
          time = as.numeric(difftime(ATD, ATA, units='hours')))

#Selection days HA;
data_PA_LISBOA_sel=data_PA_LISBOA_20222%>%
select( Navio,  IMO,ATD,ATA,  Motivo.Escala ,Local.Atribuido, GT,TAL,
  Comprimento,Calado.Maximo,  DWT, CODE,month,day,time)%>%
  mutate(CODE_PA=CODE, IMO=as.numeric(IMO))%>%
  filter(ATA>'2022-08-29' & CODE>0)

data_PA_LISBOA_sel <-data_PA_LISBOA_sel[order(data_PA_LISBOA_sel$IMO,
                                              data_PA_LISBOA_sel$ATA),]         


data_PA_LISBOA_sel=data_PA_LISBOA_sel %>% 
  group_by(IMO) %>% 
  mutate(id.trip = row_number())

data_A_D_sel=data_A_D %>% 
  mutate(CODE_AH=CODE, IMO=as.numeric(IMO))%>%
  filter(stato=="A")

# Link port of Lisbon data with AISHUB data to evaluate the coverage of AIS HUB data and 
# the accuracy of the variables


data_all <- full_join(data_PA_LISBOA_sel,data_A_D_sel ,
                      by=c("IMO","id.trip"))


data_all=data_all%>%
  mutate(FUEL=if_else(Local.Atribuido=="FUNDEADOURO QUADRO CENTRAL",1,0,0),
         PA=ifelse(!is.na(Navio),'1','0'),
         AH=ifelse(!is.na(MMSI),'1','0'),
         Link=paste(PA,AH,sep="-"),
         CODE_AH=if_else(Link=='1-1' & is.na(CODE_AH),CODE_PA,CODE_AH),
         CODE_AH=ifelse(AH=="1" & is.na(CODE_AH),0,CODE_AH)
         )
table(data_all$Link,data_all$id.trip,useNA = "ifany")

#coverage by type of vessels
addmargins(table(data_all$CODE_PA,data_all$CODE_AH, useNA = "ifany"))
#number in vessels in PA
addmargins(table(data_all$CODE_PA,useNA = "ifany"))
#number in vessels in AH
addmargins(table(data_all$CODE_AH,useNA = "ifany"))

p1=ggplot(data_all, aes(x=as.numeric(GROSS_TONNAGE), y=as.numeric(GT))) + 
  geom_point(shape=18, color="blue")+
  coord_cartesian(xlim = c(0, 40000), ylim = c(0, 40000))+
  xlab("AISHUB GT") + ylab("PA GT")

p2=ggplot(data_all, aes(x=DEADWEIGHT, y=as.numeric(paste(DWT)))) + 
  geom_point(shape=18, color="blue")+
  coord_cartesian(xlim = c(0, 80000), ylim = c(0, 80000))+
  xlab("AISHUB DWT") + ylab("PA DWT")
  
ggpubr::ggarrange(p1,p2, 
                  labels = c("A", "B"),
                  ncol = 2, nrow = 1)


