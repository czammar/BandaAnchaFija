# Archivo creating_inafed.R

library(readr)
library(dplyr)

######---- Carga base de datos de poblacion del inafed seleccionando datos de superficie----######

INAFED <- read_csv("INAFED/inafed_clean.csv") %>% 
  select("cve_inegi","id_estado","id_municipio","superficie")

# Acotamos la seleccion a datos por municipio (i.e sin resumenes por estado/pais), renombrando las variables
INAFED <- subset(INAFED, id_municipio != "0")
INAFED <- INAFED %>%  select("cve_inegi","superficie")
colnames(INAFED) <- c("K_ENTIDAD_MUNICIPIO","SUPERFICIE")

# Se agregan dos datos faltantes en la base del INAFED
de<-data.frame("07036",48.24) # Ver http://inafed.gob.mx/work/enciclopedia/EMM07chiapas/municipios/07036a.html
names(de)<-c("K_ENTIDAD_MUNICIPIO","SUPERFICIE")
INAFED <- rbind(INAFED,de)

de<-data.frame("23010",20.1) # Ver https://es.wikipedia.org/wiki/Municipio_de_Bacalar
names(de)<-c("K_ENTIDAD_MUNICIPIO","SUPERFICIE")
INAFED <- rbind(INAFED,de)

# Escribe la base de superficies
write_csv(INAFED, "INAFED_surface.csv")

# elimina variable auxiliar
rm(de)