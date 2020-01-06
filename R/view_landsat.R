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

view_landsat <- function(p = NULL, r = NULL, date = NULL, scene = NULL) {

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
  imgs <- c("B5.TIF", "B4.TIF", "B3.TIF", "B9.TIF", "BQA.TIF")
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
  raster::NAvalue(rast[[5]]) <- 1
  raster::values(rast[[5]]) <- factor(
    as.character(raster::values(rast[[5]]))
  )

  qa <- mapview::mapview(
    rast[[5]],
    layer.name = "QA band"
  )

  # print cirrus band
  cirrus <- mapview::mapview(
    rast[[4]],
    layer.name = "cirrus band",
    alpha.regions = 1
  )

  # combine
  qa + cirrus + composite

}

#' Generate table of Landsat scenes
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
