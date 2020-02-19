
********************************************************************************             
*																			   *
*                Cálculo del Índice de Desarrollo Humano Municipal             *
*                                2010 y 2015                                   *
*																			   *
********************************************************************************


********************************************************************************             
*                Cálculo del componente de Ingreso 2010 y 2015                 *
*                                                                              * 
********************************************************************************

**Paso previo: acomodo de las bases de datos

cd "G:\PNUD\Generación del IDHM 2015\Índice de Ingreso"
import excel "ICTP 2010.xlsx", sheet("Hoja1") firstrow
generate clave=Clavedemunicipio
destring clave, replace
generate estado=Clavedeentidad
destring estado, replace
rename ICTPC ICTPC2010
rename Municipio municipio
drop Clavedeentidad Clavedemunicipio
save "Base del ICTPC2010.dta"
clear 

import excel "ICTP 2015.xlsx", sheet("Hoja1") firstrow
generate clave=Clavedemunicipio
destring clave, replace
generate estado=Clavedeentidad
destring estado, replace
rename ICTPC ICTPC2015
rename Municipio municipio
drop Clavedeentidad Clavedemunicipio
save "Base del ICTPC2015.dta"
clear 

import excel "Población CONEVAL.xlsx", sheet("Hoja1") firstrow
generate clave=Clavedemunicipio
destring clave, replace
generate estado=Clavedeentidad
destring estado, replace
rename Municipio municipio
drop Clavedeentidad Clavedemunicipio
egen pob15=sieve(Población2015), keep(n)
destring pob15, replace
rename Población2010 pob10
drop Población2015
save "Población CONEVAL 2010 y 2015.dta"

use "Base del ICTPC2010.dta"
merge 1:1 clave using "Base del ICTPC2015.dta", generate(_merge1)
merge 1:1 clave using "Población CONEVAL 2010 y 2015.dta", generate(_merge2)
save "Base para el cálculo del Índice de Ingreso 2010 y 2015.dta"

**Pasos sustantivos para la creación del Índice de Ingreso

cd "G:\PNUD\Generación del IDHM 2015\Índice de Ingreso"
use "Base para el cálculo del Índice de Ingreso 2010 y 2015.dta"

**Paso 1. Cambio del ICTPC  a precios de diciembre de 2015 (INPC NOV2010=99.250; INPC NOV2015=118.051; INPC DIC2015=118.532)
generate ICTP2010_15=ICTPC2010*(118.532/99.250)
generate ICTP2015_15=ICTPC2015*(118.532/118.051)

**Paso 2. Generación del ICTPC anual
generate ICTPC2010_a=ICTP2010_15*12
generate ICTPC2015_a=ICTP2015_15*12

**Paso 3. Generación del factor de ajuste utilizando el Ingreso Nacional Bruto (INB) 
generate PICTPC2010=ICTPC2010_a*pob10
generate PICTPC2015=ICTPC2015_a*pob15
format %20.0g PICTPC2010
format %20.0g PICTPC2015
tabstat PICTPC2010 PICTPC2015 , statistics( sum ) format(%20.0f)
egen double ICTPC2010_TOTAL=total(PICTPC2010)
egen double  ICTPC2015_TOTAL=total(PICTPC2015)

*Actualización del INB de 2010 [13207409.731*(118.532/99.742)]=15,695,501.2957
*Factor de ajuste en 2010=(15,695,501.2957*1,000,000)/4,490,668,602,668=3.495136846
*Factor de ajuste en 2015=(18,097,999.4780*1,000,000)/4,578,424,998,864=3.9528876
 
generate FACTOR2010_INB=((15695501.2957*1000000)/ICTPC2010_TOTAL)
generate FACTOR2015_INB=((18097999.4780*1000000)/ICTPC2015_TOTAL)

**Paso 4. Multiplicar el ICTPC anual, a precios de diciembre de 2015 por el factor de ajuste
generate ICTPC_ajustado10=ICTPC2010_a*FACTOR2010_INB
generate ICTPC_ajustado15=ICTPC2015_a*FACTOR2015_INB

**Paso 5. Dividir el ICTPC ajustado entre el Factor de conversión de PPA (para 2015), PIB (UMN por $ a precios internacionales) https://datos.bancomundial.org/indicador/PA.NUS.PPP?locations=MX

generate ING_PPC10=ICTPC_ajustado10/8.5411
generate ING_PPC15=ICTPC_ajustado15/8.5411

**Paso 6. Crear el Índice de Ingreso del IDHM
generate II_2010=(ln(ING_PPC10)-ln(100))/(ln(75000)-ln(100))
generate II_2015=(ln(ING_PPC15)-ln(100))/(ln(75000)-ln(100))

save "Base para el cálculo del Índice de Ingreso 2010 y 2015.dta", replace
clear


********************************************************************************             
*                Cálculo del componente de salud 2010 y 2015                   *
*                                                                              * 
********************************************************************************


**Paso previo: acomodo de las bases de datos

cd "G:\PNUD\Generación del IDHM 2015\Índice de Salud"
import excel "Tasas de mortalidad infantil del CONAPO 20180515.xlsx", sheet("Hoja1") firstrow
generate estado=Claveentidad
generate municipio=Clavemunicipio
generate clave=(estado*1000)+municipio

save "Base para el cálculo del Índice de Salud municipal.dta", replace

**Pasos sustantivos para la creación del Índice de Salud

**Paso 1. Cálculo del Índice de Salud Nacional con base en los referentes internacionales del Reporte Global del IDH 2016
generate IS_N=(77-20)/(85-20)

**Paso 2. Crear la variable de población para cada año
egen pob_nac_2010=sum(población_2010)
egen pob_nac_2015=sum(población_2015)
format %20.0g pob_nac_2010
format %20.0g pob_nac_2015

**Paso 3. Calcular el máximo a partir de la Tasa de mortalidad infantil de referencia más baja (1.7 para Islandia), en términos de Supervivencia infantil
generate max=1-(1.7/1000)

**Paso 4. Expresar la Tasa de mortalidad infantil municipal, en términos de Supervivencia infantil
generate  SI_2010=1-(TMI2010/1000)
generate  SI_2015=1-(TMI2015/1000)

egen SI_N2010=sum(SI_2010*(población_2010/pob_nac_2010))
egen SI_N2015=sum(SI_2015*(población_2015/pob_nac_2015))

**Paso 5. Calcular el valor mínimo a partir del despeje de la fórmula
generate min_2010=(SI_N2010-(IS_N*max))/(1-IS_N)
generate min_2015=(SI_N2015-(IS_N*max))/(1-IS_N)

**Paso 6. Calcular el Índice de Salud
generate IS_2015=(SI_2015-min_2015)/(max-min_2015)
generate IS_2010=(SI_2010-min_2015)/(max-min_2015)

save "Base para el cálculo del Índice de Salud municipal.dta", replace
clear

********************************************************************************             
*                Cálculo del componente de educación 2010 y 2015               *
*                                                                              * 
********************************************************************************


**//Cálculo del Índice de Educación para el IDH Municipal en 2015 y 2010//**

**Paso previo: acomodo de las bases, de cada entidad federativa, de la Encuesta Intercensal 2015 y del Censo 2010
**Las bases de datos del Censo 2010 están en la sección de microdatos: https://www.inegi.org.mx/programas/ccpv/2010/**
**Las bases de datos de la Encuesta Intercensal 2015 están están en la sección de microdatos: https://www.inegi.org.mx/programas/intercensal/2015/default.html**
**Para 2010 y 2015, el INEGI tiene las bases separadas por entidad federativa, por lo que primero hay que descargarlas, en este caso, en formato Stata y luego pegarlas, conforme al paso que se describe enseguida.
**En el paso  siguiente, se pegan las bases en un sólo archivo y sólo se mantienen las variables necesarias para la construcción del Índice de Educación**

//Paso previo: Generación de una base para 2010 y otra correspondiente a 2015, a partir de las bases del INEGI de cada entidad federativa//

**Encuesta Intercensal**
cd "G:\PNUD\Generación del IDHM 2015\Índice de Educación\Encuesta Intercensal\Stata"
local BASES_EI : dir . files "*persona*"
foreach file of local BASES_EI {
    use `"`file'"' , clear
    keep ID_VIV ID_PERSONA ENT NOM_ENT MUN NOM_MUN FACTOR ESTRATO UPM SEXO EDAD ASISTEN ESCOLARI NIVACAD ALFABET ESCOACUM
    gettoken filename : file , parse(".")
    save `"`filename'_reduced.dta"'
}
****
local basecompleta : dir . files "*reduced.dta" , respectcase
gettoken firstfile basecompleta : basecompleta
use `"`firstfile'"' , clear
quietly append using `basecompleta'
save "Base Completa Intercensal 2015.dta"

**Censo 2010**
cd "G:\PNUD\Generación del IDHM 2015\Índice de Educación\Censo\Stata"
local BASES_EI : dir . files "personas*"
foreach file of local BASES_EI {
    use `"`file'"' , clear
    keep ID_VIV ID_PER ENT NOM_ENT MUN NOM_MUN FACTOR ESTRATO UPM SEXO EDAD ASISTEN ESCOLARI NIVACAD ALFABET ESCOACUM
    gettoken filename : file , parse(".")
    save `"`filename'_reduced.dta"'
}
****
local basecompleta : dir . files "*reduced.dta" , respectcase
gettoken firstfile basecompleta : basecompleta
use `"`firstfile'"' , clear
quietly append using `basecompleta'
save "Base Completa Muestra Censal 2010.dta"


********************************************************************************             
*                            Encuesta Intercensal 2015                         *
*                                                                              * 
********************************************************************************
cd "G:\PNUD\Generación del IDHM 2015\Índice de Educación\Encuesta Intercensal\Stata"
use "Base Completa Intercensal 2015.dta"

**Paso 1. Generación de nuevas variables, previo a la recodificación
generate ASISTEN_R=ASISTEN
generate ESCOLARI_R=ESCOLARI
generate NIVACAD_R=NIVACAD
generate ESCOACUM_R=ESCOACUM
   
**Paso 2. Recodificación de los años de escolaridad
generate años=.					
replace años=	0	if NIVACAD_R==	0		
replace años=	0	if NIVACAD_R==	1		
replace años=	1	if NIVACAD_R==	2	 & ESCOLARI_R==	1
replace años=	2	if NIVACAD_R==	2	 & ESCOLARI_R==	2
replace años=	3	if NIVACAD_R==	2	 & ESCOLARI_R==	3
replace años=	4	if NIVACAD_R==	2	 & ESCOLARI_R==	4
replace años=	5	if NIVACAD_R==	2	 & ESCOLARI_R==	5
replace años=	6	if NIVACAD_R==	2	 & (ESCOLARI_R>5)	  & (ESCOLARI_R<99)
replace años=	7	if NIVACAD_R==	3	 & ESCOLARI_R==	1
replace años=	8	if NIVACAD_R==	3	 & ESCOLARI_R==	2
replace años=	9	if NIVACAD_R==	3	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)
replace años=	10	if NIVACAD_R==	4	 & ESCOLARI_R==	1
replace años=	11	if NIVACAD_R==	4	 & ESCOLARI_R==	2
replace años=	12	if NIVACAD_R==	4	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)
replace años=	10	if NIVACAD_R==	5	 & ESCOLARI_R==	1
replace años=	11	if NIVACAD_R==	5	 & ESCOLARI_R==	2
replace años=	12	if NIVACAD_R==	5	 & ESCOLARI_R==	3
replace años=	13	if NIVACAD_R==	5	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace años=	6	if NIVACAD_R==	6		
replace años=	10	if NIVACAD_R==	7	 & ESCOLARI_R==	1
replace años=	11	if NIVACAD_R==	7	 & ESCOLARI_R==	2
replace años=	12	if NIVACAD_R==	7	 & ESCOLARI_R==	3
replace años=	13	if NIVACAD_R==	7	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace años=	13	if NIVACAD_R==	8	 & ESCOLARI_R==	1
replace años=	14	if NIVACAD_R==	8	 & ESCOLARI_R==	2
replace años=	15	if NIVACAD_R==	8	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)
replace años=	10	if NIVACAD_R==	9	 & ESCOLARI_R==	1
replace años=	11	if NIVACAD_R==	9	 & ESCOLARI_R==	2
replace años=	12	if NIVACAD_R==	9	 & ESCOLARI_R==	3
replace años=	13	if NIVACAD_R==	9	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace años=	13	if NIVACAD_R==	10	 & ESCOLARI_R==	1
replace años=	14	if NIVACAD_R==	10	 & ESCOLARI_R==	2
replace años=	15	if NIVACAD_R==	10	 & ESCOLARI_R==	3
replace años=	16	if NIVACAD_R==	10	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace años=	13	if NIVACAD_R==	11	 & ESCOLARI_R==	1
replace años=	14	if NIVACAD_R==	11	 & ESCOLARI_R==	2
replace años=	15	if NIVACAD_R==	11	 & ESCOLARI_R==	3
replace años=	16	if NIVACAD_R==	11	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace años=	17	if NIVACAD_R==	12	& ESCOLARI_R<99	
replace años=	17	if NIVACAD_R==	13	 & ESCOLARI_R==	1
replace años=	18	if NIVACAD_R==	13	 & (ESCOLARI_R>1)	  & (ESCOLARI_R<99)
replace años=	18	if NIVACAD_R==	14	& ESCOLARI_R<99	
replace años=99 if ESCOACUM==99

**Paso 3. Creación de identificadores únicos

generate estado=ENT
generate municipio=MUN
destring estado municipio, replace
generate clave=(estado*1000)+municipio

**Paso 4. Creación del Índice de Educación

**Paso 4a. Creación de los años promedio de escolaridad
generate edad_m=EDAD
replace edad_m=. if EDAD==999
generate rango_años=0
replace rango_años=1 if años<99
save "Base Completa Intercensal 2015.dta", replace
collapse (mean) años (last) NOM_MUN [pweight = FACTOR] if (edad_m>24) & (edad_m<999) & rango_años==1, by(estado clave)
save "Base de años promedio de escolaridad 2015.dta"
clear

**Paso 4b. Creación de la tasa de matriculación y de los años esperados
use "Base Completa Intercensal 2015.dta", clear
generate asistencia=.
replace asistencia=1 if ASISTEN==5
replace asistencia=0 if ASISTEN==7
replace asistencia=0 if ASISTEN==9
generate rango=0
replace rango=1 if (EDAD>5) & (EDAD<25)
generate población=FACTOR
generate matriculados=población*asistencia
save "Base Completa Intercensal 2015.dta", replace
collapse (sum) población (sum) matriculados (last) NOM_MUN if rango==1, by(estado clave EDAD)
generate tm=matriculados/población
order estado clave NOM_MUN EDAD población matriculados tm
sort clave
by clave: egen aesperados=sum(tm)
save "Tasa de matriculación 2015.dta"
clear

**Paso 4c. Pegado de las bases de datos para generar el Índice
use "Tasa de matriculación 2015.dta"
duplicates drop clave, force
drop EDAD población matriculados tm
merge m:m clave using "Base de años promedio de escolaridad 2015.dta"
save "Base para el IE2015.dta"

**Paso 4d. Creación de los índices
**//Los valores de referencia son 18, como máximos años esperados de educación y 15, como años máximos promedio de escolaridad//**
**Los valores se obtuvieron en la Nota técnica del Informe sobre Desarrollo Humano 2018 http://hdr.undp.org/sites/default/files/hdr2018_technical_notes.pdf

generate IAP=años/15
generate IAE=aesperados/18
generate IEDU=(IAP+IAE)/2
table NOM_MUN, contents(mean IEDU )

rename IAP IAP2015
rename IAE IAE2015
rename IEDU IEDU2015
rename aesperados aesperados2015
rename años años2015
save "Base para el IE2015.dta", replace

********************************************************************************             
*                            Censo 2010                                        *
*                                                                              * 
********************************************************************************
cd "G:\PNUD\Generación del IDHM 2015\Índice de Educación\Censo\Stata"
use "Base Completa Muestra Censal 2010.dta"

**Paso 1. Generación de nuevas variables, previo a la recodificación
generate ASISTEN_R=ASISTEN
generate ESCOLARI_R=ESCOLARI
generate NIVACAD_R=NIVACAD
generate ESCOACUM_R=ESCOACUM
 
**Paso 2. Recodificación de los años de escolaridad
generate años=.						
replace años=	0	if NIVACAD_R==	0			
replace años=	0	if NIVACAD_R==	1			
replace años=	1	if NIVACAD_R==	2	 & ESCOLARI_R==	1	
replace años=	2	if NIVACAD_R==	2	 & ESCOLARI_R==	2	
replace años=	3	if NIVACAD_R==	2	 & ESCOLARI_R==	3	
replace años=	4	if NIVACAD_R==	2	 & ESCOLARI_R==	4	
replace años=	5	if NIVACAD_R==	2	 & ESCOLARI_R==	5	
replace años=	6	if NIVACAD_R==	2	 & (ESCOLARI_R>5)	  & (ESCOLARI_R<99)	
replace años=	7	if NIVACAD_R==	3	 & ESCOLARI_R==	1	
replace años=	8	if NIVACAD_R==	3	 & ESCOLARI_R==	2	
replace años=	9	if NIVACAD_R==	3	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)	
replace años=	10	if NIVACAD_R==	4	 & ESCOLARI_R==	1	
replace años=	11	if NIVACAD_R==	4	 & ESCOLARI_R==	2	
replace años=	12	if NIVACAD_R==	4	 & ESCOLARI_R==	3	
replace años=	13	if NIVACAD_R==	4	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace años=	6	if NIVACAD_R==	6			
replace años=	10	if NIVACAD_R==	7	 & ESCOLARI_R==	1	
replace años=	11	if NIVACAD_R==	7	 & ESCOLARI_R==	2	
replace años=	12	if NIVACAD_R==	7	 & ESCOLARI_R==	3	
replace años=	13	if NIVACAD_R==	7	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace años=	13	if NIVACAD_R==	8	 & ESCOLARI_R==	1	
replace años=	14	if NIVACAD_R==	8	 & ESCOLARI_R==	2	
replace años=	15	if NIVACAD_R==	8	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)	
replace años=	10	if NIVACAD_R==	5	 & ESCOLARI_R==	1	
replace años=	11	if NIVACAD_R==	5	 & ESCOLARI_R==	2	
replace años=	12	if NIVACAD_R==	5	 & ESCOLARI_R==	3	
replace años=	13	if NIVACAD_R==	5	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace años=	13	if NIVACAD_R==	9	 & ESCOLARI_R==	1	
replace años=	14	if NIVACAD_R==	9	 & ESCOLARI_R==	2	
replace años=	15	if NIVACAD_R==	9	 & ESCOLARI_R==	3	
replace años=	16	if NIVACAD_R==	9	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace años=	13	if NIVACAD_R==	10	 & ESCOLARI_R==	1	
replace años=	14	if NIVACAD_R==	10	 & ESCOLARI_R==	2	
replace años=	15	if NIVACAD_R==	10	 & ESCOLARI_R==	3	
replace años=	16	if NIVACAD_R==	10	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace años=	17	if NIVACAD_R==	11	 & ESCOLARI_R==	1	
replace años=	18	if NIVACAD_R==	11	 & (ESCOLARI_R>1)	  & (ESCOLARI_R<99)	
replace años=	18	if NIVACAD_R==	12	& ESCOLARI_R<99		

**Paso 3. Creación de identificadores únicos

generate estado=ENT
generate municipio=MUN
destring estado municipio, replace
generate clave=(estado*1000)+municipio

**Paso 4. Creación del Índice de Educación

**Paso 4a. Creación de los años promedio de escolaridad
generate edad_m=EDAD
replace edad_m=. if EDAD==999
generate rango_años=0
replace rango_años=1 if años<99
save "Base Completa Muestra Censal 2010.dta", replace
collapse (mean) años (last) NOM_MUN [pweight = FACTOR] if (edad_m>24) & (edad_m<999) & rango_años==1, by(estado clave)
save "Base de años promedio de escolaridad 2010.dta"
clear


**Paso 4b. Creación de la tasa de matriculación y de los años esperados
use "Base Completa Muestra Censal 2010.dta", clear
generate asistencia=.
replace asistencia=1 if ASISTEN==1
replace asistencia=0 if ASISTEN==3
replace asistencia=0 if ASISTEN==9
generate rango=0
replace rango=1 if (EDAD>5) & (EDAD<25)
generate población=FACTOR
generate matriculados=población*asistencia
save "Base Completa Muestra Censal 2010.dta", replace
collapse (sum) población (sum) matriculados (last) NOM_MUN if rango==1, by(estado clave EDAD)
generate tm=matriculados/población
order estado clave NOM_MUN EDAD población matriculados tm
sort clave
by clave: egen aesperados=sum(tm)
save "Tasa de matriculación 2010.dta"
clear

**Paso 4c. Pegado de las bases de datos para generar el Índice
use "Tasa de matriculación 2010.dta"
duplicates drop clave, force
drop EDAD población matriculados tm
merge m:m clave using "Base de años promedio de escolaridad 2010.dta"
save "Base para el IE2010.dta"

**Paso 4d. Creación de los índices
**//Los valores de referencia son 18, como máximos años esperados de educación y 15, como años máximos promedio de escolaridad//**
**Los valores se obtuvieron en la Nota técnica del Informe sobre Desarrollo Humano 2018 http://hdr.undp.org/sites/default/files/hdr2018_technical_notes.pdf

generate IAP=años/15
generate IAE=aesperados/18
generate IEDU=(IAP+IAE)/2
table NOM_MUN, contents(mean IEDU )

rename IAP IAP2010
rename IAE IAE2010
rename IEDU IEDU2010
rename aesperados aesperados2010
rename años años2010
save "Base para el IE2010.dta", replace

**Paso 5. Pegado en una sola base

cd "G:\PNUD\Generación del IDHM 2015\Índice de Educación\Base completa"
use "Base para el IE2010.dta"
drop _merge
merge 1:1 clave using "Base para el IE2015.dta", generate(_merge2)
drop _merge
save "Base del IEDU2010_2015.dta"
order estado clave NOM_MUN IEDU2010 IEDU2015 aesperados2010 años2010 IAP2010 IAE2010 aesperados2015 años2015 IAP2015 IAE2015 _merge
save "Índice de Educación.dta", replace 
clear all

********************************************************************************             
*                Cálculo del Índice de Desarrollo Humano                       *
*                        Municipal  2010 y 2015                                *                                                        * 
********************************************************************************

cd "G:\PNUD\Generación del IDHM 2015\Índice General"


use "Índice de Educación"
drop _merge
merge 1:1 clave using "Base para el cálculo del Índice de Ingreso 2010 y 2015", generate(_merge3)
merge 1:1 clave using "Base para el cálculo del Índice de Salud municipal", generate(merge4) force

generate IDHM_2010=(IEDU2010*II_2010*IS_2010)^(1/3)
generate IDHM_2015=(IEDU2015*II_2015*IS_2015)^(1/3)

save "Índice de Desarrollo Humano Municipal 2010 - 2015", replace
