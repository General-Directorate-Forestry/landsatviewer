library(dplyr)

function(input, output) {
  all_scenes <- landsatviewer::get_scene_table() %>%
    mutate(
      year = lubridate::year(acquisitionDate),
      month = lubridate::month(acquisitionDate),
      day = lubridate::day(acquisitionDate)
    )

  scene_tab <- eventReactive(
    input$update, {
      out <- all_scenes
      if (!is.na(input$path)) {
        out <- out[out$path == input$path, ]
      }
      if (!is.na(input$row)) {
        out <- out[out$row == input$row, ]
      }
      if (!is.na(input$year)) {
        out <- out[out$year == input$year, ]
      }
      if (!is.na(input$month)) {
        out <- out[out$month == input$month, ]
      }
      if (!is.na(input$day)) {
        out <- out[out$day == input$day, ]
      }

      out %>%
        # group_by(path, row, acquisitionDate) %>%
        # mutate(
        #   priority = case_when(
        #     grepl("T1", productId) ~ 1,
        #     grepl("RT", productId) ~ 2
        #   )
        # ) %>%
        # filter(
        #   priority == min(priority)
        # ) %>%
        # ungroup() %>%
        arrange(desc(acquisitionDate))
    },
    ignoreNULL = FALSE
  )

  output$table <- DT::renderDataTable(
    DT::datatable(
      {
        scene_tab() %>%
          dplyr::mutate(
            thumbnail = glue::glue('<img src="{dirname(download_url)}/{productId}_thumb_small.jpg" height="104"></img')
          ) %>%
          dplyr::select(
            `Scene ID` = productId,
            date = acquisitionDate,
            `Cloud Cover %` = cloudCover,
            thumbnail
          )
      },
      escape = FALSE,
      selection = "single",
      options = list(pageLength = 4)
    )

  )

  # print the selected scene
  # output$selection <- renderPrint({
  #   scenes <- scene_tab()[["productId"]]
  #   scene <- scenes[input$table_rows_selected]
  #   if (length(scene)) {
  #     cat("This scene is selected:\n\n")
  #     cat(scene, sep = ', ')
  #   }
  # })

  map_time <- eventReactive(
    input$view_map, {
      scene_dat <- scene_tab()

      scene_dat[input$table_rows_selected, ]

    },
    ignoreNULL = FALSE
  )
  
  # open rasters if that button is clicked
  observeEvent(
    input$open_rasters, {
      scene_dat <- scene_tab()

      scene <- scene_dat[input$table_rows_selected, ]

      landsatviewer::view_landsat(
        scene = scene,
        open_rasts = TRUE
      )
    }
  )

  output$scene_map <- leaflet::renderLeaflet({
    landsat_map <- landsatviewer::view_landsat(
      scene = map_time()
    )

    landsat_map@map
  })
}
