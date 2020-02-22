# Métodos de aprendizaje de maquina para inferir el nivel de cobertura de banda ancha fija en municipios  de México

**César Zamora Martínez**

**16 de diciembre de 2019**

### 0. La penetración de servicios de Internet de banda ancha

El desarrollo de los servicios de Internet de banda ancha, ha tenido un impacto sin precedentes en los procesos productivos, financieros y en el bienestar de la población. En México, a cerca de cuatro años de la reforma de telecomunicaciones, 2013 - 2017, se estimó un crecimiento superior al 37\% en las conexiones de banda ancha fija (BAF), traduciéndose en que para entonces casi la mitad los hogares contaban con servicios de Internet.

 Sin embargo, la ENDUTIH 2018 dejó en claro la existencia de una brecha en la adopción de estos servicios para la población mexicana y sus beneficios pues:

* **La penetración no es tan honda:** sólo 66\% de la población con seis años o más es usuario de servicios de Internet en los hogares del país,
* **En un fenómeno más urbano que rural:** Cerca de 73\% del total de la población urbana son usuarios de este servicio en contraste con la población conectada en zonas rurales que es cercana a 40.6\%.

Al provenir de un sector que hace inversiones cuantiosas con vista a largo plazo, se sabe que distribución de los accesos [^1] a Internet en una zona obedece a muchos aspectos que no solo son socio-económicos, pues también hay  otros factores que pueden ser tomados en cuentan por un operador para evaluar una zona como idónea para brindar servicios, como: 1) viabilidad de permisos para desarrollar los despliegues, 2) viabilidad tecnológica (e.g. limitadas técnicas por la distancia que limitan la velocidad, calidad, entre otras), 3) existencia de infraestructura cercana a la zona de la que puedan disponer para proveer servicios (por ejemplo, propia o arrendada); y 4) existencia de competencia en el área; es decir de proveedores de servicios de telecomunicaciones.

[^1]: circuitos con los que se puede conectar la ubicación del usuario a la red de un operador y a través de la que se le prestan los servicios.

![Penetración de banda ancha por cada 100 habitantes en Ciudad de México, a Junio 2018](Paper/images/pen_habs_cdmx.png)

De hecho, para cuantificar la cobertura de banda ancha fija la OCDE define una medida de penetración en una zona como la cantidad de accesos en ella por cada 100 habitantes, el cual es un proxy del indicador de suscriptores por cada 100 habitantes (http://www.oecd.org/internet/broadband/broadband-faqs.htm):

Empleando este indicador, la imagen previa muestra, que incluso en la zona del Valle de México, existe una disparidad respecto a la cantidad de accesos a Internet por cada 100 habitantes, cuando se consideran tecnologías modernas como la fibra ópticas y el cable coaxial, que son las opciones para brindar servicios de calidad y velocidad alta. Las zonas azules muestran una penetración comparable con los países con penetración de banda ancha más alta de la OCDE [^2], mientras que los naranjas y rojos corresponden, respectivamente a sus últimos lugares o sin accesos de tales tecnologías.

[^2]: A saber Suiza, Dinamarca, Francia y Paises Bajos; considerando cualquier tecnología de banda ancha desplegada en tales países, no sólo fibra y cable coaxial como en el mapa, lo cual es impresionante!!!

### 1. La importancia de medir la penetración y el problema de la información

Diversas asociaciones, entre gobiernos, empresas e instuciones edicativas han tomado posturas activas para aumentar la penetración de servicios de Internet en ciertas zonas, de manera que pueda exisitir una derrama de los beneficios de la conectividad.

Algunas de ella son el diseño, por parte de gobiernos y agencias nacionales de regulación, de planes nacionales de banda ancha, o programas de acceso universal a banda ancha (como el diseñado por la CNMC de España, que funge como el regulador de telecomunicaciones de tal país).

Sin embargo, para llevar a cabo acciones de esta magnitud se necesitan datos y herramientas con las que se pueda cuantificar la penetración de servicios de Internet en una zona, ya que, como se comprenderá de la imagen previa, lugares con diferentes niveles de penetración de servicios se encuentran en contextos diferentes que seguramente requerirán acciones particulares y concretas para aumentar la penetración en ellas.

Desafortunadamente, la información necesaria para este fin puede no estar disponible, ya sea por falta de un marco regulatorio que obligue a los operadores a proporcionarla, por el volumen del mercado, en términos de la cantidad de operadores, redes y usuarios de un pais o simplemente porque nadie se ha preocupado por reunirla en un periodo de tiempo relevante[3^].

[3^]: Por ejemplo, en México la información relevante de los sectores de telecomunicaciones se reunia de forma no sistemática en la COFETEL, y se empezó a publicar a partir de 2017 por el IFT (con datos históricos a partir de 2013).

Es por ello que una pregunta de interés es si el nivel de penetración para servicios de banda ancha fija de una zona (por ejemplo a nivel municipal), se podrá determinar con otras fuentes de información que noe¡s permitan inferirla y, presumiblemente, entender esta variable en función de información relacionada a ella.

### 2. Objetivo

Es asi que, a efecto de explicar el entorno de la penetración de servicios de Internet a nivel municipal, en adelante nos centraremos en los servicios de banda ancha fija, con el propósito de explorar métodos de aprendizaje de máquina para inferir el nivel de cobertura de banda ancha fija, de accesos basados en fibra óptica o cable coaxial, a partir de información pública, intentando capturar establecer factores que propician o desincentivan los despliegues de banda ancha fija.

### 3. Ideas generales

* Reunir información de indicadores socio-económicos, proxys de indicadores de presencia de infraestructura [4^] para relacionarlos con la penetración de banda ancha de los municipios,
* Considerar penetración de tecnologías de acceso a Internet fijo que soporten altas velocidades (fibra óptica y cable coaxial),
* Dividir los municipios conforme a rangos de penetración (niveles) definidos de acuerdo al nivel medio de la penetración de países de la OCDE.
* Usar algoritmos de aprendizaje que puedan dar no solo resultados certeros, sino que tengan algún grado de interpretabilidad,
* Explorar sus resultados para evaluar si podrían calibrarse como un proxy para predecir el nivel de penetración en una zona.

[4^]: Sorpresivamente, en México no existe información pública sobre la presencia de infraestructura de telecomunicaciones, aunque si hay esfuerzos para proveer información aproximada (ver ![R.Escobar](http://www.revistas-conacyt.unam.mx/trimestre/index.php/te/article/view/537/1039)).

#### 4. Consideraciones

Todo el trabajo anterior, se encuentra documentado en el presente repositorio, a través de:

*  **Última versión de documento metodológico** denominado "ilcss-wp-example.pdf" y se ubica en la carpeta /Paper,
* **Presentación ejecutiva:** El archivo "talk_10122019.pdf", presente en la carpeta /talk, contiene una presentación sobre el contenido del proyecto
* **Datos y su extracción:** La carpeta */datos* contiene los scripts de extracción en Bash, o bien los archivos descargados manualmente a través de las páginas de los organismos consultados.
* **Datos y transformación:** El archivo *createdb_fixedbroadband.R* contiene la tranformación y limpieza hecha a los datos de las diferentes fuentes. Como resultado crea diferentes archivos .csv presentes en la ruta */datos/processed*
* **Análisis exploratorio y mapas interactivos:** El anáisis exploratorio se encuentra en el documento *EDA_graphs.R* Los mapas interactivos sobre cobertura de banda ancha fija en México se encuentran en la carpeta Mapas; usando información de accesos a mediados de 2019 y habitantes/hogares de la Encuesta Intercensal 2015 de Inegi (última disponible).
* *Modelado y evaluación* el archivo .ipynb presente en la raiz contiene las implementaciones para correr los modelos de aprendizaje de máquina descritos en el escrito aludido en el primer punto.

### 5. Fuentes de datos

| # | Descripción | Fuente |
|---|----------------------------------------------------------------------------------------------------------------|--------|
| 1 | Accesos de banda ancha fija a junio/2019  | Banco de Información de Telecomunicaciones, IFT |
| 2 | Datos del Indice marginación y porcentaje de población con menos de 2 salarios min, 2015  | CONAPO |
| 3 |  Superficie de municipios en kilómetros cuadrados  | INAFED |
| 4 |  Indicadores de disponiblidad de servicios de telecomunicaciones tv de paga, internet, telefonía fija y celular | Encuesta intercensal 2015, INEGI |
| 5 |  Hogares por municipios  | Encuesta intercensal 2015, INEGI |
| 6 |  Población por municipios  |Encuesta intercensal 2015, INEGI  |
| 7 |  Datos datos del Indice de desarollo humano 2015 | programa de las Naciones Unidas para el Desarrollo (PNUD) |
