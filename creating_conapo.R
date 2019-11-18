library(readr)
library(tidyverse)

######---- Carga base de datos de accesos de CONAPO ----######
conapo <- read_csv("CONAPO/Base_Indice_de_marginacion_municipal_90-15.csv", col_types = cols(CVE_ENT = col_character(), 
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
write_csv(conapo, "CONAPO_2015.csv")
