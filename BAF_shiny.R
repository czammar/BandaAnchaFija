library(shiny)
library(plotly)
library(ggplot2)
library(dplyr)
library(tidyverse)

# Para ejectuar este archivo, por favor situarse en la ruta donde esta el archivo csv con los datos
# Cargamos los datos limpios
df <- read_csv("BAF_06209_selected.csv")
df$PEN_CLASS <- as.character(df$PEN_CLASS)

# Especificaciones de tema grafico para ggplot
.theme<- theme(
  axis.line = element_line(colour = 'gray', size = .95),
  panel.background = element_blank(),
  plot.background = element_blank()
)

# nombres de variables categoricas
categorical_names <- c("PEN_CLASS")


######----- Diseno de la interfaz de usuario -----#####

ui<-fluidPage(
  # Application title
  titlePanel("Analisis Exploratorio de Banda Ancha fija"),
  
  # Creamos el titulo del panel
  headerPanel("Opciones de graficos"),
  
  #Especificaciones de panel lateral izquierdo
  sidebarPanel
  ( # Seleccion de inputs para el analisis: variables y tipo de grafico a desplegar
    selectInput("dataset","Datos:", choices =list(BAF062016 = "df"), selected=NULL), # Datos en que se basa el analisis
    selectInput("variable1","Variable 1:", names(df)), # Campo para seleccionar variable 1 a cruzar
    selectInput("variable2","Variable 2", names(df)), # Campo para seleccionar variable 2 a cruzar
    selectInput("variable3","Variable 3 (para desagregación por grupos)", choices = NULL), # Campo para seleccionar variable 3 a cruzar de manera que se desagreguen los plots con ella 
    selectInput("plot.type","Tipo de grafico:", # Tipos de gráficas que permitirá definir el dashboard
                list(boxplot = "boxplot", 
                     histograma = "histogram", 
                     densidad = "density", 
                     barras = "bar", 
                     scatterplot = "scatterplot")
    ),
    checkboxInput("show.points", "Agregar puntos con Jitter", TRUE) # Campo para decidir si agregan a los boxplots los puntos con algun jitter
  ),
  
  # Llamaos a los graficos al panel del dashboard
  mainPanel(
    plotOutput("distPlot"), # Dasboard bivariado
    plotOutput("p"), # Dasboard bivariado
    plotOutput("q") # Dashboard multivariado
  )
)


##### ----- Diseno del servidor para montar el dashboard ----- ######

server<-(function(input, output, session){
  
  #Actualizacion de las variables elegidas por el usuario en el panel lateral izquierdo
  observe({
    if(!exists(input$dataset)) return() # Revisamos que si se hallan cargado los datos
    var.opts<-colnames(get(input$dataset))
    updateSelectInput(session, "variable1", choices = var.opts) # usuario variable 1 - de entre todas las variables de la base
    updateSelectInput(session, "variable2", choices = var.opts) # usuario variable 2 - de entre todas las variables de la base
    
    # usuario elige unicamente entre las variables categoricas para desglosar los graficos con face_wrap
    updateSelectInput(session, "variable3", choices = c("PEN_CLASS")
    )
  })
  
  # Campo para mostar etiquetas del tipo de plot mostrado en funcion de grafica seleccionada en el panel
  output$caption<-renderText({
    switch(input$plot.type,
           "boxplot" 	= 	"Grafica de cajas",
           "histogram" =	"Histograma",
           "density" 	=	"Densidad",
           "bar" 		=	"Grafica de Barras",
           "scatterplot" = "Scatterplot")
  })
  
  
  #get data object
  get_data<-reactive({
    
    if(!exists(input$dataset)) return() # if no upload
    
    check<-function(x){is.null(x) || x==""}
    if(check(input$dataset)) return()
    
    obj<-list(data=get(input$dataset),
              variable1=input$variable1,
              variable2=input$variable2,
              variable3=input$variable3
    )
    
    #require all to be set to proceed
    if(any(sapply(obj,check))) return()
    #make sure choices had a chance to update
    check<-function(obj){
      !all(c(obj$variable1,obj$variable2,obj$variable3) %in% colnames(obj$data))
    }
    
    if(check(obj)) return()
    
    return(obj)
    
  })
  
  
  ######-----  Univariado  -----######
  output$distPlot <- renderPlot({
    plot.obj<-get_data()
    
    # revisamos que se hayan agregado los datos especificados para hacer las graficas, sino paramos
    if(is.null(plot.obj)) return()
    
    # verificamos que el usuario ha establecido la variable a cruzar
    if(plot.obj$variable1 == "") return()
    
    if(!plot.obj$variable1 %in% categorical_names){
      p<- ggplot(plot.obj$data, aes_string(plot.obj$variable1))+ geom_histogram(colour="black", fill="white") #geom_histogram(aes(y=..density..), colour="black", fill="white") #+ geom_density(alpha=.2, fill="#FF6666") 
      p<-p+labs(
        x 		= input$variable1,
        title = "Univariado: variable 1"
      )
      p
      
    }
    else{
      p<- ggplot(plot.obj$data, aes_string(plot.obj$variable1, fill=plot.obj$variable1))+ geom_bar()
      p<- p + theme(axis.text.x = element_text(angle = 60, hjust = 1))
      p<-p+labs(
        #   #fill 	= as.factor(input$variable1),
        x 		= input$variable1,
        title = "Univariado: variable 1"
      )
      p
    }
  })
  
  ######-----  Bivariado  -----######
  output$p <- renderPlot({  
    plot.obj<-get_data()
    
    # revisamos que se hayan agregado los datos especificados para hacer las graficas, sino paramos
    if(is.null(plot.obj)) return()
    
    # verificamos que el usuario ha establecido las variables a cruzar
    if(plot.obj$variable1 == "" | plot.obj$variable2 =="") return()
    
    # Variable para indicarle a ggplot el tipo de grafico que ha selecionado el usuario
    plot.type<-switch(input$plot.type,
                      "boxplot" 	= geom_boxplot(),
                      "histogram" =	geom_histogram(alpha=0.65,position="identity"),
                      "density" 	=	geom_density(alpha=.75),
                      "bar" 		=	geom_bar(position="dodge"),
                      "scatterplot" =	geom_point()
    )
    
    # Boxplots
    # Nota: si el usuario marca la casilla de añadir jitter se muestran los puntos con ruido para evitar overplotting
    if(input$plot.type=="boxplot")	{
      p<-ggplot(plot.obj$data,
                aes_string(
                  x 		= plot.obj$variable2,
                  y 		= plot.obj$variable1,
                  fill 	= plot.obj$variable2 # llenamos grafica con variable 2
                )
      ) + plot.type
      
      if(input$show.points==TRUE) # agregamos ruido si el usuario marco la casilla correspondiente
      {
        p<-p+ geom_point(color='black',alpha=0.35, position = 'jitter')
      }
      
    } else {
      # Scatterplots
      if(input$plot.type=="scatterplot")	{
        p<-ggplot(plot.obj$data,
                  aes_string(
                    x 		= plot.obj$variable2,
                    y 		= plot.obj$variable1,
                    fill 	= plot.obj$variable2
                  )
        ) + plot.type + geom_smooth(method = "lm") # agrega linea de tendencia con suavizado
        
      }else{
        # Sintaxis para generar el resto de plots
        p<-ggplot(plot.obj$data,
                  aes_string(
                    x 		= plot.obj$variable1,
                    fill 	= plot.obj$variable2,
                    group 	= plot.obj$variable2
                  )
        ) + plot.type
      }
    }
    
    # Se agregan descripciones de los ejes y codigo de colores
    p<-p+labs(
      fill 	= input$variable2,
      x 		= input$variable2,
      y 		= input$variable1,
      title = "Bivariado: variables 1 y 2"
    )  +
      .theme # agrega tema personalizado de ggplot
    print(p)
  })
  
  ######----- Multivariado ----- #####
  output$q <- renderPlot({  
    plot.obj<-get_data()
    
    # revisamos que se hayan agregado los datos especificados para hacer las graficas, sino paramos
    if(is.null(plot.obj)) return()
    
    # verificamos que el usuario ha establecido las variables a cruzar
    if(plot.obj$variable1 == "" | plot.obj$variable2 ==""| plot.obj$variable3 =="") return()
    
    # Variable para indicarle a ggplot el tipo de grafico que ha selecionado el usuario
    plot.type<-switch(input$plot.type,
                      "boxplot" 	= geom_boxplot(),
                      "histogram" =	geom_histogram(alpha=0.45,position="identity"),
                      "density" 	=	geom_density(alpha=.75),
                      "bar" 		=	geom_bar(position="dodge"),
                      "scatterplot" =	geom_point()
    )
    
    # Boxplots
    # Nota: si el usuario marca la casilla de añadir jitter se muestran los puntos con ruido para evitar overplotting
    if(input$plot.type=="boxplot")	{
      p<-ggplot(plot.obj$data,
                aes_string(
                  x 		= plot.obj$variable2,
                  y 		= plot.obj$variable1,
                  fill 	= plot.obj$variable2 # Llenamos con la segunda variable
                )
      ) + plot.type + facet_wrap(~plot.obj$variable3) # se hace un face_wrat con la variable 3 seleccionada
      
      if(input$show.points==TRUE)
      {
        p<-p+ geom_point(color='black',alpha=0.5, position = 'jitter')     # Nota: si el usuario marca la casilla de añadir jitter se muestran los puntos con ruido para evitar overplotting
        
      }
      
    } else {
      # Scatterplot
      if(input$plot.type=="scatterplot")	{
        p<-ggplot(plot.obj$data,
                  aes_string(
                    x 		= plot.obj$variable2,
                    y 		= plot.obj$variable1,
                    fill 	= plot.obj$variable2 # llenamos con la segunda variables
                  )
        ) + plot.type + geom_smooth(method = "lm") + facet_wrap( ~ get(plot.obj$variable3), ncol=3) # se hace un face_wrat con la variable 3 seleccionada
        
      }else{
        
        p<-ggplot(plot.obj$data,
                  aes_string(
                    x 		= plot.obj$variable1,
                    fill 	= plot.obj$variable2,
                    group 	= plot.obj$variable2
                  )
        ) + plot.type + facet_wrap( ~ get(plot.obj$variable3), ncol=3) # se hace un face_wrat con la variable 3 seleccionada
      }
    }
    
    # Se agregan descripciones de los ejes y codigo de colores
    p<-p+labs(
      fill 	= input$variable2,
      x 		= input$variable2,
      y 		= input$variable1,
      title = "Multivariado: variables 1 y 2, desagrupadas por variable 3"
    )  
    print(p)
  })
  
  
})


# Corremos la aplicacion con la interfaz de usuario y el servidor descrito previamente
shinyApp(ui = ui, server = server)