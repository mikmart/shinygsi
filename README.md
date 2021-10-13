
# shinygsi

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of shinygsi is to make it easy to integrate Sign In With Google with your Shiny app for user authentication. It uses the newer [Google Identity Services](https://developers.google.com/identity/gsi/web) Sign In API.

## Installation

shinygsi is not on CRAN. You can install the development version with:

``` r
remotes::install_github("mikmart/shinygsi")
```

## Example

First, you'll need to [obtain a Google API client ID](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid). Once you have one, you can start building your app with users authenticated via Google. Here's the basic building blocks for setting up Sign In With Google:

``` r
library(shiny)
library(shinygsi)

GAPI_CLIENT_ID <- "<YOUR-CLIENT-ID-HERE>"

ui <- fluidPage(
  useGoogleSignIn(client_id = GAPI_CLIENT_ID),
  googleSignInUI("auth"),
  verbatimTextOutput("user_info"),
)

server <- function(input, output, session) {
  auth <- googleSignInServer("auth", GAPI_CLIENT_ID)
  user_info <- reactive({ gsi_user_info(auth()) })
  output$user_info <- renderPrint(str(user_info()))
}

shinyApp(ui, server)
```

There's also an included demo app that you can run directly:

``` r
googleSignInApp(client_id = "<YOUR-CLIENT-ID-HERE>")
```
