
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

First, you'll need to [obtain a Google API client ID](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid). Once you have one, explore the included demo app to see what you get and how the pieces fit together: 

``` r
library(shinygsi)

googleSignInApp("<YOUR-CLIENT-ID-HERE>")
```
