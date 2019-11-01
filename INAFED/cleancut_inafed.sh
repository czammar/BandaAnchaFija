# Script de bash para extrar la tabla de inafed, excluyendo el resto de lineas del archivo original descargado

cat inafed_bd_1572627261.csv | sed -n '5,2494p' >  inafed_cut.csv
