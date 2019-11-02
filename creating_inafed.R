library(readr)
library(dplyr)

######---- Carga base de datos de poblacion del inafed seleccionando datos de superficie----######

INAFED <- read_csv("INAFED/inafed_clean.csv") %>% 
  select("cve_inegi","id_estado","id_municipio","superficie")

# Acotamos la seleccion a datos por municipio (i.e sin resumenes por estado/pais), renombrando las variables
INAFED <- subset(INAFED, id_municipio != "0")
INAFED <- INAFED %>%  select("cve_inegi","superficie")
colnames(INAFED) <- c("K_ENTIDAD_MUNICIPIO","SUPERFICIE")


# Escribe la base de superficies
write_csv(INAFED, "INAFED_surface.csv")