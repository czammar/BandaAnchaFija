library(readr)
library(tidyverse)
library(ggplot2)
#library("tidyverse")

######---- Carga base de datos de accesos de banda ancha fija ----######

BAF_raw <- read_csv("TODO_BAF/TD_ACC_BAF_ITE_VA.csv", 
                              col_types = cols(ANIO = col_character(), 
                                               K_ACCESO_INTERNET = col_character(), 
                                               K_ENTIDAD = col_character(), K_MUNICIPIO = col_character(), 
                                               MES = col_character()), locale = locale(encoding = "ISO-8859-1"))

######---- Transformacion y limpieza de la base de accesos ----#####

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
write_csv(BAF_062019, "BAF_06209.csv")

# Eliminamos objetos auxiliares
rm(BAF_raw,BAF_study,folio,i,n,BAF_study_ops,BAF_raw062019)

####---- Resumenes

# # Tabla resumen de conexiones por anio
# year_resume <- BAF_raw %>% select(ANIO, MES, A_TOTAL_E) %>% group_by(ANIO,MES) %>% 
#   summarize(n=sum(A_TOTAL_E,na.rm = TRUE)/1000000) %>% ungroup()
# 
# year_resume <- mutate(year_resume, key_yearmonth = paste(year_resume$ANIO, year_resume$MES,sep = ""))
# 
# #ggplot(year_resume, aes(key_yearmonth, n)) + geom_bar(stat = "identity")
# 
# # Tabla resumen de conexiones por anio, con desagregacion de tecnologia
# technology_resume<-BAF_raw %>% select(ANIO, MES, K_ACCESO_INTERNET, TECNO_ACCESO_INTERNET, A_TOTAL_E) %>% group_by(ANIO, MES, K_ACCESO_INTERNET, TECNO_ACCESO_INTERNET) %>% 
#   summarize(n=sum(A_TOTAL_E,na.rm = TRUE)/1000000) %>% ungroup()