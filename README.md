
# shinygsi

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/mikmart/shinygsi/workflows/R-CMD-check/badge.svg)](https://github.com/mikmart/shinygsi/actions)
<!-- badges: end -->

The goal of shinygsi is to make it easy to integrate Sign In With Google in your [Shiny](https://cran.r-project.org/package=shiny) app. It uses [Google Identity Services](https://developers.google.com/identity/gsi/web), with features like [a personalized sign-in button](https://developers.google.com/identity/gsi/web/guides/personalized-button), [the Google One Tap prompt](https://developers.google.com/identity/gsi/web/guides/features) and [automatic sign-in](https://developers.google.com/identity/gsi/web/guides/automatic-sign-in-sign-out).

To achieve this, shinygsi provides a simple Shiny module with the `googleSignInUI()` and `googleSignInServer()` pair, and a `useGoogleSignIn()` function to make the JavaScript work.

In order to use Sign In With Google, you'll need to register your app and [obtain a Google API client ID](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid).

## Installation

shinygsi is not on CRAN. You can install the development version with:

``` r
remotes::install_github("mikmart/shinygsi")
```

## Usage

### Sign-in

First, make sure you have [a Google API client ID](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid) to use with your app. Then, normally you need to:

1. Include `useGoogleSignIn()` somewhere in your UI code, with your client ID.
2. Use `googleSignInUI()` to place a "Sign in with Google" button in your UI.
3. Handle credential decoding and verification with `googleSignInServer()`.

You can use `gsi_user_info()` to extract basic user details from the decoded authentication information.

### Sign-out

Signing out clears all `googleSignInButton()` inputs. A sign-out can be triggered in two ways:

* from the server with `sendGoogleSignOut()`, or ...
* from the UI with a click on an element marked with `asGoogleSignOut()`.

If your app has more complex sign-out logic than just clearing user information,
use `sendGoogleSignOut()` in your server-side sign-out code. Otherwise, a UI element marked with `asGoogleSignOut()` will likely suffice.

## Example

Here's the structure for a simple app putting all the pieces together:

``` r
library(shiny)
library(shinygsi)

GAPI_CLIENT_ID <- "<YOUR-CLIENT-ID-HERE>"

ui <- fluidPage(
  useGoogleSignIn(client_id = GAPI_CLIENT_ID),
  googleSignInUI("auth"),
  verbatimTextOutput("user_info"),
  asGoogleSignOut(actionButton("sign_out", "Sign out")),
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
googleSignInApp(client_id = GAPI_CLIENT_ID)
```

## Prior art

* [googleAuthR](https://cran.r-project.org/package=googleAuthR) also offers a [`googleSignIn`](https://code.markedmondson.me/googleAuthR/reference/googleSignIn.html) module, but it uses the [older deprecating JavaScript library](https://developers.googleblog.com/2021/08/gsi-jsweb-deprecation.html).
* [gargle](https://cran.r-project.org/package=gargle) offers more generic tools for working with Google APIs.
