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


# Cargamos la base global

df_EDA <- read_csv("/media/Box/Aprendizaje_Maquina/Projecto/BAF_06209_EDA.csv", 
                          col_types = cols(CLASS_PEN_BAF_HABS_COAXFO = col_character(), 
                                           CLASS_PEN_BAF_HOGS_COAXFO = col_character(), 
                                           IS_PEN_BAF_HABS_COAXFO = col_character(), 
                                           NUM_OPS = col_character(), REG_SOCIOECONOM = col_character()))


# Distribucion poblacion y hogares

df_EDA %>% select(CLASS_PEN_BAF_HABS_COAXFO,POBLACION) %>%
  group_by(CLASS_PEN_BAF_HABS_COAXFO) %>%  summarize(Porcentaje_Pob = count(CLASS_PEN_BAF_HABS_COAXFO))

table(df_EDA$CLASS_PEN_BAF_HABS_COAXFO)


df_EDA %>% select(CLASS_PEN_BAF_HABS_COAXFO,POBLACION) %>%
  group_by(CLASS_PEN_BAF_HABS_COAXFO) %>%  summarize(Porcentaje_Pob = sum(POBLACION))%>% 
  ungroup() %>% mutate(p_pob = Porcentaje_Pob/ sum(Porcentaje_Pob)*100 )

df_EDA %>% select(CLASS_PEN_BAF_HABS_COAXFO,HOGARES) %>%
  group_by(CLASS_PEN_BAF_HABS_COAXFO) %>%  summarize(Porcentaje_Hogares = sum(HOGARES))%>% 
  ungroup() %>% mutate(p_hogs = Porcentaje_Hogares/ sum(Porcentaje_Hogares)*100 )

# Penetracion por densidad de hogares

ggplot(df_EDA, aes(x=df_EDA$PEN_BAF_HABS_COAXFO, y=df_EDA$DENS_HABS,color=CLASS_PEN_BAF_HABS_COAXFO,shape=CLASS_PEN_BAF_HABS_COAXFO)) +
  geom_point() + 
  geom_smooth(method=lm)+ theme_classic() + theme(legend.title = element_blank())+
  labs(x = "Penetración BAF" ,y = "Densidad Habitantes/KM^2", title = "Relación penetracion y densidad de habitantes")+
  ylim(0,1000000)

ggplot(df_EDA, aes(x =df_EDA$CLASS_PEN_BAF_HABS_COAXFO , 
                y = df_EDA$DENS_HABS, color= df_EDA$CLASS_PEN_BAF_HABS_COAXFO)) +
  geom_boxplot() + theme_classic() + theme(legend.title = element_blank())+
  theme(legend.position="none")+
  #scale_x_discrete(name ="Penetración BAF", limits=c("Nula","Baja","Media", "Alta", "Muy Alta"))+
  labs(x = "Penetración BAF" ,y = "Densidad de Habitantes/KM^2", title = "Relación entre densidad de habitantes y \n penetración")+
  scale_x_discrete(labels=c("0" = "Nula", "1" = "Baja", "2" = "Media", "3" = "Alta", "4" = "Muy Alta"))+coord_flip() 


# Penetracion vs Ingreso

ggplot(df1, aes(x =df1$CLASS_PEN_BAF_HABS_COAXFO , 
                y = df1$INGRESOPC_ANUAL, color= df1$CLASS_PEN_BAF_HABS_COAXFO)) +
  geom_boxplot() + theme_classic() + theme(legend.title = element_blank())+
  theme(legend.position="none")+
  #scale_x_discrete(name ="Penetración BAF", limits=c("Nula","Baja","Media", "Alta", "Muy Alta"))+
  labs(x = "Penetración BAF" ,y = "Ingreso anual per capita (USD, en ppc)", title = "Relación penetracion e ingreso anual")+
  scale_x_discrete(labels=c("0" = "Nula", "1" = "Baja", "2" = "Media", "3" = "Alta", "4" = "Muy Alta"))

ggplot(df_EDA, aes(PO2SM, colour = CLASS_PEN_BAF_HABS_COAXFO)) + theme_classic() +theme(legend.title = element_blank())+
  labs(x = "% poblacion en municipios con ingreso \n de hasta 2 salarios mínimos en 2015",
       title = "Relación penetracion y salarios minimos")+
  geom_density(alpha = 0.9)


# Densidad acumulada de penetacion

library(ggpubr)
  ggplot(df_EDA, aes(x =df_EDA$PEN_BAF_HABS_COAXFO)) + stat_ecdf(geom = "step", size = 0.8, color = 'red') + 
    theme_pubclean()+ theme(legend.title = element_blank())+
    theme(legend.position="none")+  labs(x = "Accesos de BAF por cada 100 habitantes",y ="Porcentaje de municipios" , title = "Densidad acumulada de municipios \n según penetración de BAF")
  



