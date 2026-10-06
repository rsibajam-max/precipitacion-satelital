# precipitacion-satelital

Pipeline en R para descargar, procesar y comparar datos de precipitación satelital de NOAA con registros de estaciones meteorológicas en tierra.

El repositorio contiene dos flujos independientes:

- **GHE** (Global Hydro-Estimator): producto histórico, descontinuado en 2025.
- **ERR** (Enterprise Rain Rate): producto vigente, reemplazo del GHE.

Ambos estiman precipitación a partir de imágenes satelitales infrarrojas. El objetivo es automatizar la descarga, el procesamiento y la comparación con datos de estaciones del IMN.

## Estructura del repositorio

```
.
├── README.md
├── ghe/
│   ├── descargador-hidroestimador.R
│   ├── descomprimir-hidroestimador.R
│   ├── seleccionador-hidroestimador.R
│   └── datos/
│       └── comparacion_imn_ghe.csv
└── err/
    ├── descargador-err.R
    ├── seleccionador-err.R
    └── datos/
        └── comparacion_imn_err.csv
```

## Requisitos

- R (probado en versiones recientes)
- Paquetes:
  - `aws.s3`
  - `dplyr`
  - `R.utils`
  - `ncdf4`

Instalación:

```r
install.packages(c("aws.s3", "dplyr", "R.utils", "ncdf4"))
```

---

## GHE (Global Hydro-Estimator)

Producto satelital de NOAA que estima precipitación a partir de imágenes infrarrojas, con resolución espacial de ~5 km y resolución temporal de 15 minutos. Fue descontinuado en 2025.

### Flujo de trabajo

```
1. descargador-hidroestimador.R     → descarga archivos .nc.gz desde AWS S3
2. descomprimir-hidroestimador.R    → descomprime a .nc en subcarpeta nc/
3. seleccionador-hidroestimador.R   → extrae el valor del pixel de la estacion
                                       y lo guarda en CSV con hora local
```

### Scripts

**`descargador-hidroestimador.R`**

Descarga archivos del GHE desde el bucket público de NOAA en AWS S3.

- **Entrada:** rango de fechas (inicio, fin)
- **Salida:** archivos `.nc.gz` en la carpeta `descarga_Hidroestimador`

**Nota:** el descargador original apuntaba al FTP de NOAA. Ese FTP fue retirado y los datos migraron temporalmente a un bucket de AWS S3. En 2025, el producto fue descontinuado y reemplazado por el ERR. El bucket cubre el período 2019–2025 y ya no recibe actualizaciones.

**`descomprimir-hidroestimador.R`**

Descomprime los archivos `.nc.gz` y los guarda como `.nc` en la subcarpeta `nc/`.

- **Entrada:** archivos `.nc.gz`
- **Salida:** archivos `.nc` en `descarga_Hidroestimador/nc/`

**Nota:** `gunzip` elimina el `.gz` original después de descomprimir. Cada `.nc` pesa ~180 MB.

**`seleccionador-hidroestimador.R`**

Extrae el valor de lluvia del píxel más cercano a una estación meteorológica.

- **Entrada:** carpeta `nc` con archivos `.nc`
- **Salida:** CSV con fecha, hora, lat, lon y valor de lluvia

**Nota:** el script está parametrizado con coordenadas de la estación Upala como ejemplo. La fecha y hora se convierten de UTC a hora local de Costa Rica.

### Caso de estudio GHE

Se compararon datos del GHE con registros de la estación automática de Upala (IMN) para dos eventos:

| Fecha | Hora local | Lluvia IMN (mm) | Lluvia GHE (mm) |
|-------|------------|------------------|------------------|
| 2020-05-20 | 14:00 | 0 | 0 |
| 2020-05-20 | 15:00 | 79.8 | 0 |
| 2020-05-20 | 16:00 | 5.2 | 0 |
| 2021-08-21 | 15:00 | 0 | 0 |
| 2021-08-21 | 16:00 | 41.6 | 0 |
| 2021-08-21 | 17:00 | 0.6 | 0 |

**Observaciones:**

- El GHE no registró los eventos de lluvia puntual en la estación de Upala, aunque el IMN sí los registró.
- Al analizar el raster completo del GHE para el evento del 2020-05-20, se encontró que el producto sí detectó lluvia ese día en Costa Rica, pero concentrada en el Pacífico Sur.
- Esto es consistente con limitaciones conocidas del algoritmo del GHE en eventos de convección poco profunda o de corta duración.

---

## ERR (Enterprise Rain Rate)

Producto satelital de NOAA que reemplaza al GHE. Resolución espacial de ~2 km y resolución temporal de 10 minutos. Disponible desde 2025.

### Flujo de trabajo

```
1. descargador-err.R     → descarga archivos .nc desde AWS S3
2. seleccionador-err.R   → extrae el valor del pixel de la estacion
                           y lo guarda en CSV con hora local
```

### Scripts

**`descargador-err.R`**

Descarga archivos del ERR desde el bucket público de NOAA en AWS S3. Para cada timestamp, usa el tile GLB de mayor número disponible (GLB-5 si está, si no GLB-4, etc.).

- **Entrada:** rango de fechas (inicio, fin)
- **Salida:** archivos `.nc` en la carpeta `descarga_ERR`

**Nota:** el producto está dividido en 5 tiles (`GLB-1` a `GLB-5`). El tile de mayor número integra más satélites y tiene mayor cobertura válida. No todos los tiles están disponibles en todas las horas.

**`seleccionador-err.R`**

Extrae el valor de lluvia del píxel más cercano a una estación meteorológica.

- **Entrada:** carpeta con archivos `.nc`
- **Salida:** CSV con fecha, hora, lat, lon y valor de lluvia

**Nota:** el script está parametrizado con coordenadas de la estación Upala como ejemplo. La fecha y hora se convierten de UTC a hora local de Costa Rica.

### Caso de estudio ERR

Se compararon datos del ERR con registros de la estación automática de Upala (IMN) para el evento del 5 de junio de 2026.

| Fecha | Hora local | Lluvia IMN (mm) | Lluvia ERR (mm) |
|-------|------------|------------------|------------------|
| 2026-06-05 | 14:00 | 0 | 0 |
| 2026-06-05 | 15:00 | 4.4 | 0 |
| 2026-06-05 | 16:00 | 31.8 | 38.5 |
| 2026-06-05 | 17:00 | 10 | 25.5 |
| 2026-06-05 | 18:00 | 5 | 9.0 |
| 2026-06-05 | 19:00 | 1.4 | 0 |
| 2026-06-05 | 20:00 | 0.2 | 0 |
| 2026-06-05 | 21:00 | 0 | 0 |

**Observaciones:**

- El ERR captó el evento principal de lluvia (16:00–18:00), con una sobreestimación.
- El ERR también detectó lloviznas leves que el IMN registró con valores bajos.
- Los acumulados horarios del ERR son del mismo orden de magnitud que los del IMN.

---

## Conclusión

Ambos productos satelitales permiten captar eventos de lluvia y observar tendencias generales. Sin embargo, presentan limitaciones para su utilización como fuente de precipitación en aplicaciones cuantitativas como la alimentación de modelos hidrológicos (HEC-HMS) o hidráulicos (HEC-RAS).

La experiencia previa con el GHE durante trabajos de modelación hidrológica mostró resultados poco satisfactorios para este tipo de aplicación. El ERR presenta una mejor capacidad para captar los eventos observados en los casos analizados, aunque mantiene una tendencia similar a la observada anteriormente con el GHE.

Los productos satelitales resultan útiles como fuente complementaria de información sobre precipitación, pero las mediciones en tierra continúan siendo fundamentales para aplicaciones de modelación hidrológica e hidráulica.

## Contexto

Este repositorio forma parte de un portafolio de proyectos desarrollados para demostrar el uso de R aplicado a problemas de ingeniería y análisis de información ambiental.


