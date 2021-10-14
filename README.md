
# shinygsi

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of shinygsi is to make it easy to integrate Sign In With Google in your Shiny app for user authentication via the [Google Identity Services](https://developers.google.com/identity/gsi/web) Sign In API. shinygsi provides a simple Shiny module with the `googleSignInUI()` and `googleSignInServer()` pair, and an additional `useGoogleSignIn()` function to put the JavaScript in place that makes it all work in your app.

In order to use Sign In With Google, you'll need to register your app and [obtain a Google API client ID](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid).

## Installation

shinygsi is not on CRAN. You can install the development version with:

``` r
remotes::install_github("mikmart/shinygsi")
```

## Usage

First, make sure you have [a Google API client ID](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid) to use with your app. Then, normally you need to:

1. Include `useGoogleSignIn()` comewhere in your UI code, with your client ID.
2. Use `googleSignInUI()` to place the "Sign in with Google" button in your UI.
3. Handle the credential decoding and verification with `googleSignInServer()`.

There's also a convenience function `gsi_user_info()` that you can use to parse basic user details from the authentication information returned by `googleSignInServer()`.

## Example

Here's the structure for a simple app putting the pieces together:

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

The above is also included in a demo app that you can run directly:

``` r
googleSignInApp(client_id = "<YOUR-CLIENT-ID-HERE>")
```
