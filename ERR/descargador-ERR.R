# ============================================================
# descargador-err.R
# Descarga datos del Enterprise Rain Rate (ERR) desde AWS S3.
# Para cada timestamp, usa el tile GLB de mayor numero
# disponible (GLB-5 si esta, si no GLB-4, etc.).
# Entrada: rango de fechas (UTC) y paso temporal
# Salida : archivos .nc en la carpeta de descarga
# ============================================================

library(aws.s3) #carga la libreria para trabajar con buckets de AWS

setwd("ruta/a/tus/datos") #directorio donde se guardaran los archivos

bucket <- "noaa-enterprise-rainrate-pds" #nombre del bucket en AWS
carpeta_descarga <- "descarga_ERR" #carpeta donde se guardaran los archivos
dir.create(carpeta_descarga, showWarnings = FALSE) #crea la carpeta si no existe

# ------------------------------------------------------------
# Definir rango de fechas a descargar (en UTC)
# ------------------------------------------------------------
fecha_ini <- as.POSIXct("2026-06-05 20:00:00", tz = "UTC") #fecha y hora inicial (ajustar)
fecha_fin <- as.POSIXct("2026-06-06 03:00:00", tz = "UTC") #fecha y hora final (ajustar)

fechas <- seq(fecha_ini, fecha_fin, by = "10 min") #genera secuencia cada 10 minutos
print(fechas)

# ------------------------------------------------------------
# Descargar cada archivo del rango
# ------------------------------------------------------------
registro <- NULL #variable vacia para acumular el registro de tiles usados

for (i in seq_along(fechas)) { #recorre cada fecha de la secuencia
  f <- fechas[i] #accede a la fecha por indice

  ano  <- format(f, "%Y") #extrae el ano
  mes  <- format(f, "%m") #extrae el mes
  dia  <- format(f, "%d") #extrae el dia
  hora <- format(f, "%H") #extrae la hora
  prefijo <- paste0("BLEND/RainRate-Blend-INST/", ano, "/", mes, "/", dia, "/", hora, "/") #ruta de la carpeta

  objetos <- get_bucket_df(bucket = bucket, prefix = prefijo, max = 1000) #lista los archivos de esa carpeta

  timestamp_12 <- format(f, "%Y%m%d%H%M") #timestamp sin segundos
  candidatos <- subset(objetos, grepl(timestamp_12, Key)) #filtra los archivos que contienen ese timestamp

  if (nrow(candidatos) > 0) { #si hay candidatos
    candidatos$tile <- as.numeric(sub(".*GLB-(\\d+).*", "\\1", candidatos$Key)) #extrae el numero de tile
    tile_max <- max(candidatos$tile) #toma el tile de mayor numero
    archivo <- subset(candidatos, tile == tile_max)$Key[1] #selecciona el primer archivo con ese tile

    nombre  <- basename(archivo) #nombre del archivo
    destino <- file.path(carpeta_descarga, nombre) #ruta donde se guardara

    tryCatch({ #intenta descargar, si falla no detiene el bucle
      save_object(object = archivo, bucket = bucket, file = destino, overwrite = TRUE) #descarga el archivo
      print(paste("Descargado:", nombre, "| tile:", tile_max)) #muestra el avance
    }, error = function(e) {
      print(paste("Error al descargar:", nombre, "-", e$message)) #avisa si falla
    })

    registro <- rbind(registro, data.frame( #agrega la fila al registro
      timestamp_utc = format(f, "%Y-%m-%d %H:%M:%S"), #timestamp en UTC
      tile = tile_max #tile usado
    ))
  } else {
    print(paste("No encontrado:", timestamp_12)) #avisa si no hay archivos
  }
}

write.csv(registro, "registro_tiles.csv", row.names = FALSE, quote = FALSE) #guarda el registro de tiles
print("Listo.")
