library(readr)
library(tidyverse)
library(readxl)

# Establece directorio de trabajo
setwd("/media/Box/Aprendizaje_Maquina/Projecto")

# Crear las bases de datos para trabajar
source("creating_baf.R") # Accesos de banda ancha fija a junio/2019 BIT del IFT
source("creating_conapo.R") # Indice marginacion y porcentaje pob con menos de 2 salarios min, 2015 CONAPO
source("creating_inafed.R") # Superficie de municipios, INAFED
source("creating_indiceinfraestructura.R")  # Indice infraestructura TII - centro de estudios IFT
source("creating_hogares.R") # Hogares por municipios Encuesta intercensal 2015, INEGI
source("creating_poblacion.R") # Poblacion por municipios Encuesta intercensal 2015, INEGI

# Elimina variables auxiliares
rm(index, left_path,name_state,right_path,states_list,cleaning_hog_state,cleaning_pop_state)

# Consolidamos las bases
df <- left_join(hogares2015,poblacion2015, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,conapo, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,INAFED, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,infraestructura_index, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,BAF_062019, by = "K_ENTIDAD_MUNICIPIO")

df$SUPERFICIE<- as.numeric(df$SUPERFICIE)
df$PO2SM<- as.numeric(df$PO2SM)

# Se eliminan columas sin interes para el analisis
df$K_ENTIDAD<-NULL
df$K_MUNICIPIO<-NULL
df$ANIO<-NULL
df$MES<-NULL

## El detalle de accesos a nivel municipal con NA se imputa con cero
df <- df %>% mutate_all(~replace(., is.na(.), 0))

# Crea variable de penetracion de BAF por cada 100 hogares y la penetracion de cable coaxial + fibra optica
df <- df %>% mutate(PEN_BAF = df$ALL_ACCESS/df$HOGARES*100)
df$PEN_BAF_COAXFO <- 0
for (i in 1:nrow(df)){
df$PEN_BAF_COAXFO[i]<- df$COAX_FO[i]/df$HOGARES[i]*100
}

# Crea variable de densidad de hogares por kilometros cuadrados
#df <- df %>% mutate(DENS_HOGS = df$HOGARES/df$SUPERFICIE)

df$DENS_HOGS <- 0
for (i in 1:nrow(df)){
  df$DENS_HOGS[i]<- df$HOGARES[i]/df$SUPERFICIE[i]*100
}

# Creamos una columna para clasificar los municipios segun su grado de penetracion.
#La clasificación de Penetracion de Fibra Óptica y Cable Coaxial:
# Sin cobertura=0
# Muy baja 0>25%
# Baja 25%>50%
# Media 50%>75%
# Alta 75%>100%
# Muy Alta 100%

df$PEN_CLASS <- NA

for (index in 1:nrow(df)){
  df$PEN_CLASS[index] <- if_else(df$PEN_BAF_COAXFO[index]==0,0, 
                                 if_else(df$PEN_BAF_COAXFO[index]<=25,1,
                                         if_else(df$PEN_BAF_COAXFO[index]<=50,2,
                                                 if_else(df$PEN_BAF_COAXFO[index]<=75,3, 
                                                         if_else(df$PEN_BAF_COAXFO[index]<=100,4,5)))))
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

# ---- Seleccionamos columnas para el analisis 

df1<- df %>% select(HOGARES, POBLACION, PO2SM, IM, SUPERFICIE, INFRA_INDEX, ALL_ACCESS, NUM_OPS, DENS_HOGS, PEN_CLASS)

write_csv(df1, "BAF_06209_selected.csv")
