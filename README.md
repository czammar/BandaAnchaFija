# Métodos de aprendizaje de maquina para inferir el nivel de cobertura de banda ancha fija en municipios  de México

**César Zamora Martínez**

**16 de diciembre de 2019**

El desarrollo de los servicios de Internet de banda ancha, ha tenido un impacto sin precedentes en los procesos productivos, financieros y en el bienestar de la población. En México, a cerca de cuatro años de la reforma de telecomunicaciones, 2013 - 2017, se estimó un crecimiento superior al 37\% en las conexiones de banda ancha fija (BAF), traduciéndose en que para entonces casi la mitad los hogares contaban con servicios de Internet.

 Sin embargo, la ENDUTIH 2018 dejó en claro la existencia de una brecha en la adopción de estos servicios para la población mexicana y sus beneficios pues:

* **La penetración no es tan honda:** sólo 66\% de la población con seis años o más es usuario de servicios de Internet en los hogares del país,
* **En un fenómeno más urbano que rural:** Cerca de 73\% del total de la población urbana son usuarios de este servicio en contraste con la población conectada en zonas rurales que es cercana a 40.6\%.

Al provenir de un sector que hace inversiones cuantiosas con vista a largo plazo, se sabe que distribución de los accesos [^1] a Internet en una zona obedece a muchos aspectos que no solo son socio-económicos, pues también hay  otros factores que pueden ser tomados en cuentan por un operador para evaluar una zona como idónea para brindar servicios, como: 1) viabilidad de permisos para desarrollar los despliegues, 2) viabilidad tecnológica (e.g. limitadas técnicas por la distancia que limitan la velocidad, calidad, entre otras), 3) existencia de infraestructura cercana a la zona de la que puedan disponer para proveer servicios (por ejemplo, propia o arrendada); y 4) existencia de competencia en el área; es decir de proveedores de servicios de telecomunicaciones.

[^1]: circuitos con los que se puede conectar la ubicación del usuario a la red de un operador y a través de la que se le prestan los servicios.

![Penetración de banda ancha por cada 100 habitantes en Ciudad de México, a Junio 2018](Paper/images/pen_habs_cdmx.png)

La imagen anterior muestra, que en incluso en la zona del Valle de México, existe una disparidad respecto a la cantidad de accesos a Internet por cada 100 habitantes, cuando se consideran tecnologías modernas como la fibra ópticas y el cable coaxial, que son las opciones para brindar servicios de calidad y velocidad alta.

Para cuantificar la cobertura de banda ancha fija la OCDE define una medida de penetración en una zona como la cantidad de accesos en ella por cada 100 habitantes, el cual es un proxy del indicador de suscriptores por cada 100 habitantes (http://www.oecd.org/internet/broadband/broadband-faqs.htm):

$$PenBAFHabitantes = \frac{Accesos }{Habitantes} \times 100 $$


A efecto de explicar el entorno de la penetración de servicios de Internet a nivel municipal, en adelante nos centraremos en los servicios de banda ancha fija, los cuales son servicios de acceso a Internet y transmisión de datos orientados a usuarios finales (personas físicas o empresas), que se brindan a través de equipos terminales (módems, terminales ópticas y demás) que tienen una ubicación geográfica determinada y fija. Ello obliga a los operadores de telecomunicaciones interesados a realizar inversiones que les permitan alcanzar los puntos geográficos en donde se localizan los clientes potenciales, esto es, cerca de hogares y edificios de empresas, aprovechando las capacidades de las tecnologías en las que se basan sus redes.

Dicho contexto les condiciona a establecer un circuito físico o virtual a través del cual se pueda conectar la ubicación del usuario a la red del operador y a través del que se prestarán los servicios (“Acceso de datos” o simplemente como “acceso”). Por ende, dado que afrontan costos considerables en infraestructura, equipos, permisos y recursos humanos para poder brindar servicios\footnote{En línea con \cite{IFT2017reb}, no sólo se enfrentan costos directos, sino oportunidad y de transacción; así como el riesgo de afrontar costos hundidos.}, típicamente los operadores concentran su oferta en zonas densamente pobladas donde existe suficiente capacidad económica para asegurar no solo que recuperarán sus inversiones sino que serán rentables desde la visión de negocio.

Además de los aspectos socio-económicos, también se destacan otros factores que pueden ser tomados en cuentan por un operador para evaluar una zona como idónea para brindar servicios: 1) Viabilidad de permisos para desarrollar los despliegues (e.g. concesiones para operar, medio ambiente), 2) viabilidad tecnológica (e.g. limitadas técnicas por la distancia que limitan la velocidad, calidad, entre otras), 3) existencia de infraestructura cercana a la zona de la que puedan disponer para proveer servicios (por ejemplo, propia o arrendada); y 4) existencia de competencia en el área; es decir de proveedores de servicios de telecomunicaciones.
%

### Objetivo

Explorar métodos de aprendizaje de máquina para inferir el nivel de cobertura de banda ancha fija, de accesos basados en fibra óptica o cable coaxial, a partir de información pública (por ejemplo, indicadores socio-económicos, proxys de indicadores de presencia de infraestructura).


### Consideraciones

* La última versión del escrito denomina "ilcss-wp-example.pdf" y se ubica en la carpeta /Paper,
* El archivo "talk_10122019.pdf", presente en la carpeta /talk, contiene una presentación sobre el contenido del proyecto
* Los mapas interactivos sobre cobertura de banda ancha fija en México se encuentran en la carpeta Mapas; usando información de accesos a mediados de 2019 y habitantes/hogares de la Encuesta Intercensal 2015 de Inegi (última disponible).
* Los archivos de extensión .R y .ipynb contienen las implementaciones para crear la base de datos de BAF y correr los modelos de aprendizaje de máquina descritos en el escrito aludido en el primer punto.

### Especificaciones de las carpetas y programas

El archivo que procesa los fuentes de datos en crudo para la creación de las bases de datos con las que trabaja el pipeline de modelos se denominada **banda_anchafija.R**, el cual manda a llamar diferentes rutinas en R procesan cada una de las bases de la fuentes que se reunieron, a saber:

| # | Archivo | Descripción | Fuente |
|---|----------------------------------------------------|----------------------------------------------------------------------------------------------------------------|--------|
| 1 | creating_baf.R | Accesos de banda ancha fija a junio/2019  | Banco de Información de Telecomunicaciones, IFT |
| 2 | creating_conapo.R | Datos del Indice marginación y porcentaje de población con menos de 2 salarios min, 2015  | CONAPO |
| 3 | creating_inafed.R | Superficie de municipios en kilómetros cuadrados  | INAFED |
| 4 | creating_indicadores_serviciostelecom_viviendas_.R | Indicadores de disponiblidad de servicios de telecomunicaciones tv de paga, internet, telefonía fija y celular | Encuesta intercensal 2015, INEGI |
| 5 | creating_hogares.R | Hogares por municipios  | Encuesta intercensal 2015, INEGI |
| 6 | creating_poblacion.R | Población por municipios  |Encuesta intercensal 2015, INEGI  |
| 7 | creating_humandevelop_index.R | Datos datos del Indice de desarollo humano 2015 | programa de las Naciones Unidas para el Desarrollo (PNUD) |
