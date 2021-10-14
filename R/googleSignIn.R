#' Set up a Shiny app to use Sign In With Google
#'
#' Call this function at least once in your Shiny app UI to set up the necessary
#' elements for Sign In With Google to work.
#'
#' @param client_id A string containing the client ID of your Google web app.
#'   See Details for acquiring one.
#' @param auto_prompt Logical. Should the Google One Tap prompt be displayed?
#'
#' @details # Client ID
#' In order to use Sign In With Google in Shiny, you need to register a client
#' in a Google Cloud Platform project and set it up for OAuth use. Google
#' provides details for the setup steps
#' (<https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid>).
#'
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/display-button#html>
#' * <https://developers.google.com/identity/gsi/web/reference/html-reference#element_with_id_g_id_onload>
#'
#' @family module functions
#' @export
useGoogleSignIn <- function(client_id, auto_prompt = TRUE) {
  singleton(
    tagList(
      tags$head(
        tags$script(src = "https://accounts.google.com/gsi/client", defer = "true"),
        includeScript(system.file("js/shinygsi.js", package = "shinygsi")),
      ),
      div(
        id = "g_id_onload",
        `data-client_id` = client_id,
        `data-callback` = "handleGoogleSignInCredentialResponse",
        `data-auto_prompt` = tolower(auto_prompt)
      ),
    )
  )
}

#' Create HTML for a Sign In With Google button
#'
#' Creates the HTML element for displaying a Sign In With Google button. Most of
#' the time you probably don't want to use this directly, but through the
#' `googleSignInUI()` module instead.
#'
#' The given `inputId` receives the encoded Google ID JWT value. Most of the
#' time you may want to use `googleSignInUI()` paired with the server module
#' `googleSignInServer()` instead to decode and verify the token.
#'
#' Note that while you _can_ have several buttons in an app, whenever new
#' authentication information is received it gets passed to **all** the
#' `googleSignInButton()` inputs in the app.
#'
#' @param inputId The `input` slot that authentication information will be
#'   available in. See Details.
#' @param options A list of customization options to control the appearance of
#'   the button. The names will be automatically prepended with `"data-"`.
#'   See Examples for usage and [Google's
#'   reference](https://developers.google.com/identity/gsi/web/reference/html-reference#element_with_class_g_id_signin)
#'    for possible values.
#'
#' @seealso You might instead want [googleSignInUI()] to use the full module.
#'
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/personalized-button>
#' * <https://developers.google.com/identity/gsi/web/guides/display-button#html>
#' * <https://developers.google.com/identity/gsi/web/reference/html-reference#element_with_class_g_id_signin>
#'
#' @examples
#' # Customizing the appearance
#' googleSignInButton(
#'   inputId = "google_jwt",
#'   options = list(
#'     theme = "filled_blue",
#'     shape = "pill",
#'     text = "continue_with"
#'   )
#' )
#'
#' @export
googleSignInButton <- function(inputId, options = list()) {
  if (!is.null(names(options))) {
    names(options) <- paste0("data-", names(options))
  }
  div(id = inputId, class = "g_id_signin", !!!options)
}

#' User interface for a Sign In With Google module
#'
#' Creates a "Sign in with Google" button in the UI that links the
#' authentication response to the server side [googleSignInServer()].
#' To render and function properly, you must call [useGoogleSignIn()]
#' somewhere in your UI code.
#'
#' @inheritParams shiny::moduleServer
#' @param options A list of customization options for the included
#'   [googleSignInButton()].
#'
#' @details Note that while you _can_ have several sign in UIs in the app,
#'   whenever new authentication information is received it gets passed to
#'   **all** the sign in module inputs in the app.
#'
#' @seealso [googleSignInButton()] for details on the included button.
#'
#' @family module functions
#' @export
googleSignInUI <- function(id, options = list()) {
  ns <- NS(id)
  tagList(
    googleSignInButton(ns("unverified_credential"), options),
  )
}

#' Server side for a Sign In With Google module
#'
#' Handles decoding and verification of the authentication response received
#' from the linked UI part, `googleSignInUI()`. Provides a reactive return value
#' containing a list with the verified Google ID token's payload, or `NULL`.
#'
#' The server module decodes and verifies the encoded Google ID JWT received
#' from the UI module upon succesful completion of the authentication flow. See
#' [gsi_verify_credential()] for details about the verification process.
#'
#' @inheritParams shiny::moduleServer
#' @inheritParams gsi_verify_credential
#'
#' @seealso [gsi_user_info()] for extracting user details from the return value.
#'
#' @family module functions
#' @export
googleSignInServer <- function(id, client_ids) {
  stopifnot(!is.reactive(client_ids))

  moduleServer(id, function(input, output, session) {
    verified_credential <- reactive({
      credential <- input$unverified_credential
      if (!is.null(credential)) {
        gsi_verify_credential(
          credential = credential,
          client_ids = client_ids
        )
      }
    })

    verified_credential
  })
}

#' A demo Shiny app for using Sign In With Google
#'
#' @inheritParams useGoogleSignIn
#'
#' @seealso Individual components: [useGoogleSignIn()], [googleSignInUI()] and
#'   [googleSignInServer()].
#'
#' @inheritSection useGoogleSignIn Client ID
#' @importFrom utils str
#' @export
googleSignInApp <- function(client_id) {
  ui <- fluidPage(
    useGoogleSignIn(client_id = client_id),
    googleSignInUI("auth"),
    verbatimTextOutput("user_info"),
  )

  server <- function(input, output, session) {
    auth <- googleSignInServer("auth", client_id)
    user_info <- reactive({ gsi_user_info(auth()) })
    output$user_info <- renderPrint(str(user_info()))
  }

  shinyApp(ui, server)
}
