library(readxl)
library(tidyverse)

hd_index2015 <- read_excel("IndiceDH/Bases de datos y programas de calculo/Resultados IDH/MOD_Indice de Desarrollo Humano Municipal_2010_2015.xlsx", 
                       sheet = "IDH_extract", col_types = c("text", 
                                                            "skip", "skip", "skip", "skip", "skip", 
                                                            "skip", "numeric", "numeric", "numeric", 
                                                            "numeric", "numeric", "numeric", 
                                                            "numeric", "numeric", "skip"))

# Escribe la base de hogares en el municipio
write_csv(hd_index2015,"indicadores_servicios2015.csv")