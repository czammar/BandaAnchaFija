
********************************************************************************             
*																			   *
*                C�lculo del �ndice de Desarrollo Humano Municipal             *
*                                2010 y 2015                                   *
*																			   *
********************************************************************************


********************************************************************************             
*                C�lculo del componente de Ingreso 2010 y 2015                 *
*                                                                              * 
********************************************************************************

**Paso previo: acomodo de las bases de datos

cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Ingreso"
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

import excel "Poblaci�n CONEVAL.xlsx", sheet("Hoja1") firstrow
generate clave=Clavedemunicipio
destring clave, replace
generate estado=Clavedeentidad
destring estado, replace
rename Municipio municipio
drop Clavedeentidad Clavedemunicipio
egen pob15=sieve(Poblaci�n2015), keep(n)
destring pob15, replace
rename Poblaci�n2010 pob10
drop Poblaci�n2015
save "Poblaci�n CONEVAL 2010 y 2015.dta"

use "Base del ICTPC2010.dta"
merge 1:1 clave using "Base del ICTPC2015.dta", generate(_merge1)
merge 1:1 clave using "Poblaci�n CONEVAL 2010 y 2015.dta", generate(_merge2)
save "Base para el c�lculo del �ndice de Ingreso 2010 y 2015.dta"

**Pasos sustantivos para la creaci�n del �ndice de Ingreso

cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Ingreso"
use "Base para el c�lculo del �ndice de Ingreso 2010 y 2015.dta"

**Paso 1. Cambio del ICTPC  a precios de diciembre de 2015 (INPC NOV2010=99.250; INPC NOV2015=118.051; INPC DIC2015=118.532)
generate ICTP2010_15=ICTPC2010*(118.532/99.250)
generate ICTP2015_15=ICTPC2015*(118.532/118.051)

**Paso 2. Generaci�n del ICTPC anual
generate ICTPC2010_a=ICTP2010_15*12
generate ICTPC2015_a=ICTP2015_15*12

**Paso 3. Generaci�n del factor de ajuste utilizando el Ingreso Nacional Bruto (INB) 
generate PICTPC2010=ICTPC2010_a*pob10
generate PICTPC2015=ICTPC2015_a*pob15
format %20.0g PICTPC2010
format %20.0g PICTPC2015
tabstat PICTPC2010 PICTPC2015 , statistics( sum ) format(%20.0f)
egen double ICTPC2010_TOTAL=total(PICTPC2010)
egen double  ICTPC2015_TOTAL=total(PICTPC2015)

*Actualizaci�n del INB de 2010 [13207409.731*(118.532/99.742)]=15,695,501.2957
*Factor de ajuste en 2010=(15,695,501.2957*1,000,000)/4,490,668,602,668=3.495136846
*Factor de ajuste en 2015=(18,097,999.4780*1,000,000)/4,578,424,998,864=3.9528876
 
generate FACTOR2010_INB=((15695501.2957*1000000)/ICTPC2010_TOTAL)
generate FACTOR2015_INB=((18097999.4780*1000000)/ICTPC2015_TOTAL)

**Paso 4. Multiplicar el ICTPC anual, a precios de diciembre de 2015 por el factor de ajuste
generate ICTPC_ajustado10=ICTPC2010_a*FACTOR2010_INB
generate ICTPC_ajustado15=ICTPC2015_a*FACTOR2015_INB

**Paso 5. Dividir el ICTPC ajustado entre el Factor de conversi�n de PPA (para 2015), PIB (UMN por $ a precios internacionales) https://datos.bancomundial.org/indicador/PA.NUS.PPP?locations=MX

generate ING_PPC10=ICTPC_ajustado10/8.5411
generate ING_PPC15=ICTPC_ajustado15/8.5411

**Paso 6. Crear el �ndice de Ingreso del IDHM
generate II_2010=(ln(ING_PPC10)-ln(100))/(ln(75000)-ln(100))
generate II_2015=(ln(ING_PPC15)-ln(100))/(ln(75000)-ln(100))

save "Base para el c�lculo del �ndice de Ingreso 2010 y 2015.dta", replace
clear


********************************************************************************             
*                C�lculo del componente de salud 2010 y 2015                   *
*                                                                              * 
********************************************************************************


**Paso previo: acomodo de las bases de datos

cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Salud"
import excel "Tasas de mortalidad infantil del CONAPO 20180515.xlsx", sheet("Hoja1") firstrow
generate estado=Claveentidad
generate municipio=Clavemunicipio
generate clave=(estado*1000)+municipio

save "Base para el c�lculo del �ndice de Salud municipal.dta", replace

**Pasos sustantivos para la creaci�n del �ndice de Salud

**Paso 1. C�lculo del �ndice de Salud Nacional con base en los referentes internacionales del Reporte Global del IDH 2016
generate IS_N=(77-20)/(85-20)

**Paso 2. Crear la variable de poblaci�n para cada a�o
egen pob_nac_2010=sum(poblaci�n_2010)
egen pob_nac_2015=sum(poblaci�n_2015)
format %20.0g pob_nac_2010
format %20.0g pob_nac_2015

**Paso 3. Calcular el m�ximo a partir de la Tasa de mortalidad infantil de referencia m�s baja (1.7 para Islandia), en t�rminos de Supervivencia infantil
generate max=1-(1.7/1000)

**Paso 4. Expresar la Tasa de mortalidad infantil municipal, en t�rminos de Supervivencia infantil
generate  SI_2010=1-(TMI2010/1000)
generate  SI_2015=1-(TMI2015/1000)

egen SI_N2010=sum(SI_2010*(poblaci�n_2010/pob_nac_2010))
egen SI_N2015=sum(SI_2015*(poblaci�n_2015/pob_nac_2015))

**Paso 5. Calcular el valor m�nimo a partir del despeje de la f�rmula
generate min_2010=(SI_N2010-(IS_N*max))/(1-IS_N)
generate min_2015=(SI_N2015-(IS_N*max))/(1-IS_N)

**Paso 6. Calcular el �ndice de Salud
generate IS_2015=(SI_2015-min_2015)/(max-min_2015)
generate IS_2010=(SI_2010-min_2015)/(max-min_2015)

save "Base para el c�lculo del �ndice de Salud municipal.dta", replace
clear

********************************************************************************             
*                C�lculo del componente de educaci�n 2010 y 2015               *
*                                                                              * 
********************************************************************************


**//C�lculo del �ndice de Educaci�n para el IDH Municipal en 2015 y 2010//**

**Paso previo: acomodo de las bases, de cada entidad federativa, de la Encuesta Intercensal 2015 y del Censo 2010
**Las bases de datos del Censo 2010 est�n en la secci�n de microdatos: https://www.inegi.org.mx/programas/ccpv/2010/**
**Las bases de datos de la Encuesta Intercensal 2015 est�n est�n en la secci�n de microdatos: https://www.inegi.org.mx/programas/intercensal/2015/default.html**
**Para 2010 y 2015, el INEGI tiene las bases separadas por entidad federativa, por lo que primero hay que descargarlas, en este caso, en formato Stata y luego pegarlas, conforme al paso que se describe enseguida.
**En el paso  siguiente, se pegan las bases en un s�lo archivo y s�lo se mantienen las variables necesarias para la construcci�n del �ndice de Educaci�n**

//Paso previo: Generaci�n de una base para 2010 y otra correspondiente a 2015, a partir de las bases del INEGI de cada entidad federativa//

**Encuesta Intercensal**
cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Educaci�n\Encuesta Intercensal\Stata"
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
cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Educaci�n\Censo\Stata"
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
cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Educaci�n\Encuesta Intercensal\Stata"
use "Base Completa Intercensal 2015.dta"

**Paso 1. Generaci�n de nuevas variables, previo a la recodificaci�n
generate ASISTEN_R=ASISTEN
generate ESCOLARI_R=ESCOLARI
generate NIVACAD_R=NIVACAD
generate ESCOACUM_R=ESCOACUM
   
**Paso 2. Recodificaci�n de los a�os de escolaridad
generate a�os=.					
replace a�os=	0	if NIVACAD_R==	0		
replace a�os=	0	if NIVACAD_R==	1		
replace a�os=	1	if NIVACAD_R==	2	 & ESCOLARI_R==	1
replace a�os=	2	if NIVACAD_R==	2	 & ESCOLARI_R==	2
replace a�os=	3	if NIVACAD_R==	2	 & ESCOLARI_R==	3
replace a�os=	4	if NIVACAD_R==	2	 & ESCOLARI_R==	4
replace a�os=	5	if NIVACAD_R==	2	 & ESCOLARI_R==	5
replace a�os=	6	if NIVACAD_R==	2	 & (ESCOLARI_R>5)	  & (ESCOLARI_R<99)
replace a�os=	7	if NIVACAD_R==	3	 & ESCOLARI_R==	1
replace a�os=	8	if NIVACAD_R==	3	 & ESCOLARI_R==	2
replace a�os=	9	if NIVACAD_R==	3	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)
replace a�os=	10	if NIVACAD_R==	4	 & ESCOLARI_R==	1
replace a�os=	11	if NIVACAD_R==	4	 & ESCOLARI_R==	2
replace a�os=	12	if NIVACAD_R==	4	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)
replace a�os=	10	if NIVACAD_R==	5	 & ESCOLARI_R==	1
replace a�os=	11	if NIVACAD_R==	5	 & ESCOLARI_R==	2
replace a�os=	12	if NIVACAD_R==	5	 & ESCOLARI_R==	3
replace a�os=	13	if NIVACAD_R==	5	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace a�os=	6	if NIVACAD_R==	6		
replace a�os=	10	if NIVACAD_R==	7	 & ESCOLARI_R==	1
replace a�os=	11	if NIVACAD_R==	7	 & ESCOLARI_R==	2
replace a�os=	12	if NIVACAD_R==	7	 & ESCOLARI_R==	3
replace a�os=	13	if NIVACAD_R==	7	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace a�os=	13	if NIVACAD_R==	8	 & ESCOLARI_R==	1
replace a�os=	14	if NIVACAD_R==	8	 & ESCOLARI_R==	2
replace a�os=	15	if NIVACAD_R==	8	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)
replace a�os=	10	if NIVACAD_R==	9	 & ESCOLARI_R==	1
replace a�os=	11	if NIVACAD_R==	9	 & ESCOLARI_R==	2
replace a�os=	12	if NIVACAD_R==	9	 & ESCOLARI_R==	3
replace a�os=	13	if NIVACAD_R==	9	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace a�os=	13	if NIVACAD_R==	10	 & ESCOLARI_R==	1
replace a�os=	14	if NIVACAD_R==	10	 & ESCOLARI_R==	2
replace a�os=	15	if NIVACAD_R==	10	 & ESCOLARI_R==	3
replace a�os=	16	if NIVACAD_R==	10	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace a�os=	13	if NIVACAD_R==	11	 & ESCOLARI_R==	1
replace a�os=	14	if NIVACAD_R==	11	 & ESCOLARI_R==	2
replace a�os=	15	if NIVACAD_R==	11	 & ESCOLARI_R==	3
replace a�os=	16	if NIVACAD_R==	11	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)
replace a�os=	17	if NIVACAD_R==	12	& ESCOLARI_R<99	
replace a�os=	17	if NIVACAD_R==	13	 & ESCOLARI_R==	1
replace a�os=	18	if NIVACAD_R==	13	 & (ESCOLARI_R>1)	  & (ESCOLARI_R<99)
replace a�os=	18	if NIVACAD_R==	14	& ESCOLARI_R<99	
replace a�os=99 if ESCOACUM==99

**Paso 3. Creaci�n de identificadores �nicos

generate estado=ENT
generate municipio=MUN
destring estado municipio, replace
generate clave=(estado*1000)+municipio

**Paso 4. Creaci�n del �ndice de Educaci�n

**Paso 4a. Creaci�n de los a�os promedio de escolaridad
generate edad_m=EDAD
replace edad_m=. if EDAD==999
generate rango_a�os=0
replace rango_a�os=1 if a�os<99
save "Base Completa Intercensal 2015.dta", replace
collapse (mean) a�os (last) NOM_MUN [pweight = FACTOR] if (edad_m>24) & (edad_m<999) & rango_a�os==1, by(estado clave)
save "Base de a�os promedio de escolaridad 2015.dta"
clear

**Paso 4b. Creaci�n de la tasa de matriculaci�n y de los a�os esperados
use "Base Completa Intercensal 2015.dta", clear
generate asistencia=.
replace asistencia=1 if ASISTEN==5
replace asistencia=0 if ASISTEN==7
replace asistencia=0 if ASISTEN==9
generate rango=0
replace rango=1 if (EDAD>5) & (EDAD<25)
generate poblaci�n=FACTOR
generate matriculados=poblaci�n*asistencia
save "Base Completa Intercensal 2015.dta", replace
collapse (sum) poblaci�n (sum) matriculados (last) NOM_MUN if rango==1, by(estado clave EDAD)
generate tm=matriculados/poblaci�n
order estado clave NOM_MUN EDAD poblaci�n matriculados tm
sort clave
by clave: egen aesperados=sum(tm)
save "Tasa de matriculaci�n 2015.dta"
clear

**Paso 4c. Pegado de las bases de datos para generar el �ndice
use "Tasa de matriculaci�n 2015.dta"
duplicates drop clave, force
drop EDAD poblaci�n matriculados tm
merge m:m clave using "Base de a�os promedio de escolaridad 2015.dta"
save "Base para el IE2015.dta"

**Paso 4d. Creaci�n de los �ndices
**//Los valores de referencia son 18, como m�ximos a�os esperados de educaci�n y 15, como a�os m�ximos promedio de escolaridad//**
**Los valores se obtuvieron en la Nota t�cnica del Informe sobre Desarrollo Humano 2018 http://hdr.undp.org/sites/default/files/hdr2018_technical_notes.pdf

generate IAP=a�os/15
generate IAE=aesperados/18
generate IEDU=(IAP+IAE)/2
table NOM_MUN, contents(mean IEDU )

rename IAP IAP2015
rename IAE IAE2015
rename IEDU IEDU2015
rename aesperados aesperados2015
rename a�os a�os2015
save "Base para el IE2015.dta", replace

********************************************************************************             
*                            Censo 2010                                        *
*                                                                              * 
********************************************************************************
cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Educaci�n\Censo\Stata"
use "Base Completa Muestra Censal 2010.dta"

**Paso 1. Generaci�n de nuevas variables, previo a la recodificaci�n
generate ASISTEN_R=ASISTEN
generate ESCOLARI_R=ESCOLARI
generate NIVACAD_R=NIVACAD
generate ESCOACUM_R=ESCOACUM
 
**Paso 2. Recodificaci�n de los a�os de escolaridad
generate a�os=.						
replace a�os=	0	if NIVACAD_R==	0			
replace a�os=	0	if NIVACAD_R==	1			
replace a�os=	1	if NIVACAD_R==	2	 & ESCOLARI_R==	1	
replace a�os=	2	if NIVACAD_R==	2	 & ESCOLARI_R==	2	
replace a�os=	3	if NIVACAD_R==	2	 & ESCOLARI_R==	3	
replace a�os=	4	if NIVACAD_R==	2	 & ESCOLARI_R==	4	
replace a�os=	5	if NIVACAD_R==	2	 & ESCOLARI_R==	5	
replace a�os=	6	if NIVACAD_R==	2	 & (ESCOLARI_R>5)	  & (ESCOLARI_R<99)	
replace a�os=	7	if NIVACAD_R==	3	 & ESCOLARI_R==	1	
replace a�os=	8	if NIVACAD_R==	3	 & ESCOLARI_R==	2	
replace a�os=	9	if NIVACAD_R==	3	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)	
replace a�os=	10	if NIVACAD_R==	4	 & ESCOLARI_R==	1	
replace a�os=	11	if NIVACAD_R==	4	 & ESCOLARI_R==	2	
replace a�os=	12	if NIVACAD_R==	4	 & ESCOLARI_R==	3	
replace a�os=	13	if NIVACAD_R==	4	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace a�os=	6	if NIVACAD_R==	6			
replace a�os=	10	if NIVACAD_R==	7	 & ESCOLARI_R==	1	
replace a�os=	11	if NIVACAD_R==	7	 & ESCOLARI_R==	2	
replace a�os=	12	if NIVACAD_R==	7	 & ESCOLARI_R==	3	
replace a�os=	13	if NIVACAD_R==	7	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace a�os=	13	if NIVACAD_R==	8	 & ESCOLARI_R==	1	
replace a�os=	14	if NIVACAD_R==	8	 & ESCOLARI_R==	2	
replace a�os=	15	if NIVACAD_R==	8	 & (ESCOLARI_R>2)	  & (ESCOLARI_R<99)	
replace a�os=	10	if NIVACAD_R==	5	 & ESCOLARI_R==	1	
replace a�os=	11	if NIVACAD_R==	5	 & ESCOLARI_R==	2	
replace a�os=	12	if NIVACAD_R==	5	 & ESCOLARI_R==	3	
replace a�os=	13	if NIVACAD_R==	5	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace a�os=	13	if NIVACAD_R==	9	 & ESCOLARI_R==	1	
replace a�os=	14	if NIVACAD_R==	9	 & ESCOLARI_R==	2	
replace a�os=	15	if NIVACAD_R==	9	 & ESCOLARI_R==	3	
replace a�os=	16	if NIVACAD_R==	9	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace a�os=	13	if NIVACAD_R==	10	 & ESCOLARI_R==	1	
replace a�os=	14	if NIVACAD_R==	10	 & ESCOLARI_R==	2	
replace a�os=	15	if NIVACAD_R==	10	 & ESCOLARI_R==	3	
replace a�os=	16	if NIVACAD_R==	10	 & (ESCOLARI_R>3)	  & (ESCOLARI_R<99)	
replace a�os=	17	if NIVACAD_R==	11	 & ESCOLARI_R==	1	
replace a�os=	18	if NIVACAD_R==	11	 & (ESCOLARI_R>1)	  & (ESCOLARI_R<99)	
replace a�os=	18	if NIVACAD_R==	12	& ESCOLARI_R<99		

**Paso 3. Creaci�n de identificadores �nicos

generate estado=ENT
generate municipio=MUN
destring estado municipio, replace
generate clave=(estado*1000)+municipio

**Paso 4. Creaci�n del �ndice de Educaci�n

**Paso 4a. Creaci�n de los a�os promedio de escolaridad
generate edad_m=EDAD
replace edad_m=. if EDAD==999
generate rango_a�os=0
replace rango_a�os=1 if a�os<99
save "Base Completa Muestra Censal 2010.dta", replace
collapse (mean) a�os (last) NOM_MUN [pweight = FACTOR] if (edad_m>24) & (edad_m<999) & rango_a�os==1, by(estado clave)
save "Base de a�os promedio de escolaridad 2010.dta"
clear


**Paso 4b. Creaci�n de la tasa de matriculaci�n y de los a�os esperados
use "Base Completa Muestra Censal 2010.dta", clear
generate asistencia=.
replace asistencia=1 if ASISTEN==1
replace asistencia=0 if ASISTEN==3
replace asistencia=0 if ASISTEN==9
generate rango=0
replace rango=1 if (EDAD>5) & (EDAD<25)
generate poblaci�n=FACTOR
generate matriculados=poblaci�n*asistencia
save "Base Completa Muestra Censal 2010.dta", replace
collapse (sum) poblaci�n (sum) matriculados (last) NOM_MUN if rango==1, by(estado clave EDAD)
generate tm=matriculados/poblaci�n
order estado clave NOM_MUN EDAD poblaci�n matriculados tm
sort clave
by clave: egen aesperados=sum(tm)
save "Tasa de matriculaci�n 2010.dta"
clear

**Paso 4c. Pegado de las bases de datos para generar el �ndice
use "Tasa de matriculaci�n 2010.dta"
duplicates drop clave, force
drop EDAD poblaci�n matriculados tm
merge m:m clave using "Base de a�os promedio de escolaridad 2010.dta"
save "Base para el IE2010.dta"

**Paso 4d. Creaci�n de los �ndices
**//Los valores de referencia son 18, como m�ximos a�os esperados de educaci�n y 15, como a�os m�ximos promedio de escolaridad//**
**Los valores se obtuvieron en la Nota t�cnica del Informe sobre Desarrollo Humano 2018 http://hdr.undp.org/sites/default/files/hdr2018_technical_notes.pdf

generate IAP=a�os/15
generate IAE=aesperados/18
generate IEDU=(IAP+IAE)/2
table NOM_MUN, contents(mean IEDU )

rename IAP IAP2010
rename IAE IAE2010
rename IEDU IEDU2010
rename aesperados aesperados2010
rename a�os a�os2010
save "Base para el IE2010.dta", replace

**Paso 5. Pegado en una sola base

cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice de Educaci�n\Base completa"
use "Base para el IE2010.dta"
drop _merge
merge 1:1 clave using "Base para el IE2015.dta", generate(_merge2)
drop _merge
save "Base del IEDU2010_2015.dta"
order estado clave NOM_MUN IEDU2010 IEDU2015 aesperados2010 a�os2010 IAP2010 IAE2010 aesperados2015 a�os2015 IAP2015 IAE2015 _merge
save "�ndice de Educaci�n.dta", replace 
clear all

********************************************************************************             
*                C�lculo del �ndice de Desarrollo Humano                       *
*                        Municipal  2010 y 2015                                *                                                        * 
********************************************************************************

cd "G:\PNUD\Generaci�n del IDHM 2015\�ndice General"


use "�ndice de Educaci�n"
drop _merge
merge 1:1 clave using "Base para el c�lculo del �ndice de Ingreso 2010 y 2015", generate(_merge3)
merge 1:1 clave using "Base para el c�lculo del �ndice de Salud municipal", generate(merge4) force

generate IDHM_2010=(IEDU2010*II_2010*IS_2010)^(1/3)
generate IDHM_2015=(IEDU2015*II_2015*IS_2015)^(1/3)

save "�ndice de Desarrollo Humano Municipal 2010 - 2015", replace
