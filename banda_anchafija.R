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

# Se eliminan columas sin interes para el analisis
df$K_ENTIDAD<-NULL
df$K_MUNICIPIO<-NULL
df$ANIO<-NULL
df$MES<-NULL

## El detalle de accesos a nivel municipal con NA se imputa con cero
df <- df %>% mutate_all(~replace(., is.na(.), 0))

# Crea variable de penetracion de BAF por cada 100 hogares y la penetracion de cable coaxial + fibra optica
df <- df %>% mutate(PEN_BAF = df$ALL_ACCESS/df$HOGARES*100)
df <- df %>% mutate(PEN_BAF_COAXFO = df$COAX_FO/df$HOGARES*100)

# Crea variable de densidad de hogares por kilometros cuadrados
df <- df %>% mutate(DENS_HOGS = df$HOGARES/df$SUPERFICIE)




