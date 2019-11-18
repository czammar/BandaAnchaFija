library(readxl)
library(tidyverse)

left_path = "Intercensal2015/14_vivienda_"
right_path = ".xls"
states_list = c("ags","bc","bcs","cam","coah","col","chis","chih","cdmx","dgo","gto","gro","hgo","jal","mex","mich","mor","nay","nl","oax","pue","qro","qroo","slp","sin","son","tab","tamps","tlax","ver"
                ,"yuc","zac")

# Funcion para extraer los datos de indicadores de servicios de telecom en viviendas


cleaning_viv_state<-function(name_state){
  # Carga el archivo con el path descrito
  test <-read_excel(paste0(left_path,name_state,right_path), sheet = "22", col_names = FALSE, col_types = NULL, na = "", skip = 10)
  
  # Nombres temporales de las variables
  colnames(test)<- c("X1","X2","X3","X4","X5","X6","X7","X8")
  
  # Se eliminan renglones con texto que no es de interes
  test[-c(1,2,3,4,5,6,7,8),]
  
  # Filtrado para obtener datos de servicios de telecomunicaciones en municipios
  test <- filter(test, test$X3 == "Teléfono fijo" | test$X3 == "Teléfono celular" | test$X3 == "Internet" | test$X3 == "Servicio de televisión de paga")
  test <- filter(test, test$X2 != "Total" & test$X4 == "Valor")
  
  # seleccion de variables de estado, municipio y poblacion, para renombrarlas
  test<- test %>% select(X1,X2,X3,X6)
  colnames(test)<- c("K_ENTIDAD","K_MUNICIPIO","TIPO_BIEN_O_TECNOLOGIA","DISPONIBILIDAD")
  
  # Obtiene claves de identificacion de estado y municipio
  test$K_ENTIDAD <- substr(test$K_ENTIDAD,1,2)
  test$K_MUNICIPIO<- substr(test$K_MUNICIPIO,1,3)
   
  # Crea nueva variable con clave y
  test <- test %>% mutate(K_ENTIDAD_MUNICIPIO = paste(K_ENTIDAD, K_MUNICIPIO, sep=""))
  test <-test %>% select(K_ENTIDAD_MUNICIPIO, TIPO_BIEN_O_TECNOLOGIA, DISPONIBILIDAD)
  #test <- test %>% select
  return(test)
}

test_vivs = cleaning_viv_state("ags")

for (name_state in states_list ){
  test_vivs <- rbind(test_vivs,cleaning_viv_state(name_state))
  
}

# Elimina duplicados
test_vivs<-unique(test_vivs)
indicadores_servicios2015 <- test_vivs

# Alargamos las columnas para que los indicadores de dispobilidad de servicios de telecomunicaciones queden hacia la derecha
indicadores_servicios2015 <- indicadores_servicios2015 %>% spread(TIPO_BIEN_O_TECNOLOGIA, DISPONIBILIDAD)

# Cambiamos los nombres para que sea mas facil manejarlo
colnames(indicadores_servicios2015) <- c("K_ENTIDAD_MUNICIPIO","DISP_INTERNET", "DISP_TV_PAGA", "DISP_TEL_CELULAR", "DISP_TEL_FIJO")

# Escribe la base de hogares en el municipio
write_csv(indicadores_servicios2015,"indicadores_servicios2015.csv")