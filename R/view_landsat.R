#' @title Preview Landsat 8 images with `mapview`
#' @description For a specified scene create a `mapview` interactive map with a
#' false color composite image (bands 5, 4, 3), the cirrus band (band 9), and
#' the QA band
#'
#' @param p landsat path (integer)
#' @param r landsat row (integer)
#' @param date image date formatted as YYYYMMDD
#' @param scene dataframe containing one row from `get_scene_table()`. This can
#' be used instead of `p`, `r`, and `date`.
#'
#' @return `mapview` interactive map
#' @importFrom magrittr %>%
#' @export

view_landsat <- function(p = NULL, r = NULL, date = NULL,
                         scene = NULL, open_rasts = FALSE) {

  if (is.null(scene) | (is.null(p) & is.null(r) & is.null(date))) {
    stop("you must specifiy either a row from get_scene_table() or a path/row/date combo")
  }

  if (is.null(scene)) {
    all_scenes <- get_scene_table()

    scenes <- all_scenes %>%
      dplyr::filter(path == p, row == r) %>%
      dplyr::mutate(acquisitionDate = lubridate::as_date(acquisitionDate))

    # filter down to specified date
    scene <- scenes %>%
      dplyr::filter(
        acquisitionDate == lubridate::ymd(date)
      )
  }

  if (nrow(scene) == 0) {
    stop("no matching scenes found in s3://landsat-pds")
  }

  # take T1 not RT if available
  if (nrow(scene) > 1) {
    scene <- scene %>%
      dplyr::filter(stringr::str_detect(string = productId, pattern = "T1")) %>%
      dplyr::distinct()
  }

  # get urls for the bands that we want
  imgs <- c("B5.TIF", "B4.TIF", "B3.TIF", "B2.TIF", "B9.TIF", "BQA.TIF")
  urls <- glue::glue("{dirname(scene$download_url)}/{scene$productId}_{imgs}")
  tempfiles <- file.path(
    tempdir(),
    basename(urls)
  )

  message("downloading rasters")
  downloaded <- purrr::map2(
    .x = urls,
    .y = tempfiles,
    .f = ~ download.file(
      url = .x,
      destfile = .y
    )
  )

  if (open_rasts) {
    # build false color tif
    false_file <- file.path(
      tempdir(),
      glue::glue(
        "{scene$productId}_false_color.tif"
      )
    )

    false_color_tifs <- glue::glue_collapse(
      tempfiles[imgs %in% c("B5.TIF", "B4.TIF", "B3.TIF")],
      sep = " "
    )

    merge_rasts(out_file = false_file, in_files = false_color_tifs)

    # build true color rast
    true_file <- file.path(
      tempdir(),
      glue::glue(
        "{scene$productId}_true_color.tif"
      )
    )

    true_color_tifs <- glue::glue_collapse(
      tempfiles[imgs %in% c("B4.TIF", "B3.TIF", "B2.TIF")],
      sep = " "
    )

    merge_rasts(out_file = true_file, in_files = true_color_tifs)

    # cirrus and QA bands
    cirrus_band <- tempfiles[imgs == "B9.TIF"]
    qa_band <- tempfiles[imgs == "BQA.TIF"]

    cirrus_band_resamp <- resample_raster(
      file = cirrus_band,
      a_nodata = 0,
      tr = 60
    )
    qa_band_resamp <- resample_raster(
      file = qa_band,
      a_nodata = 1,
      tr = 60
    )

    system2(
      "open",
      c(cirrus_band_resamp, qa_band_resamp, false_file, true_file)
    )


    return("opening rasters in system viewer")
  }

  rast <- raster::stack(tempfiles)

  raster::NAvalue(rast) <- 0

  # fire up mapview
  mapview::mapviewOptions(
    raster.palette = viridisLite::viridis,
    na.color = "#00000000"
  )

  # print false color map
  composite <- mapview::viewRGB(
    rast,
    r = 1, g = 2, b = 3,
    layer.name = "false color",
    alpha.regions = 1
  )

  # print QA band
  raster::NAvalue(rast[[6]]) <- 1
  raster::values(rast[[6]]) <- factor(
    as.character(raster::values(rast[[6]]))
  )

  qa <- mapview::mapview(
    rast[[6]],
    layer.name = "QA band"
  )

  # print cirrus band
  cirrus <- mapview::mapview(
    rast[[5]],
    layer.name = "cirrus band",
    alpha.regions = 1
  )

  # combine
  qa + cirrus + composite

}

#' @title Generate table of Landsat scenes
#'
#' @return data.frame containing Landsat scene attributes from
#' "https://landsat-pds.s3.amazonaws.com/c1/L8/scene_list.gz"
#' @export
#'

get_scene_table <- function() {
  scene_url <- "https://landsat-pds.s3.amazonaws.com/c1/L8/scene_list.gz"

  scene_file <- file.path(
    tempdir(),
    basename(scene_url)
  )

  if (!file.exists(scene_file)) {
    message("downloading list of scenes")
    utils::download.file(
      scene_url,
      destfile = scene_file
    )
  }

  out <-
    vroom::vroom(
      scene_file,
      delim = ","
    ) %>%
    dplyr::mutate(
      acquisitionDate = lubridate::as_date(acquisitionDate)
    )

  return(out)
}


#' @title Build multiband raster from several .tifs
#'
#' @param out_file file path to .tif file to be created
#' @param in_files file paths of .tif files to be added to .vrt
#'
#' @return file path to output file

merge_rasts <- function(out_file, in_files) {
  gdal_merge.py <- system("which gdal_merge.py", intern = TRUE)
  merge_cmd <- glue::glue(
    "{gdal_merge.py} -separate -n 0 -a_nodata 0 -ps 60 60 -co COMPRESS=LZW -o {out_file} {in_files}"
  )
  system(merge_cmd)

  if (! file.exists(out_file)) {
    stop("there was an error creating multiband raster")
  }

  return(out_file)
}

#' @title Build multiband raster from several .tifs
#'
#' @param file file path to .tif file to be resampled
#' @param a_nodata nodata value for output raster
#' @param tr target resolution
#'
#' @return file path to output .tif file

resample_raster <- function(file, a_nodata, tr) {
  out_file <- stringr::str_replace(file, ".TIF", "_update.TIF")

  cmd <- glue::glue(
    "gdal_translate -a_nodata {a_nodata} -tr {tr} {tr} {file} {out_file}"
  )

  system(cmd)

  return(out_file)
}
