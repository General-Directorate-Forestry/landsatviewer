# Load the ggplot2 package which provides
# the 'mpg' dataset.
library(ggplot2)

fluidPage(
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(
      width = 2,
      # Input: Numeric entry for landsat path
      numericInput(
        inputId = "path",
        label = "path:",
        value = NA
      ),

      # Input: Numeric entry for landsat row
      numericInput(
        inputId = "row",
        label = "row",
        value = NA
      ),

      # Input: Date entry for scene year
      numericInput(
        inputId = "year",
        label = "year",
        value = NA
      ),

      # Input: Date entry for scene month
      numericInput(
        inputId = "month",
        label = "month",
        value = NA
      ),

      # Input: Date entry for scene day
      numericInput(
        inputId = "day",
        label = "day",
        value = NA
      ),

      actionButton("update", "Update"),

      actionButton("view_map", "View Map")
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      tabsetPanel(
        type = "tabs",
        tabPanel(
          "Scene Selection",
          DT::dataTableOutput("table")
        ),
        tabPanel(
          "Map",
          leaflet::leafletOutput("scene_map", height = 500)
        )
      )

    )
  )
)
