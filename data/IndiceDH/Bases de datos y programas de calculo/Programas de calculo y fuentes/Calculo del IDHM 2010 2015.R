rm(list = ls())
install.packages("xlsx")
install.packages("readstata13")
install.packages("doBy")
library(xlsx)
library(dplyr)
library(reshape)
library(foreign)
library(readstata13)
library(doBy)

################################### C�lculo del �ndice de Desarrollo Humano Municipal 2010 y 2015 #############################

######### C�lculo del componente de Ingreso 2010 y 2015

###Paso previo: acomodo de las bases de datos

##ICTP 2010
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Ingreso")
ICTP2010<-read.xlsx("ICTP 2010.xlsx",sheetIndex = 1,header = T,encoding ="UTF-8" )
ICTP2010<-ICTP2010 %>% mutate(clave=Clave.de.municipio,estado=Clave.de.entidad)
ICTP2010<-rename(ICTP2010,c("ICTPC" = "ICTPC2010","Municipio"="municipio"))
ICTP2010<-ICTP2010 [,-c(1,3)]
saveRDS(ICTP2010,"Base del ICTPC2010.rds")

##ICTP 2015
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Ingreso")
ICTP2015<-read.xlsx("ICTP 2015.xlsx",sheetIndex = 1,header = T,encoding ="UTF-8" )
ICTP2015<-ICTP2015 %>% mutate(clave=Clave.de.municipio,estado=Clave.de.entidad)
ICTP2015<-rename(ICTP2015,c("ICTPC" = "ICTPC2015","Municipio"="municipio"))
ICTP2015<-ICTP2015 [,-c(1,3)]
saveRDS(ICTP2015,"Base del ICTPC2015.rds")

##Poblacion Coneval
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Ingreso")
pobconeval<-read.xlsx("Poblaci�n CONEVAL.xlsx",sheetIndex = 1,header = T,encoding = "UTF-8")
pobconeval<-pobconeval %>% mutate(clave=Clave.de.municipio,estado=Clave.de.entidad)
pobconeval<-rename(pobconeval,c("Municipio"="municipio"))
pobconeval<-pobconeval [,-c(1,3)]
pobconeval$Poblaci�n.2015<-as.character(pobconeval$Poblaci�n.2015)
pobconeval$Poblaci�n.2015<-as.numeric(pobconeval$Poblaci�n.2015)
pobconeval<-rename(pobconeval,replace=c("Poblaci�n.2015"="pob15","Poblaci�n.2010"="pob10"))
saveRDS(pobconeval,"Poblaci�n CONEVAL 2010 y 2015.rds")

BII<-merge(ICTP2010,ICTP2015,by="clave",all = T)
BII<-merge(BII,pobconeval,by="clave",all=T)
BII<-BII[,-c(2,3,5,6,7,9)]
BII<-BII[,c(4,5,2,3,6,7,1,8)]
saveRDS(BII,"Base para el c�lculo del �ndice de Ingreso 2010 y 2015.rds")


##Paso 1. Cambio del ICTPC  a precios de diciembre de 2015 (INPC NOV2010=99.250; INPC NOV2015=118.051; INPC DIC2015=118.532)
BII<-BII%>%mutate(ICTP2010_15=ICTPC2010*(118.532/99.250),ICTP2015_15=ICTPC2015*(118.532/118.051))

##Paso 2. Generaci�n del ICTPC anual
BII<-BII%>%mutate(ICTPC2010_a=ICTP2010_15*12,ICTPC2015_a=ICTP2015_15*12)

##Paso 3. Generaci�n del factor de ajuste utilizando el Ingreso Nacional Bruto (INB) 
BII<-BII%>%mutate(PICTPC2010=ICTPC2010_a*pob10,PICTPC2015=ICTPC2015_a*pob15)
sum(BII$PICTPC2010,na.rm = T)
sum(BII$PICTPC2015,na.rm=T)
options(scipen=999)
BII<-BII%>%mutate(ICTPC2010_TOTAL=sum(PICTPC2010,na.rm=T),ICTPC2015_TOTAL=sum(PICTPC2015,na.rm=T))

##Actualizaci�n del INB de 2010 [13207409.731*(118.532/99.742)]=15,695,501.2957
##Factor de ajuste en 2010=(15,695,501.2957*1,000,000)/4,490,668,602,668=3.495136846
##Factor de ajuste en 2015=(18,097,999.4780*1,000,000)/4,578,424,998,864=3.9528876

BII<-BII%>%mutate(FACTOR2010_INB=((15695501.2957*1000000)/ICTPC2010_TOTAL),FACTOR2015_INB=((18097999.4780*1000000)/ICTPC2015_TOTAL))

##Paso 4. Multiplicar el ICTPC anual, a precios de diciembre de 2015 por el factor de ajuste
BII<-BII%>%mutate(ICTPC_ajustado10=ICTPC2010_a*FACTOR2010_INB,ICTPC_ajustado15=ICTPC2015_a*FACTOR2015_INB)

##Paso 5. Dividir el ICTPC ajustado entre el Factor de conversi�n de PPA (para 2015), PIB (UMN por $ a precios internacionales) https://datos.bancomundial.org/indicador/PA.NUS.PPP?locations=MX
BII<-BII%>%mutate(ING_PPC10=ICTPC_ajustado10/8.5411,ING_PPC15=ICTPC_ajustado15/8.5411)

##Paso 6. Crear el �ndice de Ingreso del IDHM
BII<-BII%>%mutate(II_2010=(log(ING_PPC10)-log(100))/(log(75000)-log(100)),II_2015=(log(ING_PPC15)-log(100))/(log(75000)-log(100)))
saveRDS(BII,"Base para el c�lculo del �ndice de Ingreso 2010 y 2015.rds")


######### C�lculo del componente de Salud 2010 y 2015

### Paso previo: acomodo de las bases de datos
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Salud")
TMI<-read.xlsx("Tasas de mortalidad infantil del CONAPO 20180515.xlsx",sheetIndex = 1,header = T,encoding ="UTF-8" )
TMI<-TMI %>% mutate(estado=Claveentidad,municipio=Clavemunicipio,clave=(estado*1000)+municipio)
TMI$clave<-sprintf("%05d",TMI$clave)

###Paso 1. C�lculo del �ndice de Salud Nacional con base en los referentes internacionales del Reporte Global del IDH 2016
TMI$IS_N<-(77-20)/(85-20)

##Paso 2. Crear la variable de poblaci�n para cada a�o
TMI$pob_nac_2010<-sum(TMI$poblaci�n_2010,na.rm=T)
TMI$pob_nac_2015<-sum(TMI$poblaci�n_2015)

##Paso 3. Calcular el m�ximo a partir de la Tasa de mortalidad infantil de referencia m�s baja (1.7 para Iceland), en t�rminos de Supervivencia infantil
TMI$max<-1-(1.7/1000)

##Paso 4. Expresar la Tasa de mortalidad infantil municipal, en t�rminos de Supervivencia infantil
TMI<-TMI%>%mutate(SI_2010=1-(TMI2010/1000),SI_2015=1-(TMI2015/1000))
TMI$SI_N2010<-sum(TMI$SI_2010*(TMI$poblaci�n_2010/TMI$pob_nac_2010),na.rm = T)

TMI<-TMI%>%mutate(SI_N2010=sum(SI_2010*(poblaci�n_2010/pob_nac_2010),na.rm = T),SI_N2015=sum(SI_2015*(poblaci�n_2015/pob_nac_2015),na.rm = T))

##Paso 5. Calcular el valor m�nimo a partir del despeje de la f�rmula
TMI<-TMI%>%mutate(min_2010=(SI_N2010-(IS_N*max))/(1-IS_N),min_2015=(SI_N2015-(IS_N*max))/(1-IS_N))

##Paso 6. Calcular el �ndice de Salud

TMI<-TMI%>%mutate(IS_2015=(SI_2015-min_2015)/(max-min_2015),IS_2010=(SI_2010-min_2015)/(max-min_2015))

saveRDS(TMI,"Base para el c�lculo del �ndice de Salud municipal.rds")


######### C�lculo del componente de Educaci�n 2010 y 2015

##Paso previo: acomodo de las bases, de cada entidad federativa, de la Encuesta Intercensal 2015 y del Censo 2010
## Las bases de datos del Censo 2010 est�n en la secci�n de microdatos:https://www.inegi.org.mx/programas/ccpv/2010
##Las bases de la encuesta Intercensal 2015 est�n en la secci�n de microdatos: https://www.inegi.org.mx/programas/intercensal/2015/default.html
##Para 2010 y 2015, el INEGI tiene las bases separadas por entidad federativa, por lo que primero hay que descargarlas y luego pegarlas, conforme al paso que se describe enseguida
## En el paso siguiente, se pegan las bases en un solo archivo y s�lo se mantienen las variables
##necesarias para la construcci�n del �ndice de Educaci�n
##Paso previo: Generaci�n de una base para 2010 y otra correspondiente a 2015, a partir de las bases del INEGI de cada entidad federativa


##Encuesta Intercensal
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Educaci�n/Intercensal")

file_list <- list.files()
file_list

for (file in file_list){
  # if the merged dataset doesn't exist, create it
  if (!exists("dataset")){
    dataset <- read.dta13(file)
  }
  
  # if the merged dataset does exist, append to it
  if (exists("dataset")){
    temp_dataset <-read.dta13(file)
    dataset<-rbind(dataset, temp_dataset)
    rm(temp_dataset)
  }
  
}
saveRDS(dataset,"Base Completa Intercensal 2015.rds")



##Censo 2010
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Educaci�n/Censo")
file_list <- list.files()
file_list

for (file in file_list){
  # if the merged dataset doesn't exist, create it
  if (!exists("dataset")){
    dataset <- read.dta13(file)
  }
  
  # if the merged dataset does exist, append to it
  if (exists("dataset")){
    temp_dataset <-read.dta13(file)
    dataset<-rbind(dataset, temp_dataset)
    rm(temp_dataset)
  }
  
}
saveRDS(dataset,"Base Completa Muestra Censal 2010.rds")
rm(dataset)

### Encuesta Intercensal 2015###
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Educaci�n/Intercensal")

Intercensal<-readRDS("Base Completa Intercensal 2015.rds")

##Paso 1. Generaci�n de nuevas variables, previo a la recodificaci�n
Intercensal<-Intercensal %>% mutate(ASISTEN_R=ASISTEN,ESCOLARI_R=ESCOLARI,NIVACAD_R=NIVACAD,ESCOACUM_R=ESCOACUM)

##Paso 2. Recodificaci�n de los a�os de escolaridad
Intercensal$a�os<-NA

Intercensal$a�os[Intercensal$NIVACAD_R==0]<-0
Intercensal$a�os[Intercensal$NIVACAD_R==1]<-0
Intercensal$a�os[Intercensal$NIVACAD_R==2 & Intercensal$ESCOLARI_R==1]<-1
Intercensal$a�os[Intercensal$NIVACAD_R==2 & Intercensal$ESCOLARI_R==2]<-2
Intercensal$a�os[Intercensal$NIVACAD_R==2 & Intercensal$ESCOLARI_R==3]<-3
Intercensal$a�os[Intercensal$NIVACAD_R==2 & Intercensal$ESCOLARI_R==4]<-4
Intercensal$a�os[Intercensal$NIVACAD_R==2 & Intercensal$ESCOLARI_R==5]<-5
Intercensal$a�os[Intercensal$NIVACAD_R==2 & Intercensal$ESCOLARI_R>5&Intercensal$ESCOLARI_R<99]<-6
Intercensal$a�os[Intercensal$NIVACAD_R==3 & Intercensal$ESCOLARI_R==1]<-7
Intercensal$a�os[Intercensal$NIVACAD_R==3 & Intercensal$ESCOLARI_R==2]<-8
Intercensal$a�os[Intercensal$NIVACAD_R==3 & Intercensal$ESCOLARI_R>2&Intercensal$ESCOLARI_R<99]<-9
Intercensal$a�os[Intercensal$NIVACAD_R==4 & Intercensal$ESCOLARI_R==1]<-10
Intercensal$a�os[Intercensal$NIVACAD_R==4 & Intercensal$ESCOLARI_R==2]<-11
Intercensal$a�os[Intercensal$NIVACAD_R==4 & Intercensal$ESCOLARI_R>2&Intercensal$ESCOLARI_R<99]<-12
Intercensal$a�os[Intercensal$NIVACAD_R==5 & Intercensal$ESCOLARI_R==1]<-10
Intercensal$a�os[Intercensal$NIVACAD_R==5 & Intercensal$ESCOLARI_R==2]<-11
Intercensal$a�os[Intercensal$NIVACAD_R==5 & Intercensal$ESCOLARI_R==3]<-12
Intercensal$a�os[Intercensal$NIVACAD_R==5 & Intercensal$ESCOLARI_R>3&Intercensal$ESCOLARI_R<99]<-13
Intercensal$a�os[Intercensal$NIVACAD_R==6]<-6
Intercensal$a�os[Intercensal$NIVACAD_R==7 & Intercensal$ESCOLARI_R==1]<-10
Intercensal$a�os[Intercensal$NIVACAD_R==7 & Intercensal$ESCOLARI_R==2]<-11
Intercensal$a�os[Intercensal$NIVACAD_R==7 & Intercensal$ESCOLARI_R==3]<-12
Intercensal$a�os[Intercensal$NIVACAD_R==7 & Intercensal$ESCOLARI_R>3&Intercensal$ESCOLARI_R<99]<-13
Intercensal$a�os[Intercensal$NIVACAD_R==8 & Intercensal$ESCOLARI_R==1]<-13
Intercensal$a�os[Intercensal$NIVACAD_R==8 & Intercensal$ESCOLARI_R==2]<-14
Intercensal$a�os[Intercensal$NIVACAD_R==8 & Intercensal$ESCOLARI_R>2&Intercensal$ESCOLARI_R<99]<-15
Intercensal$a�os[Intercensal$NIVACAD_R==9 & Intercensal$ESCOLARI_R==1]<-10
Intercensal$a�os[Intercensal$NIVACAD_R==9 & Intercensal$ESCOLARI_R==2]<-11
Intercensal$a�os[Intercensal$NIVACAD_R==9 & Intercensal$ESCOLARI_R==3]<-12
Intercensal$a�os[Intercensal$NIVACAD_R==9 & Intercensal$ESCOLARI_R>3&Intercensal$ESCOLARI_R<99]<-13
Intercensal$a�os[Intercensal$NIVACAD_R==10 & Intercensal$ESCOLARI_R==1]<-13
Intercensal$a�os[Intercensal$NIVACAD_R==10 & Intercensal$ESCOLARI_R==2]<-14
Intercensal$a�os[Intercensal$NIVACAD_R==10 & Intercensal$ESCOLARI_R==3]<-15
Intercensal$a�os[Intercensal$NIVACAD_R==10 & Intercensal$ESCOLARI_R>3&Intercensal$ESCOLARI_R<99]<-16
Intercensal$a�os[Intercensal$NIVACAD_R==11 & Intercensal$ESCOLARI_R==1]<-13
Intercensal$a�os[Intercensal$NIVACAD_R==11 & Intercensal$ESCOLARI_R==2]<-14
Intercensal$a�os[Intercensal$NIVACAD_R==11 & Intercensal$ESCOLARI_R==3]<-15
Intercensal$a�os[Intercensal$NIVACAD_R==11 & Intercensal$ESCOLARI_R>3&Intercensal$ESCOLARI_R<99]<-16
Intercensal$a�os[Intercensal$NIVACAD_R==12 &Intercensal$ESCOLARI_R<99]<-17
Intercensal$a�os[Intercensal$NIVACAD_R==13 &Intercensal$ESCOLARI_R==1]<-17
Intercensal$a�os[Intercensal$NIVACAD_R==13 &Intercensal$ESCOLARI_R>1&Intercensal$ESCOLARI_R<99]<-18
Intercensal$a�os[Intercensal$NIVACAD_R==14 &Intercensal$ESCOLARI_R<99]<-18
Intercensal$a�os[Intercensal$ESCOACUM==99]<-99

##Paso 3. Creaci�n de identificadores �nicos

Intercensal<-Intercensal %>% mutate(estado=ENT,municipio=MUN,clave=paste(ENT,MUN))

##Paso 4. Creaci�n del �ndice de Educaci�n
##Paso 4a. Creaci�n de los a�os promedio de escolaridad

Intercensal<-Intercensal %>% mutate(edad_m=EDAD)
Intercensal$edad_m[Intercensal$EDAD==999]<-NA
Intercensal<-Intercensal %>% mutate(rango_a�os=0)
Intercensal$rango_a�os[Intercensal$a�os<99]<-1
saveRDS(Intercensal,"Base Completa Intercensal 2015.rds")

attach(Intercensal)
BAPE<-Intercensal%>%group_by(estado,clave,NOM_MUN)%>%filter(edad_m>24 & edad_m<999 &rango_a�os==1)%>%summarise(a�os=weighted.mean(a�os,FACTOR))
detach(Intercensal)

saveRDS(BAPE,"Base de a�os promedio de escolaridad 2015.rds")

##Paso 4b. Creaci�n de la tasa de matriculaci�n y de los a�os esperados

Intercensal$asistencia<-NA
Intercensal$asistencia[Intercensal$ASISTEN==5]<-1
Intercensal$asistencia[Intercensal$ASISTEN==7]<-0
Intercensal$asistencia[Intercensal$ASISTEN==9]<-0

Intercensal$rango<-0
Intercensal$rango[Intercensal$EDAD>5 & Intercensal$EDAD<25]<-1

Intercensal<-Intercensal %>% mutate(poblaci�n=FACTOR)
Intercensal$matriculados<-Intercensal$poblaci�n*Intercensal$asistencia
saveRDS(Intercensal,"Base Completa Intercensal 2015.rds")

attach(Intercensal)
Tasamatriculaci�n<-Intercensal%>%group_by(estado,clave,NOM_MUN,EDAD)%>%filter(rango==1)%>%summarise(poblaci�n=sum(poblaci�n,na.rm=T),matriculados=sum(matriculados,na.rm=T))
detach(Intercensal)

Tasamatriculaci�n$tm<-Tasamatriculaci�n$matriculados/Tasamatriculaci�n$poblaci�n
Tasamatriculaci�n1<-Tasamatriculaci�n%>%group_by(clave)%>%summarise(aesperados2015=sum(tm))
Tasamatriculaci�n<-merge(Tasamatriculaci�n,Tasamatriculaci�n1,by="clave",all=T)

saveRDS(Tasamatriculaci�n,"Tasa de matriculaci�n 2015.rds")

##Paso 4c. Pegado de las bases de datos para generar el �ndice
Tasamatriculaci�n<-Tasamatriculaci�n[!duplicated(Tasamatriculaci�n[c("clave")]),]
Tasamatriculaci�n<-Tasamatriculaci�n[,-c(4:7)]

BIE2015<-merge(BAPE,Tasamatriculaci�n,by="clave",all=T)
BIE2015<-BIE2015[,-c(5,6)]
colnames(BIE2015)<-c("clave","estado","NOM_MUN","a�os","aesperados2015")
saveRDS(BIE2015,"Base para el IE2015.rds")

##Paso 4d. Creaci�n de los �ndices
##Los valores de referencia son 18, como m�ximos a�os esperados de educaci�n y 15, como a�os m�ximos promedio de escolaridad//**
##Los valores se obtuvieron en la Nota t�cnica del Informe sobre Desarrollo Humano 2018 http://hdr.undp.org/sites/default/files/hdr2018_technical_notes.pdf
BIE2015<-BIE2015%>%mutate(IAP2015=(a�os/15),IAE2015=(aesperados2015/18),IEDU2015=(IAP2015+IAE2015)/2)
BIE2015<-rename(BIE2015,c("a�os"="a�os2015"))
saveRDS(BIE2015,"Base para el IE2015.rds")

### Censo 2010 ###
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Educaci�n/Censo")
Censo<-readRDS("Base Completa Muestra Censal 2010.rds")

##Paso 1. Generaci�n de nuevas variables, previo a la recodificaci�n
Censo<-Censo %>% mutate(ASISTEN_R=ASISTEN,ESCOLARI_R=ESCOLARI,NIVACAD_R=NIVACAD,ESCOACUM_R=ESCOACUM)

##Paso 2. Recodificaci�n de los a�os de escolaridad

Censo$a�os<-NA

Censo$a�os[Censo$NIVACAD_R==0]<-0
Censo$a�os[Censo$NIVACAD_R==1]<-0
Censo$a�os[Censo$NIVACAD_R==2 & Censo$ESCOLARI_R==1]<-1
Censo$a�os[Censo$NIVACAD_R==2 & Censo$ESCOLARI_R==2]<-2
Censo$a�os[Censo$NIVACAD_R==2 & Censo$ESCOLARI_R==3]<-3
Censo$a�os[Censo$NIVACAD_R==2 & Censo$ESCOLARI_R==4]<-4
Censo$a�os[Censo$NIVACAD_R==2 & Censo$ESCOLARI_R==5]<-5
Censo$a�os[Censo$NIVACAD_R==2 & Censo$ESCOLARI_R>5 & Censo$ESCOLARI_R<99]<-6
Censo$a�os[Censo$NIVACAD_R==3 & Censo$ESCOLARI_R==1]<-7
Censo$a�os[Censo$NIVACAD_R==3 & Censo$ESCOLARI_R==2]<-8
Censo$a�os[Censo$NIVACAD_R==3 & Censo$ESCOLARI_R>2 & Censo$ESCOLARI_R<99]<-9
Censo$a�os[Censo$NIVACAD_R==4 & Censo$ESCOLARI_R==1]<-10
Censo$a�os[Censo$NIVACAD_R==4 & Censo$ESCOLARI_R==2]<-11
Censo$a�os[Censo$NIVACAD_R==4 & Censo$ESCOLARI_R==3]<-12
Censo$a�os[Censo$NIVACAD_R==4 &  Censo$ESCOLARI_R>3 & Censo$ESCOLARI_R<99]<-13
Censo$a�os[Censo$NIVACAD_R==6]<-6
Censo$a�os[Censo$NIVACAD_R==7 & Censo$ESCOLARI_R==1]<-10
Censo$a�os[Censo$NIVACAD_R==7 & Censo$ESCOLARI_R==2]<-11
Censo$a�os[Censo$NIVACAD_R==7 & Censo$ESCOLARI_R==3]<-12
Censo$a�os[Censo$NIVACAD_R==7 & Censo$ESCOLARI_R>3 & Censo$ESCOLARI_R<99]<-13
Censo$a�os[Censo$NIVACAD_R==8 & Censo$ESCOLARI_R==1]<-13
Censo$a�os[Censo$NIVACAD_R==8 & Censo$ESCOLARI_R==2]<-14
Censo$a�os[Censo$NIVACAD_R==8 & Censo$ESCOLARI_R>2 & Censo$ESCOLARI_R<99]<-15
Censo$a�os[Censo$NIVACAD_R==5 & Censo$ESCOLARI_R==1]<-10
Censo$a�os[Censo$NIVACAD_R==5 & Censo$ESCOLARI_R==2]<-11
Censo$a�os[Censo$NIVACAD_R==5 & Censo$ESCOLARI_R==3]<-12
Censo$a�os[Censo$NIVACAD_R==5 & Censo$ESCOLARI_R>3 & Censo$ESCOLARI_R<99]<-13
Censo$a�os[Censo$NIVACAD_R==9 & Censo$ESCOLARI_R==1]<-13
Censo$a�os[Censo$NIVACAD_R==9 & Censo$ESCOLARI_R==2]<-14
Censo$a�os[Censo$NIVACAD_R==9 & Censo$ESCOLARI_R==3]<-15
Censo$a�os[Censo$NIVACAD_R==9 & Censo$ESCOLARI_R>3 & Censo$ESCOLARI_R<99]<-16
Censo$a�os[Censo$NIVACAD_R==10 & Censo$ESCOLARI_R==1]<-13
Censo$a�os[Censo$NIVACAD_R==10 & Censo$ESCOLARI_R==2]<-14
Censo$a�os[Censo$NIVACAD_R==10 & Censo$ESCOLARI_R==3]<-15
Censo$a�os[Censo$NIVACAD_R==10 & Censo$ESCOLARI_R>3&Censo$ESCOLARI_R<99]<-16
Censo$a�os[Censo$NIVACAD_R==11 & Censo$ESCOLARI_R==1]<-17
Censo$a�os[Censo$NIVACAD_R==11 & Censo$ESCOLARI_R>1&Censo$ESCOLARI_R<99]<-18
Censo$a�os[Censo$NIVACAD_R==12 & Censo$ESCOLARI_R<99]<-18

##Paso 3. Creaci�n de identificadores �nicos

Censo<-Censo %>% mutate(estado=ENT,municipio=MUN,clave=paste(ENT,MUN))

##Paso 4. Creaci�n del �ndice de Educaci�n
##Paso 4a. Creaci�n de los a�os promedio de escolaridad

Censo<-Censo %>% mutate(edad_m=EDAD)
Censo$edad_m[Censo$EDAD==999]<-NA
Censo<-Censo %>% mutate(rango_a�os=0)
Censo$rango_a�os[Censo$a�os<99]<-1
saveRDS(Censo,"Base Completa Muestra Censal 2010.rds")

attach(Censo)
BAPE2010<-Censo%>%group_by(estado,clave,NOM_MUN)%>%filter(edad_m>24 & edad_m<999 &rango_a�os==1)%>%summarise(a�os=weighted.mean(a�os,FACTOR))
detach(Censo)

saveRDS(BAPE2010,"Base de a�os promedio de escolaridad 2010.rds")

##Paso 4b. Creaci�n de la tasa de matriculaci�n y de los a�os esperados
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Educaci�n/Censo")

Censo<-readRDS("Base Completa Muestra Censal 2010.rds")
Censo$asistencia<-NA
Censo$asistencia[Censo$ASISTEN==1]<-1
Censo$asistencia[Censo$ASISTEN==3]<-0
Censo$asistencia[Censo$ASISTEN==9]<-0

Censo$rango<-0
Censo$rango[Censo$EDAD>5 & Censo$EDAD<25]<-1

Censo<-Censo %>% mutate(poblaci�n=FACTOR)
Censo$matriculados<-Censo$poblaci�n*Censo$asistencia
saveRDS(Censo,"Base Completa Muestra Censal 2010.rds")

attach(Censo)
Tasamatriculaci�n2010<-Censo%>%group_by(estado,clave,NOM_MUN,EDAD)%>%filter(rango==1)%>%summarise(poblaci�n=sum(poblaci�n,na.rm=T),matriculados=sum(matriculados,na.rm=T))
detach(Censo)

Tasamatriculaci�n2010$tm<-Tasamatriculaci�n2010$matriculados/Tasamatriculaci�n2010$poblaci�n
Tasamatriculaci�n20101<-Tasamatriculaci�n2010%>%group_by(clave)%>%summarise(aesperados2010=sum(tm))
Tasamatriculaci�n2010<-merge(Tasamatriculaci�n2010,Tasamatriculaci�n20101,by="clave",all=T)
rm(Tasamatriculaci�n20101)
saveRDS(Tasamatriculaci�n2010,"Tasa de matriculaci�n 2010.rds")

##Paso 4c. Pegado de las bases de datos para generar el �ndice
Tasamatriculaci�n2010<-Tasamatriculaci�n2010[!duplicated(Tasamatriculaci�n2010[c("clave")]),]
Tasamatriculaci�n2010<-Tasamatriculaci�n2010[,-c(4:7)]

BIE2010<-merge(BAPE2010,Tasamatriculaci�n2010,by="clave",all=T)
BIE2010<-BIE2010[,-c(5,6)]
colnames(BIE2010)<-c("clave","estado","NOM_MUN","a�os","aesperados2010")
saveRDS(BIE2010,"Base para el IE2010.rds")

##Paso 4d. Creaci�n de los �ndices
##//Los valores de referencia son 18, como m�ximos a�os esperados de educaci�n y 15, como a�os m�ximos promedio de escolaridad//**
##Los valores se obtuvieron en la Nota t�cnica del Informe sobre Desarrollo Humano 2016 http://hdr.undp.org/sites/default/files/hdr2016_technical_notes.pdf
BIE2010<-BIE2010%>%mutate(IAP2010=(a�os/15),IAE2010=(aesperados2010/18),IEDU2010=(IAP2010+IAE2010)/2)
BIE2010<-rename(BIE2010,c("a�os"="a�os2010"))
saveRDS(BIE2010,"Base para el IE2010.rds")


###Pegado en una sola base###
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Educaci�n/Censo")
BIE2010<-readRDS("Base para el IE2010.rds")
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Educaci�n/Intercensal")
BIE2015<-readRDS("Base para el IE2015.rds")
IEDU2010_2015<-merge(BIE2010,BIE2015,by="clave",all = T)
IEDU2010_2015$clave<-as.factor(IEDU2010_2015$clave)
IEDU2010_2015$clave <- gsub('\\s+', '', IEDU2010_2015$clave)
saveRDS(IEDU2010_2015,"Base del IEDU2010_2015.rds")

###C�lculo del Indice de Desarrollo Humano Municipal 2010 y 2015###
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Salud")
TMI<-readRDS("Base para el c�lculo del �ndice de Salud municipal.rds")
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice de Ingreso")
BII<-readRDS("Base para el c�lculo del �ndice de Ingreso 2010 y 2015.rds")
BIDH2010_2015<-merge(BII,TMI,by="clave",all = T)
BIDH2010_2015<-merge(BIDH2010_2015,IEDU2010_2015,by="clave",all = T)

BIDH2010_2015$IDHM_2010<-(IEDU2010_2015$IEDU2010*BII$II_2010*TMI$IS_2010)^(1/3)
BIDH2010_2015$IDHM_2015<-(IEDU2010_2015$IEDU2015*BII$II_2015*TMI$IS_2015)^(1/3)
BIDH2010_2015<-BIDH2010_2015[,-c(25,26,31,46,53,54)]
BIDH2010_2015<-BIDH2010_2015[,c(8,1,43,2,3,25:28,30,29,31:42,4:7,9:24,42,48,53,45,44,46,47,50,49,51,52,54,55)]
BIDH2010_2015<-rename(BIDH2010_2015,c("estado.x.x" = "estado","NOM_MUN.x"="NOM_MUN","Entidadfederativa"="Entidad"
                                      ,"municipio"="Municipio"))
setwd("~/Documents/Indice de Desarrollo Mpal/Generaci�n del IDHM 2015/�ndice General")
saveRDS(BIDH2010_2015,"Base Completa IDHM 2010_2015.rds")
