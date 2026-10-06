# ============================================================
# seleccionador-err.R
# Extrae el valor de lluvia del pixel mas cercano a la estacion
# meteorologica, desde archivos NetCDF del ERR, y lo guarda
# en un CSV con fecha y hora en zona local de Costa Rica.
# Entrada: carpeta con archivos .nc
# Salida : CSV con fecha, hora, lat, lon y valor de lluvia
# ============================================================

library(ncdf4)

setwd("ruta/a/tus/datos/descarga_ERR") #directorio donde estan los .nc

listfiles <- list.files(pattern = ".nc$", full.names = TRUE) #lista de archivos NetCDF
print(listfiles)

# Coordenadas de la estacion Upala
lat_upala <- 10.880833
lon_upala <- -85.0725

# Parametros de la malla del ERR (de los atributos globales)
n_cols  <- 18000
n_rows  <- 6501
lon_min <- -180
lon_max <- 179.98
lat_max <- 70
lat_min <- -60

# Calcula el pixel central mas cercano a Upala
col_central <- round((lon_upala - lon_min) / ((lon_max - lon_min) / n_cols)) + 1
row_central <- round((lat_max - lat_upala) / ((lat_max - lat_min) / n_rows)) + 1
print(paste("Pixel central (row, col):", row_central, col_central))

resultado <- NULL #variable vacia para acumular

for (i in 1:length(listfiles)) {
  nc <- nc_open(listfiles[i]) #abre el NetCDF
  rrqpe <- ncvar_get(nc, "RRQPE") #lee la variable de lluvia
  nc_close(nc) #cierra el archivo

  # Extrae el valor del pixel central
  valor <- rrqpe[col_central, row_central]

  # Nombre del archivo actual
  archivo <- basename(listfiles[i])

  # Extrae fecha y hora (UTC) del nombre del archivo
  fecha_hora <- sub(".*_s(\\d{14}).*", "\\1", archivo)
  ano  <- substr(fecha_hora, 1, 4)
  mes  <- substr(fecha_hora, 5, 6)
  dia  <- substr(fecha_hora, 7, 8)
  hora <- substr(fecha_hora, 9, 10)
  min  <- substr(fecha_hora, 11, 12)

  # Convierte de UTC a hora local de Costa Rica
  fecha_utc <- as.POSIXct(paste(ano, mes, dia, hora, min, sep = "-"),
                          format = "%Y-%m-%d-%H-%M",
                          tz = "UTC")

  fecha_local <- format(fecha_utc, tz = "America/Costa_Rica")

  # Extrae componentes en hora local
  ano  <- substr(fecha_local, 1, 4)
  mes  <- substr(fecha_local, 6, 7)
  dia  <- substr(fecha_local, 9, 10)
  hora <- substr(fecha_local, 12, 13)
  min  <- substr(fecha_local, 15, 16)

  # Acumula el resultado
  temp <- data.frame(
    fecha = paste(ano, mes, dia, sep = "-"),
    hora  = paste(hora, min, sep = ":"),
    lat   = lat_upala,
    lon   = lon_upala,
    valor = valor
  )

  resultado <- rbind(resultado, temp)
  print(paste("Procesado:", archivo))
}

write.csv(resultado, "Upala_ERR.csv", row.names = FALSE, quote = FALSE)
print("Listo.")
