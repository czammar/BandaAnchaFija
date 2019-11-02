library(readr)
library(tidyverse)

# Cargamos la base de datos del indice de infraestructura seleccionado ciertas variables
infraestructura_index <- read_csv("Index_Telecom/Values.csv")
infraestructura_index <- infraestructura_index %>% select(K_ENTIDAD_MUNICIPIO, VALUE)

# Renombramos sus columnas 
colnames(infraestructura_index) <- c("K_ENTIDAD_MUNICIPIO","INFRA_INDEX")