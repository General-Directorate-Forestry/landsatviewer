# landsatviewer

## Install
At this time you must install `landsatviewer` via GitHub.
```r
devtools::install_github("SilviaTerra/landsatviewer")
```

To make the composite raster images that can be opened in your system GIS software you must have the system package `gdal` installed on your machine and the path to the gdal functions must be visible to R via `system()` calls.
This works better when you launch the shiny app from your terminal (not from Rstudio).

## Usage
The main function is `view_landsat` which will download and assemble a false color composite image using bands 5, 4, and 3 from the specified landsat scene, a true color composite image using bands 4, 3, and 2, the QA band, and the cirrus band (band 9).
The rasters can either be opened in your system GIS software (e.g. QGIS) or in an interactive leaflet map.

### Shiny App
The easiest way to use landsatviewer is to launch the shiny app:
```r
landsatviewer::run_app()
```
This will open up the shiny app where you can browse the Landsat scene archive and filter by path, row, and time (year, month, day).
Once you have selected a scene that you would like to view, you can click the 'Open Rasters' button to download the raw Landsat files and open them in your GIS software, or you can click the 'View Map' button to render an interactive leaflet map with the raster layers.
The leaflet map is slow and will fuzz the resolution of the rasters so opening the files in your system viewer will be a better experience.

### R console
The function can be used without the shiny interface. To create the interactive map just provide the path (`p`), row (`r`), and date (`date`) to
`view_landsat`. Setting `open_rasts` to `TRUE` will send the files to your GIS software instead.
```r
landsatviewer::view_landsat(
  p = 26,
  r = 27,
  date = 20190926,
  open_rasts = FALSE
)
```

A map will open in your web browser or in the plot viewer panel if you are using
Rstudio. You can toggle each layer on/off to compare the QA band to clouds
visible in the cirrus band and in the composite false color image.
