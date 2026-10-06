# ============================================================
# descargador-hidroestimador.R
# Descarga datos del Global Hydro-Estimator (GHE) desde AWS S3
# en un rango de fechas definido.
# Entrada: rango de fechas (inicio, fin) y paso temporal
# Salida : archivos .nc.gz en la carpeta de trabajo
#
# Nota: version adaptada del descargador original, que apuntaba
# al FTP de NOAA (ftp://ftp.star.nesdis.noaa.gov/...). Ese FTP
# fue retirado en 2025 y los datos migraron a AWS S3.
# ============================================================

library(aws.s3)
library(dplyr)

setwd("ruta/a/tus/datos") #directorio donde se guardaran los archivos

url_base <- "https://noaa-ghe-pds.s3.amazonaws.com/rain_rate/" #ruta base del bucket en AWS

options(timeout = 30) #evita que se quede colgado esperando respuesta del servidor

carpeta_descarga <- "descarga_Hidroestimador" #carpeta donde se guardaran los archivos

# ------------------------------------------------------------
# Definir rango de fechas a descargar
# ------------------------------------------------------------
fecha_ini <- as.POSIXct("2020-05-20 19:15:00", tz = "UTC") #fecha y hora inicial (ajustar)
fecha_fin <- as.POSIXct("2020-05-20 22:00:00", tz = "UTC") #fecha y hora final (ajustar)

fechas <- seq(fecha_ini, fecha_fin, by = "15 min") #genera secuencia cada 15 minutos
print(fechas)

# ------------------------------------------------------------
# Descargar cada archivo del rango
# ------------------------------------------------------------
for (i in seq_along(fechas)) { #recorre cada fecha de la secuencia
  f <- fechas[i] #accede a la fecha por indice, conservando su clase

  ano  <- format(f, "%Y") #extrae el ano
  mes  <- format(f, "%m") #extrae el mes
  dia  <- format(f, "%d") #extrae el dia
  hhmm <- format(f, "%H%M") #extrae la hora y minutos

  nombre <- paste0("NPR.GEO.GHE.v1.S", ano, mes, dia, hhmm, ".nc.gz") #construye el nombre del archivo
  ruta   <- paste0(url_base, ano, "/", mes, "/", dia, "/", nombre) #construye la ruta completa

  destino <- file.path(carpeta_descarga, nombre) #ruta donde se guardara el archivo

  tryCatch({ #intenta descargar, si falla no detiene el bucle
    download.file(ruta, destfile = destino, mode = "wb", quiet = TRUE) #descarga el archivo
    print(paste("Descargado:", nombre)) #muestra el avance
  }, error = function(e) {
    print(paste("No disponible:", nombre)) #avisa si un archivo no existe
  })
}
