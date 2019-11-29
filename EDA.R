#library(shiny)
#library(plotly)
library(ggplot2)
library(dplyr)
library(tidyverse)

# Para ejectuar este archivo, por favor situarse en la ruta donde esta el archivo csv con los datos
# Cargamos los datos limpios
# Nota: modificar en la ruta donde almacenan los datos
df1 <- read_csv("/media/Box/Aprendizaje_Maquina/Projecto/BAF_06209_P2.csv")

# Aqui especificamos cuales con las variables categoricas
# Nota: la lista de los nombres de estas variables se tiene que escribir en la linea 32
df1$CLASS_PEN_BAF_HABS_COAXFO <- as.character(df1$CLASS_PEN_BAF_HABS_COAXFO)
df1$IS_PEN_BAF_HABS_COAXFO <- as.character(df1$IS_PEN_BAF_HABS_COAXFO)
df1$NUM_OPS <- as.character(df1$NUM_OPS)

#



# Penetracion vs Ingreso

ggplot(df1, aes(x =df1$CLASS_PEN_BAF_HABS_COAXFO , 
                y = df1$INGRESOPC_ANUAL, color= df1$CLASS_PEN_BAF_HABS_COAXFO)) +
  geom_boxplot() + theme_classic() + theme(legend.title = element_blank())+
  theme(legend.position="none")+
  #scale_x_discrete(name ="Penetración BAF", limits=c("Nula","Baja","Media", "Alta", "Muy Alta"))+
  labs(x = "Penetración BAF" ,y = "Ingreso anual per capita (USD, en ppc)", title = "Relación penetracion e ingreso anual")+
  scale_x_discrete(labels=c("0" = "Nula", "1" = "Baja", "2" = "Media", "3" = "Alta", "4" = "Muy Alta"))





