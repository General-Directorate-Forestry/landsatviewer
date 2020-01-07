#' @title Run landsatviewer shiny app
#' @param ... Additional arguments passed to `shiny::runApp`
#' @export
run_app <- function(...) {
  appDir <- system.file("shiny", "landsatviewer", package = "landsatviewer")
  if (appDir == "") {
    stop(
      "Could not find example directory. Try re-installing `landsatviewer`.",
      call. = FALSE
    )
  }

  shiny::runApp(appDir, display.mode = "normal", ...)
}
