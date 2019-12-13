# Archivo Mapas

# Script para crecion mapas de penetracion BAF

# Libreria
library("mxmaps") #Ver https://www.diegovalle.net/mxmaps/
library("scales")
library("readxl")
library("ggplot2")
library("tidyverse")
library("readr")
library(leaflet) # Libreria para invocar la funcion colorNumeric de paleta de colores
library(mxmaps)
library(viridis) # Libreria para paleta de colores
library(scales) # Libreria auxiliar para colores


# Establece directorio de trabajo
setwd("/media/Box/Aprendizaje_Maquina/Projecto")

# Crear las bases de datos para trabajar
source("creating_baf.R") # Accesos de banda ancha fija a junio/2019 BIT del IFT
source("creating_hogares.R") # Hogares por municipios Encuesta intercensal 2015, INEGI
source("creating_poblacion.R") # Poblacion por municipios Encuesta intercensal 2015, INEGI

# Cargamos la base de datos de nombre de estados y municipios para usarla en los mapas
Nombres <- read_csv("Nombres_entidad_municipio.csv", locale = locale(encoding = "ISO-8859-1"))
Nombres <- Nombres %>% select(K_ENTIDAD_MUNICIPIO,nom_ent,nom_mun)

# Consolidamos las bases
df <- left_join(hogares2015,poblacion2015, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,BAF_062019, by = "K_ENTIDAD_MUNICIPIO")
df <- left_join(df,Nombres, by = "K_ENTIDAD_MUNICIPIO")


# Imputamos ceros donde no hay datos de penetracion
df <- df %>% mutate_all(~replace(., is.na(.), 0))

# Elimina variables auxiliares
rm(left_path,name_state,right_path,states_list,cleaning_hog_state,cleaning_pop_state, hogares2015,poblacion2015, BAF_062019, INAFED)


# Seleccionamos variables de interes y creamos otras
df <- df %>% select(K_ENTIDAD_MUNICIPIO, K_ENTIDAD, K_MUNICIPIO,nom_ent, nom_mun, HOGARES, POBLACION, ALL_ACCESS, COAX_FO)
df <- df %>% mutate(PEN_BAF_HOGS = 100*COAX_FO/HOGARES) # Penetracion por cada 100 hogares
df <- df %>% mutate(PEN_BAF_HABS = 100*COAX_FO/POBLACION) # Penetracion por cada 100 hogares

# Agregamos una columna que nos diga la region socioecnomica a la que pertenece el municipio

RegionesSocioEcono <- read_csv("RegionesSocioEcono.csv", 
                               col_types = cols(NOM_ABRE_ENTIDAD = col_skip(), 
                                                NOM_ENTIDAD = col_skip(), NUM = col_skip()))
df <- df %>% mutate(K_ENTIDAD = substr(K_ENTIDAD_MUNICIPIO,1,2))
df <- left_join(df,RegionesSocioEcono, by = "K_ENTIDAD")

for (index in 1:nrow(df)){
  df$REG_SOCIOECONOM[index] <- if_else(df$REG_SOCIOECONOM[index]=="Centronorte",1, 
                                       if_else(df$REG_SOCIOECONOM[index]=="Centrosur",2,
                                               if_else(df$REG_SOCIOECONOM[index]=="Noreste",3,
                                                       if_else(df$REG_SOCIOECONOM[index]=="Noroeste",4,
                                                               if_else(df$REG_SOCIOECONOM[index]=="Occidente",5,
                                                                       if_else(df$REG_SOCIOECONOM[index]=="Oriente",6,
                                                                               if_else(df$REG_SOCIOECONOM[index]=="Sureste",7,8)))))))
}






########## Mapa dinamico de penetracion por cada 100 hogares en todos los municpios de mexico ##########

# Creamos una variable para hacer mapas de penetracion de cable coaxial y fibra optica
PenetrationBAF_Hogares <- df

# Crea nombres de columnas value y region que se necesita para usan alimentar la función mxmunicipio_choropleth
PenetrationBAF_Hogares$value <- PenetrationBAF_Hogares$PEN_BAF_HOGS # Valores para escala de colores
PenetrationBAF_Hogares$region <- PenetrationBAF_Hogares$K_ENTIDAD_MUNICIPIO # Llave principal de municipios de INEGI


# Definicion de paleta de colores a partir de valores de penetracion
# "RdYlBu", "Accent", or "Greens"
#"viridis", "magma", "inferno", or "plasma".

# Spectral para el mapa de BAF para hogares
pal <- colorNumeric(palette = "magma", domain = PenetrationBAF_Hogares$value) 

mxmunicipio_leaflet(PenetrationBAF_Hogares,
                    pal,
                    ~ pal(value),
                    ~ sprintf("Estado: %s<br/>Municipio : %s<br/>Penetración: %s ",
                              nom_ent, nom_mun, round(value,1))) %>%
  addLegend(position = "topright", 
            pal = pal, 
            values = PenetrationBAF_Hogares$value,
            title = "Accesos de cable coaxial y fibra <br/>  óptica por cada 100 hogares",
            labFormat = labelFormat(suffix = "",
                                    transform = function(x) {x})) %>%
  addProviderTiles("CartoDB.Positron")



########## Mapa dinamico de penetracion por cada 100 habitantes en todos los municpios de mexico ##########

# Creamos una variable para hacer mapas de penetracion de cable coaxial y fibra optica
PenetrationBAF_Habitantes <- df

# Crea nombres de columnas value y region que se necesita para usan alimentar la función mxmunicipio_choropleth
PenetrationBAF_Habitantes$value <- PenetrationBAF_Habitantes$PEN_BAF_HABS # Valores para escala de colores
PenetrationBAF_Habitantes$region <- PenetrationBAF_Habitantes$K_ENTIDAD_MUNICIPIO # Llave principal de municipios de INEGI


# Definicion de paleta de colores a partir de valores de penetracion
# http://www.di.fc.ul.pt/~jpn/r/GraphicalTools/colorPalette.html
# "RdYlBu", "Accent", or "Greens"
#"viridis", "magma", "inferno", or "plasma".

# Spectral para el mapa de BAF para hogares
pal <- colorNumeric(palette = "Spectral", domain = PenetrationBAF_Habitantes$value) 

mxmunicipio_leaflet(PenetrationBAF_Habitantes,
                    pal,
                    ~ pal(value),
                    ~ sprintf("Estado: %s<br/>Municipio : %s<br/>Penetración: %s ",
                              nom_ent, nom_mun, round(value,1))) %>%
  addLegend(position = "topright", 
            pal = pal, 
            values = PenetrationBAF_Habitantes$value,
            title = "Accesos de cable coaxial y fibra <br/>  óptica por cada 100 habitantes",
            labFormat = labelFormat(suffix = "",
                                    transform = function(x) {x})) %>%
  addProviderTiles("CartoDB.Positron")



####---- Mapa estatico de penetracion BAF en todos los municpios de mexico version 1 ----####

# num_colors puede tomar valores enteros de 1 a 9, donde 1 es una escala continua, 
# y 2, 3 ... significa divisiones del rango de penetracion

# mxmunicipio_choropleth(PenetrationBAF_Hogares, num_colors = 1, 
#                        title = "Penetración de servicios fijos de Internet en México",
#                        legend = "Accesos por cada \n        100 hogares")
# 

########## Mapa estatico de penetracion BAF en todos los municpios de mexico version 2 ##########
# gg = MXMunicipioChoropleth$new(PenetrationBAF_Hogares)
# 
# gg$title <- "Penetración de servicios fijos de Internet en México"
# gg$set_num_colors(1)
# 
# # el parametro option toma valores de letras (A,B,C,D ...) y arroja diferentes opciones de paletas de colores
# gg$ggplot_scale <- scale_fill_viridis("Accesos por \n cada 100 hogares",option="C")
# 
# # Muestra el mapa
# gg$render()

########## Mapas estaticos de penetracion BAF de los municpios de mexico por estado ##########
# 
# 
# # Variable auxiliar para escala de colores de num_colors
# Idx= 8
# 
# # Nota: se hace uso de la funcion zoom para crear un filtro con el nombre del estado (columna nom_ent)
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Aguascalientes"))$region,
#                        title = "Aguascalientes - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Baja California"))$region,
#                        title = "Baja California - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Baja California Sur"))$region,
#                        title = "Baja California Sur- Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Campeche"))$region,
#                        title = "Campeche - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Coahuila de Zaragoza"))$region,
#                        title = "Coahuila - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Colima"))$region,
#                        title = "Colima - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Chiapas"))$region,
#                        title = "Chiapas - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Chihuahua"))$region,
#                        title = "Chihuahua - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Distrito Federal"))$region,
#                        title = "CDMX - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Durango"))$region,
#                        title = "Durango - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Guanajuato"))$region,
#                        title = "Guanajuato - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Guerrero"))$region,
#                        title = "Guerrero - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Hidalgo"))$region,
#                        title = "Hidalgo - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Jalisco"))$region,
#                        title = "Jalisco - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("México"))$region,
#                        title = "Estado de México - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Michoacán de Ocampo"))$region,
#                        title = "Michoacán - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Morelos"))$region,
#                        title = "Morelos - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Nayarit"))$region,
#                        title = "Nayarit - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Nuevo León"))$region,
#                        title = "Nuevo León - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Oaxaca"))$region,
#                        title = "Oaxaca - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Puebla"))$region,
#                        title = "Puebla - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Querétaro"))$region,
#                        title = "Querétaro - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Quintana Roo"))$region,
#                        title = "Quintana Roo - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("San Luis Potosí"))$region,
#                        title = "San Luis Potosí - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Sinaloa"))$region,
#                        title = "Sinaloa - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Sonora"))$region,
#                        title = "Sonora - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Tabasco"))$region,
#                        title = "Tabasco - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Tamaulipas"))$region,
#                        title = "Tamaulipas - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Tlaxcala"))$region,
#                        title = "Tlaxcala - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Veracruz de Ignacio de la Llave"))$region,
#                        title = "Veracruz - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Yucatán"))$region,
#                        title = "Yucatán - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Zacatecas"))$region,
#                        title = "Zacatecas - Accesos para servicios fijos de Internet por cada 100 hogares",
#                        legend = "Accesos por \n cada 100 hogares")
# 
# 
# 
# ########## Mapas estaticos de penetracion BAF de los municpios de mexico por regiones socioeconomicas ##########
# 
# # Nota: se hace uso de la funcion zoom para crear un filtro con el nombre del estado (columna nom_ent)
# 
# # Region Noroeste
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Baja California", "Baja California Sur", "Chihuahua", "Durango", "Sinaloa", "Sonora"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Región Noroeste (Baja California, Baja California Sur, \n Chihuahua, Durango, Sinaloa y Sonora )",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# # Region Noroeste
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Coahuila de Zaragoza", "Nuevo León", "Tamaulipas"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Región Noreste (Coahuila, Nuevo León y Tamaulipas) ",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# # Region Occidente
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Colima", "Jalisco", "Michoacán de Ocampo", "Nayarit"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Región Occidente (Colima, Jalisco, Michoacán y Nayarit)",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# # Region Oriente
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Hidalgo", "Puebla", "Tlaxcala", "Veracruz de Ignacio de la Llave"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Región Oriente (Hidalgo, Puebla, Tlaxcala y Veracruz)",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# # Region Centronorte
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Aguascalientes", "Guanajuato", "Querétaro", "San Luis Potosí", "Zacatecas"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Región Centronorte (Aguascalientes, Guanajuato, Querétaro, \n San Luis Potosí y Zacatecas)",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# # Region Centrosur
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("México", "Distrito Federal", "Morelos"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Region Centrosur (CDMX, Estado de México y Morelos)",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# # Region Suroeste
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Chiapas", "Guerrero", "Oaxaca"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Región Suroeste (Chiapas, Guerrero y Oaxaca) ",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# # Region Sureste
# mxmunicipio_choropleth(PenetrationBAF, num_colors = Idx,
#                        zoom = subset(PenetrationBAF,nom_ent %in% c("Campeche", "Quintana Roo", "Tabasco", "Yucatán"))$region,
#                        title = "Accesos para servicios fijos de Internet por cada 100 hogares \n Región Sureste (Campeche, Tabasco, Quintana Roo y Yucatán)",
#                        show_states = TRUE,
#                        legend = "Accesos por \n cada 100 hogares")
# 
# 
# 
# 
# ## Mapas de municipios tipo tras clustering
# 
# library(readxl)
# library(ggplot)
# 
# 
# #Cluster8BAF <- read_excel("E:/1. IFT/1. UPR/11. Proyecto - Cobertura/Analisis - Accesos Fijos Internet - CGPE 4Q2018 - 22052019 1206pm.xlsx", 
# #                          sheet = "ClusterDB8a_BAF")
# 
# Cluster8BAF <- read_excel("/home/cesar/Escritorio/11. Proyecto - Cobertura/Analisis - Accesos Fijos Internet - CGPE 4Q2018 - 22052019 1206pm.xlsx", 
#                           sheet = "ClusterDB8a_BAF")
# 
# 
# 
# Cluster8BAF$region <- Cluster8BAF$Main_Key
# Cluster8BAF$value <- Cluster8BAF$cluster
# #Cluster8BAF$value <- as.factor(Cluster8BAF$cluster)
# 
# 
# # Centronorte
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Centronorte"))$region,
#                        title = "Municipios Tipo de la región Centronorte \n (Aguascalientes, Guanajuato, Querétaro, San Luis Potosí y Zacatecas)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 
# 
# # Centrosur
# Cluster8BAF$value <- as.factor(Cluster8BAF$cluster)
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Centrosur"))$region,
#                        title = "Municipios Tipo de la región Centrosur \n (CDMX, Estado de México y Morelos)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 
# # Noreste
# Cluster8BAF$value <- Cluster8BAF$cluster
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Noreste"))$region,
#                        title = "Municipios Tipo de la región Noreste \n (Coahuila, Nuevo León y Tamaulipas)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 
# # Noroeste
# Cluster8BAF$value <- as.factor(Cluster8BAF$cluster)
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Noroeste"))$region,
#                        title = "Municipios Tipo de la región Noroeste \n (Baja California, Baja California Sur, Chihuahua, Durango, Sinaloa y Sonora)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 
# # Occidente
# #Cluster8BAF$value <- Cluster8BAF$cluster
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Occidente"))$region,
#                        title = "Municipios Tipo de la región Occidente \n (Colima, Jalisco, Michoacán de Ocampo y Nayarit)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 
# # Oriente
# Cluster8BAF$value <- Cluster8BAF$cluster
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Oriente"))$region,
#                        title = "Municipios Tipo de la región Oriente \n (Hidalgo, Puebla, Tlaxcala y Veracruz)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 
# # Sureste
# Cluster8BAF$value <- Cluster8BAF$cluster
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Sureste"))$region,
#                        title = "Municipios Tipo de la región Sureste \n (Campeche, Quintana Roo, Tabasco y Yucatán)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 
# # Suroeste
# Cluster8BAF$value <- Cluster8BAF$cluster
# 
# mxmunicipio_choropleth(Cluster8BAF, num_colors = 9,
#                        zoom = subset(Cluster8BAF,REG_SOCIOECONOM %in% c("Suroeste"))$region,
#                        title = "Municipios Tipo de la región Suroeste \n (Chiapas, Guerrero y Oaxaca)",
#                        show_states = TRUE,
#                        legend = "Municipio \n Tipo")
# 

