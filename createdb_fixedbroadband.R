# Archivo createdb_fixedbroadband.R

# Este programa procesa las diferentes DB's reunidas (ver archivo Readme.md y carpeta /datos) sobre datos
# socio-demograficos de los municipios de Mexico, junto con datos de indicadores de presencia de infraestructura 
# y localizacion de accesos de banda ancha fija de los operadores del mercado.

# Como resultadom se crean una serie de archivos .csv (carpeta /datos/processed) que son la base del analisis 
# exploratorio (incluyendo la creacion de mapas de penetracion municipal de cobertura de accesos de banda ancha fija),
# asi como las bases de datos que alimentan los modelos de aprendizaje de maquina, que se realizan posteriormente en Python.

# Cargamos las librerias a emplear 
library(dplyr)
library(tidyverse)
library(readr)
library(readxl)

######---- Carga base de datos de accesos de banda ancha fija en Mexico ----######

BAF_raw <- read_csv("data/TODO_BAF/TD_ACC_BAF_ITE_VA.csv", 
                    col_types = cols(ANIO = col_character(), 
                                     K_ACCESO_INTERNET = col_character(), 
                                     K_ENTIDAD = col_character(), K_MUNICIPIO = col_character(), 
                                     MES = col_character()), locale = locale(encoding = "ISO-8859-1"))

### Modificacmos los datos atipicos de de Mayapan (Yucatan) y Rayon (Estado de Mexico) ∫

# Los municipios circundates a Mayapan no tienen penetracion de BAF en cable coaxial ni fibra optica.
# Se considera que Mayapan tampoco (error en la base del Banco de informacion de Telecomunicaciones de Mexico)

indice_mayapan = (BAF_raw$ANIO == "2019")*(BAF_raw$ENTIDAD == "Yucatan")*(BAF_raw$MUNICIPIO == "Mayapan")
for (i in which(indice_mayapan==1)){
  BAF_raw$A_TOTAL_E[i]<-0
}

rm(indice_mayapan)
# El nivel reportado de penetracion para Rayon es muy alto debido a incosistencias con los accesos
# reportados por Megacable en los meses 04, 05 y 06 de 2019. Se les imputa el valor
# historico mas reciente, que es congruente con los datos historicos previos.


indice_rayon = (BAF_raw$ANIO == "2019")*(BAF_raw$ENTIDAD == "Mexico.")*(BAF_raw$MUNICIPIO == "Rayon..")*(BAF_raw$EMPRESA == "MEGACABLE")*(BAF_raw$TECNO_ACCESO_INTERNET == "Cable Coaxial")

indice_rayon_03 = which((indice_rayon*(BAF_raw$MES == "03"))==1)
indice_rayon_04 = which((indice_rayon*(BAF_raw$MES == "04"))==1)
indice_rayon_05 = which((indice_rayon*(BAF_raw$MES == "05"))==1)
indice_rayon_06 = which((indice_rayon*(BAF_raw$MES == "06"))==1)

BAF_raw$A_TOTAL_E[indice_rayon_04] <- BAF_raw$A_TOTAL_E[indice_rayon_03] 
BAF_raw$A_TOTAL_E[indice_rayon_05] <- BAF_raw$A_TOTAL_E[indice_rayon_03] 
BAF_raw$A_TOTAL_E[indice_rayon_06] <- BAF_raw$A_TOTAL_E[indice_rayon_03] 


### Transformacion y limpieza de la base de accesos

## Crea una llave para cruzar con las otras bases
BAF_study <- BAF_raw 
BAF_study$K_MUNICIPIO <- substr(BAF_study$K_MUNICIPIO,3,5)
BAF_study <- BAF_study  %>% mutate(K_ENTIDAD_MUNICIPIO = paste(K_ENTIDAD, K_MUNICIPIO, sep = ""))

## seleccion variable y alarga la bases de accesos por tecnologia

# suma los accesos de todos los operadores en el municipio por tecnologia
BAF_study <- BAF_study %>%  select(K_ENTIDAD_MUNICIPIO,K_ENTIDAD,K_MUNICIPIO, ANIO, MES,K_ACCESO_INTERNET, A_TOTAL_E) %>% 
  group_by(K_ENTIDAD_MUNICIPIO,K_ENTIDAD,K_MUNICIPIO, ANIO, MES,K_ACCESO_INTERNET) %>% summarise_all(funs(sum))

BAF_study <- BAF_study %>% ungroup()

BAF_study<- BAF_study %>% spread(K_ACCESO_INTERNET, A_TOTAL_E)

## El detalle de accesos a nivel municipal con NA se imputa con cero
BAF_study <- BAF_study %>% mutate_all(~replace(., is.na(.), 0))

# Renombramos columnas de accesos segun su tecnologia
names(BAF_study)[6] <- "CABLE_COAXIAL"
names(BAF_study)[7] <- "DSL"
names(BAF_study)[8] <- "FIBRA_OPTICA"
names(BAF_study)[9] <- "SATELITAL"
names(BAF_study)[10] <- "TERRESTRE_FIJO_INALAMBRICO"
names(BAF_study)[11] <- "OTRAS_TECNOLOGIAS"
names(BAF_study)[12] <- "SIN_TECNOLOGIA_ESPECIFICADA"

# Agregamos columna de todos los accesos del municipio
BAF_study <- BAF_study %>% mutate(ALL_ACCESS = CABLE_COAXIAL+DSL+FIBRA_OPTICA+SATELITAL+TERRESTRE_FIJO_INALAMBRICO+OTRAS_TECNOLOGIAS+SIN_TECNOLOGIA_ESPECIFICADA)

# Agregamos columna de todos los accesos cable coaxial y fibra optica del municipio
BAF_study <- BAF_study %>% mutate(COAX_FO = CABLE_COAXIAL+FIBRA_OPTICA)

# Se excluyen los datos de accesos que no tienen ubicacion de municipio
BAF_062019 <-  subset(BAF_study, ANIO == "2019" & MES == "06" & K_ENTIDAD != "99"  & K_MUNICIPIO != "999" )

# ----- Contamos la cantidad de empresas presentes en el municipio

# Filtramos la base en crudo para junio de 2019
BAF_raw062019<- BAF_raw %>%filter(ANIO=="2019" & MES == "06" & K_ENTIDAD != "99"  & K_MUNICIPIO != "999" )

## Crea una llave para cruzar con las otras bases
BAF_raw062019$K_MUNICIPIO <- substr(BAF_raw062019$K_MUNICIPIO,3,5)
BAF_raw062019 <- BAF_raw062019  %>% mutate(K_ENTIDAD_MUNICIPIO = paste(K_ENTIDAD, K_MUNICIPIO, sep = ""))

# Crea la base auxiliar que tiene por clave de municipio la cantidad de empresas de BAF en esta 
BAF_study_ops <- BAF_raw062019 %>% select(K_ENTIDAD_MUNICIPIO) %>% unique()
BAF_study_ops$NUM_OPS <-NA

for (i in 1:nrow(BAF_study_ops)){
  folio =BAF_study_ops$K_ENTIDAD_MUNICIPIO[i]
  n <- BAF_raw062019 %>% select(EMPRESA,K_ENTIDAD_MUNICIPIO) %>% filter(K_ENTIDAD_MUNICIPIO == BAF_study_ops$K_ENTIDAD_MUNICIPIO[i]) %>% unique() %>% nrow()
  BAF_study_ops$NUM_OPS[i]= n
}

# Agrega un columna de la cantidad total de empresas que cuentan con al menos un acceso de BAF en cada municipio
BAF_062019 <- left_join(BAF_062019,BAF_study_ops, by = "K_ENTIDAD_MUNICIPIO")

#----- Escribe la base final
write_csv(BAF_062019, "data/processed/BAF_062019.csv")

# Eliminamos objetos auxiliares
rm(BAF_raw,BAF_study,folio,i,n,BAF_study_ops,BAF_raw062019)


######---- Carga base de datos de accesos de CONAPO ----######

conapo <- read_csv("data/CONAPO/Base_Indice_de_marginacion_municipal_90-15.csv", col_types = cols(CVE_ENT = col_character(), 
                                                                                             CVE_MUN = col_character()), locale = locale(encoding = "ISO-8859-1"))
# Creamos variables de id de entidad y municipio
conapo$K_ENTIDAD<-NA
conapo$K_MUNICIPIO<-NA

for (index in 1:nrow(conapo)){
  conapo$K_ENTIDAD[index] = ifelse(nchar(conapo$CVE_ENT[index])==1, paste(0,conapo$CVE_ENT[index],sep=""),conapo$CVE_ENT[index])
}

for (index in 1:nrow(conapo)){
  conapo$K_MUNICIPIO[index] = ifelse(nchar(conapo$CVE_MUN[index])==4, substr(conapo$CVE_MUN[index],2,4),substr(conapo$CVE_MUN[index],3,5))
}

conapo<- conapo %>% mutate(K_ENTIDAD_MUNICIPIO = paste(K_ENTIDAD, K_MUNICIPIO,sep="")) 
conapo <- subset(conapo, ENT != "Nacional")

# Filtramos la base para seleccionar columnas y renglones de interes, en 2015
conapo <- conapo %>% select(K_ENTIDAD_MUNICIPIO,ANALF,SPRIM, OVSDE, OVSEE, OVSAE, VHAC, OVPT,"PL<5000" ,PO2SM,IM,GM, AÑO)
conapo <- subset(conapo, AÑO == "2015")
conapo$AÑO<-NULL

# Escribe la base de datos de conapo
write_csv(conapo, "data/processed/CONAPO_2015.csv")


######---- Carga DB de hogares por municipio en Mexico (Encuesta Intercensal INEGI, 2015) ----######

# Directorio donde se localizan los archivos a unir
left_path = "data/Intercensal2015/12_hogares_"
right_path = ".xls"
states_list = c("ags","bc","bcs","cam","coah","col","chis","chih","cdmx","dgo","gto","gro","hgo","jal","mex","mich","mor","nay","nl","oax","pue","qro","qroo","slp","sin","son","tab","tamps","tlax","ver"
                ,"yuc","zac")

# Funcion para extraer los datos de poblacion

cleaning_hog_state<-function(name_state){
  # Carga el archivo con el path descrito
  test <-read_excel(paste0(left_path,name_state,right_path), sheet = 3, col_names = FALSE, col_types = NULL, na = "", skip = 10)
  
  # Nombres temporales de las variables
  colnames(test)<- c("X1","X2","X3","X4","X5","X6","X7","X8","X9","X10","X11","X12","X13","X14","X15")
  
  # Filtrado para obtener datos de poblacion en municipios
  test<-subset(test, X2 != "Total" & X3 == "Total" & X4 == "Hogares"& X5 == "Valor")
  
  # seleccion de variables de estado, municipio y poblacion, para renombrarlas
  test<- test %>% select(X1,X2,X6)
  colnames(test)<- c("K_ENTIDAD","K_MUNICIPIO","HOGARES")
  
  # Obtiene claves de identificacion de estado y municipio
  test$K_ENTIDAD <- substr(test$K_ENTIDAD,1,2)
  test$K_MUNICIPIO<- substr(test$K_MUNICIPIO,1,3)
  
  # Crea nueva variable con clave y
  test <- test %>% mutate(K_ENTIDAD_MUNICIPIO = paste(K_ENTIDAD, K_MUNICIPIO, sep=""))
  test <-test %>% select(K_ENTIDAD_MUNICIPIO, HOGARES)
  
  return(test)
}

test_hogares = cleaning_hog_state("ags")

for (name_state in states_list ){
  test_hogares <- rbind(test_hogares,cleaning_hog_state(name_state))
  
}

# Elimina duplicados
test_hogares<-unique(test_hogares)
hogares2015 <- test_hogares

# Escribe la base de hogares en el municipio
write_csv(test_hogares,"data/processed/hogares2015.csv")

# Eliminamos objetos auxiliares
rm(test_hogares)

######---- Carga base de datos de poblacion por municipio en Mexico (Encuesta Intercensal INEGI, 2015) ----######

# Directorio donde se localizan los archivos a unir

left_path = "data/Intercensal2015/01_poblacion_"
right_path = ".xls"
states_list = c("ags","bc","bcs","cam","coah","col","chis","chih","cdmx","dgo","gto","gro","hgo","jal","mex","mich","mor","nay","nl","oax","pue","qro","qroo","slp","sin","son","tab","tamps","tlax","ver"
                ,"yuc","zac")

# Funcion para extraer los datos de poblacion

cleaning_pop_state<-function(name_state){
  # Carga el archivo con el path descrito
  test <-read_excel(paste0(left_path,name_state,right_path), sheet = 3, col_names = FALSE, col_types = NULL, na = "", skip = 10)
  
  # Nombres temporales de las variables
  colnames(test)<- c("X1","X2","X3","X4","X5","X6","X7")
  
  # Filtrado para obtener datos de poblacion en municipios
  test<-subset(test, X2 != "Total" & X3 == "Total" & X4 == "Valor")
  
  # seleccion de variables de estado, municipio y poblacion, para renombrarlas
  test<- test %>% select(X1,X2,X5)
  colnames(test)<- c("K_ENTIDAD","K_MUNICIPIO","POBLACION")
  
  # Obtiene claves de identificacion de estado y municipio
  test$K_ENTIDAD <- substr(test$K_ENTIDAD,1,2)
  test$K_MUNICIPIO<- substr(test$K_MUNICIPIO,1,3)
  
  # Crea nueva variable con clave y
  test <- test %>% mutate(K_ENTIDAD_MUNICIPIO = paste(K_ENTIDAD, K_MUNICIPIO, sep=""))
  test <-test %>% select(K_ENTIDAD_MUNICIPIO, POBLACION)
  
  return(test)
}

test = cleaning_pop_state("ags")

for (name_state in states_list ){
  test <- rbind(test,cleaning_pop_state(name_state))
  
}

# Elimina duplicados
test<-unique(test)
poblacion2015<-test

# Escribe la base de poblacion en el municipio
write_csv(poblacion2015,"data/processed/poblacion2015.csv")

#Eliminamos objeto auxiliar
rm(test)

#####---- Carga DB de indicadores de servicios de telecomunicaciones en municipios (Encuesta Intercesal INEGI, 2015) ----######

# Directorio donde se localizan los archivos a unir

left_path = "data/Intercensal2015/14_vivienda_"
right_path = ".xls"
states_list = c("ags","bc","bcs","cam","coah","col","chis","chih","cdmx","dgo","gto","gro","hgo","jal","mex","mich","mor","nay","nl","oax","pue","qro","qroo","slp","sin","son","tab","tamps","tlax","ver"
                ,"yuc","zac")

# Funcion para extraer los datos de indicadores de servicios de telecom en viviendas

cleaning_viv_state<-function(name_state){
  # Carga el archivo con el path descrito
  test <-read_excel(paste0(left_path,name_state,right_path), sheet = "22", col_names = FALSE, col_types = NULL, na = "", skip = 10)
  
  # Nombres temporales de las variables
  colnames(test)<- c("X1","X2","X3","X4","X5","X6","X7","X8")
  
  # Se eliminan renglones con texto que no es de interes
  test[-c(1,2,3,4,5,6,7,8),]
  
  # Filtrado para obtener datos de servicios de telecomunicaciones en municipios
  test <- filter(test, test$X3 == "Teléfono fijo" | test$X3 == "Teléfono celular" | test$X3 == "Internet" | test$X3 == "Servicio de televisión de paga")
  test <- filter(test, test$X2 != "Total" & test$X4 == "Valor")
  
  # seleccion de variables de estado, municipio y poblacion, para renombrarlas
  test<- test %>% select(X1,X2,X3,X6)
  colnames(test)<- c("K_ENTIDAD","K_MUNICIPIO","TIPO_BIEN_O_TECNOLOGIA","DISPONIBILIDAD")
  
  # Obtiene claves de identificacion de estado y municipio
  test$K_ENTIDAD <- substr(test$K_ENTIDAD,1,2)
  test$K_MUNICIPIO<- substr(test$K_MUNICIPIO,1,3)
  
  # Crea nueva variable con clave y
  test <- test %>% mutate(K_ENTIDAD_MUNICIPIO = paste(K_ENTIDAD, K_MUNICIPIO, sep=""))
  test <-test %>% select(K_ENTIDAD_MUNICIPIO, TIPO_BIEN_O_TECNOLOGIA, DISPONIBILIDAD)
  #test <- test %>% select
  return(test)
}

test_vivs = cleaning_viv_state("ags")

for (name_state in states_list ){
  test_vivs <- rbind(test_vivs,cleaning_viv_state(name_state))
  
}

# Elimina duplicados
test_vivs<-unique(test_vivs)
indicadores_servicios2015 <- test_vivs

# Alargamos las columnas para que los indicadores de dispobilidad de servicios de telecomunicaciones queden hacia la derecha
indicadores_servicios2015 <- indicadores_servicios2015 %>% spread(TIPO_BIEN_O_TECNOLOGIA, DISPONIBILIDAD)

# Cambiamos los nombres para que sea mas facil manejarlo
colnames(indicadores_servicios2015) <- c("K_ENTIDAD_MUNICIPIO","DISP_INTERNET", "DISP_TV_PAGA", "DISP_TEL_CELULAR", "DISP_TEL_FIJO")

# Escribe la base de hogares en el municipio
write_csv(indicadores_servicios2015,"data/processed/indicadores_servicios2015.csv")


######---- Carga DB Indice de Desarrollo Humano (programa de las Naciones Unidas para el Desarrollo (PNUD, 2015)) ----######


hd_index2015 <- read_excel("data/IndiceDH/Bases de datos y programas de calculo/Resultados IDH/MOD_Indice de Desarrollo Humano Municipal_2010_2015.xlsx", 
                           sheet = "IDH_extract", col_types = c("text", 
                                                                "skip", "skip", "skip", "skip", "skip", 
                                                                "skip", "numeric", "numeric", "numeric", 
                                                                "numeric", "numeric", "numeric", 
                                                                "numeric", "numeric", "skip"))

# Escribe la base de hogares en el municipio
write_csv(hd_index2015,"data/processed/indicadores_servicios2015.csv")



######---- Carga DB, de INAFED con superficie de municipios de Mexico ----######

INAFED <- read_csv("data/INAFED/inafed_clean.csv") %>% 
  select("cve_inegi","id_estado","id_municipio","superficie")

# Acotamos la seleccion a datos por municipio (i.e sin resumenes por estado/pais), renombrando las variables
INAFED <- subset(INAFED, id_municipio != "0")
INAFED <- INAFED %>%  select("cve_inegi","superficie")
colnames(INAFED) <- c("K_ENTIDAD_MUNICIPIO","SUPERFICIE")

# De acuerdo al analisis, existen dos municipios de INAFED, que no cuentan con clave geoestadistica del Censo Intercensal 2015 (INEGI)
# Se hacen las imputaciones correspondientes para poder hacer joints con las otras bases de datos

# Se agregan dos datos faltantes en la base del INAFED
de<-data.frame("07036",48.24) # Ver http://inafed.gob.mx/work/enciclopedia/EMM07chiapas/municipios/07036a.html
names(de)<-c("K_ENTIDAD_MUNICIPIO","SUPERFICIE")
INAFED <- rbind(INAFED,de)

de<-data.frame("23010",20.1) # Ver https://es.wikipedia.org/wiki/Municipio_de_Bacalar
names(de)<-c("K_ENTIDAD_MUNICIPIO","SUPERFICIE")
INAFED <- rbind(INAFED,de)

# Escribe la base de superficies
write_csv(INAFED, "data/processed/INAFED_surface.csv")

# elimina variable auxiliar
rm(de)


#####---- Creacion DB con todos los datos socio-demograficos, de infraestructura y accesos de banda ancha fija en MExico ----#####

# Elimina variables auxiliares
rm(left_path,name_state,right_path,states_list,cleaning_hog_state,cleaning_pop_state,indice_rayon,indice_rayon_03,indice_rayon_04,indice_rayon_05,indice_rayon_06,cleaning_viv_state)

# Consolidamos las bases
df <- left_join(hogares2015,poblacion2015, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,conapo, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,INAFED, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,indicadores_servicios2015, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,BAF_062019, by = "K_ENTIDAD_MUNICIPIO")

## El detalle de accesos a nivel municipal con NA se imputa con cero
df <- df %>% mutate_all(~replace(., is.na(.), 0))

df$SUPERFICIE<- as.numeric(df$SUPERFICIE)
df$PO2SM<- as.numeric(df$PO2SM)

# Se eliminan columas sin interes para el analisis
df$K_ENTIDAD<-NULL
df$K_MUNICIPIO<-NULL
df$ANIO<-NULL
df$MES<-NULL

# df1 <- df
# Se cambian algunas variables de caracteres a numericas
# df1 <- df1 %>% select(-K_ENTIDAD_MUNICIPIO,-GM)
df$SPRIM <- as.numeric(df$SPRIM)
df$OVSDE <- as.numeric(df$OVSDE)
df$VHAC <- as.numeric(df$VHAC)
df$OVPT <- as.numeric(df$OVPT)
df$`PL<5000` <- as.numeric(df$`PL<5000`)

# Crea variable de densidad de hogares por kilometros cuadrados

df$DENS_HOGS <- 0
for (i in 1:nrow(df)){
  df$DENS_HOGS[i]<- df$HOGARES[i]/df$SUPERFICIE[i]*100
}

# Crea variable de densidad de personas por kilometros cuadrados
df$DENS_HABS <- 0
for (i in 1:nrow(df)){
  df$DENS_HABS[i]<- df$HOGARES[i]/df$SUPERFICIE[i]*100
}

# Crea variable de penetracion de BAF por cada 100 hogares y la penetracion de cable coaxial + fibra optica
df$PEN_BAF_HOGS_COAXFO <- 0
for (i in 1:nrow(df)){
  df$PEN_BAF_HOGS_COAXFO[i]<- df$COAX_FO[i]/df$HOGARES[i]*100
}

# Crea variable de penetracion de BAF por cada 100 habitantes y la penetracion de cable coaxial + fibra optica

df$PEN_BAF_HABS_COAXFO <- 0
for (i in 1:nrow(df)){
  df$PEN_BAF_HABS_COAXFO[i]<- df$COAX_FO[i]/df$POBLACION[i]*100
}

# Creamos una columna para clasificar los municipios segun su grado de penetracion.
#La clasificación de Penetracion de Fibra Óptica y Cable Coaxial:
# Sin cobertura=0
# Muy baja 0>25%
# Baja 25%>50%
# Media 50%>75%
# Alta 75%>100%
# Muy Alta 100%

df$CLASS_PEN_BAF_HOGS_COAXFO <- 0

for (index in 1:nrow(df)){
  df$CLASS_PEN_BAF_HOGS_COAXFO[index] <- if_else(df$PEN_BAF_HOGS_COAXFO[index]==0,0, 
                                                 if_else(df$PEN_BAF_HOGS_COAXFO[index]<=25,1,
                                                         if_else(df$PEN_BAF_HOGS_COAXFO[index]<=50,2,
                                                                 if_else(df$PEN_BAF_HOGS_COAXFO[index]<=75,3, 
                                                                         if_else(df$PEN_BAF_HOGS_COAXFO[index]<=100,4,5)))))
}


# Creamos una columna para clasificar los municipios segun su grado de penetracion.
#La clasificación de Penetracion de Fibra Óptica y Cable Coaxial:
# Sin cobertura=0
# Muy baja 0>25%
# Baja 25%>50%
# Media 50%>75%
# Alta 75%>100%
# Muy Alta 100%

df$CLASS_PEN_BAF_HABS_COAXFO <- 0

for (index in 1:nrow(df)){
  df$CLASS_PEN_BAF_HABS_COAXFO[index] <- if_else(df$PEN_BAF_HABS_COAXFO[index]==0,0, 
                                                 if_else(df$PEN_BAF_HABS_COAXFO[index]<=10,1,
                                                         if_else(df$PEN_BAF_HABS_COAXFO[index]<=20,2,
                                                                 if_else(df$PEN_BAF_HABS_COAXFO[index]<=30.92,3,4))))
}

df$IS_PEN_BAF_HABS_COAXFO <- 0

for (index in 1:nrow(df)){
  df$IS_PEN_BAF_HABS_COAXFO[index] <- if_else(df$CLASS_PEN_BAF_HABS_COAXFO[index]!=0,1,0)
}

#----- Agregamos una columna que nos diga la region socioecnomica a la que pertenece el municipio

RegionesSocioEcono <- read_csv("RegionesSocioEcono.csv", 
                               col_types = cols(NOM_ABRE_ENTIDAD = col_skip(), 
                                                NOM_ENTIDAD = col_skip(), NUM = col_skip()))
df <- df %>% mutate(K_ENTIDAD = substr(K_ENTIDAD_MUNICIPIO,1,2))
df <- left_join(df,RegionesSocioEcono, by = "K_ENTIDAD")

df$K_ENTIDAD<-NULL

for (index in 1:nrow(df)){
  df$REG_SOCIOECONOM[index] <- if_else(df$REG_SOCIOECONOM[index]=="Centronorte",1, 
                                       if_else(df$REG_SOCIOECONOM[index]=="Centrosur",2,
                                               if_else(df$REG_SOCIOECONOM[index]=="Noreste",3,
                                                       if_else(df$REG_SOCIOECONOM[index]=="Noroeste",4,
                                                               if_else(df$REG_SOCIOECONOM[index]=="Occidente",5,
                                                                       if_else(df$REG_SOCIOECONOM[index]=="Oriente",6,
                                                                               if_else(df$REG_SOCIOECONOM[index]=="Sureste",7,8)))))))
}


# Adjuntamos los datos de indices de derechos humanos
df <- left_join(df, hd_index2015, by = "K_ENTIDAD_MUNICIPIO")


######---- Seleccionamos columnas para el analisis y escribimos la base para Python ----######

# Base completa para EDA
write_csv(df, "data/processed/BAF_062019_EDA.csv")

# Bases de datos para correr modelos en Python

df1<- df %>% select(K_ENTIDAD_MUNICIPIO, HOGARES, POBLACION, SUPERFICIE, DENS_HOGS, DENS_HABS,
                    ANALF, SPRIM, ANOS_PROMEDIO_DE_ESCOLARIDAD,OVSAE, OVSEE, 'PL<5000', PO2SM, INGRESOPC_ANUAL,
                    DISP_INTERNET, DISP_TV_PAGA, DISP_TEL_CELULAR, DISP_TEL_FIJO, 
                    NUM_OPS, CLASS_PEN_BAF_HABS_COAXFO, IS_PEN_BAF_HABS_COAXFO)

# Base para el problema de detecion de penetracion sin importar el nivel
write_csv(df1, "data/processed/BAF_062019_P1.csv")

# Base para el problema de detecion del nivel de penetracion
write_csv(df1, "data/processed/BAF_062019_P2.csv")






