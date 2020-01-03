# landsatviewer

## Install
At this time you must install `landsatviewer` via GitHub.
```r
devtools::install_github("SilviaTerra/landsatviewer")
```

## Usage
The main function is `view_landsat` which will create an interactive map with
a false color composite image using bands 5, 4, and 3 from the specified landsat
scene, the QA band, and the cirrus band (band 9).

To create a map just provide the path (`p`), row (`r`), and date (`date`) to
`view_landsat`:
```r
landsatviewer::view_landsat(
  p = 26,
  r = 27,
  date = 20190926
)
```

A map will open in your web browser or in the plot viewer panel if you are using
Rstudio. You can toggle each layer on/off to compare the QA band to clouds
visible in the cirrus band and in the composite false color image.
