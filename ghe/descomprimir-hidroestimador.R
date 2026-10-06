# ============================================================
# descomprimir-hidroestimador.R
# Descomprime los archivos .nc.gz descargados del GHE y los
# guarda como .nc en una subcarpeta.
# Entrada: archivos .nc.gz en la carpeta de descarga
# Salida : archivos .nc en la subcarpeta nc
#
# Nota: gunzip elimina el .gz original despues de descomprimir.
# ============================================================

setwd("ruta/a/tus/datos/descarga_Hidroestimador") #directorio donde estan los .gz

library(R.utils)

listfiles <- list.files(path = getwd(), pattern = ".gz", full.names = TRUE) #lista los archivos .gz
print(listfiles)

for (i in 1:length(listfiles)) {
  gunzip(listfiles[i], destname = file.path("nc", sub(".gz$", "", basename(listfiles[i])))) #descomprime en la subcarpeta nc
}
