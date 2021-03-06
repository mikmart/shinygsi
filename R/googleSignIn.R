#' Set up a Shiny app to use Sign In With Google
#'
#' Call this function at least once in your Shiny app UI to set up the necessary
#' elements for Sign In With Google to work.
#'
#' # Client ID
#' In order to use Sign In With Google in Shiny, you need to register a client
#' in a Google Cloud Platform project and set it up for OAuth use. You can find
#' details for the process in [Google's setup guide](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid).
#'
#' @param client_id A string containing the Google API client ID of your app.
#'   See Details for acquiring one.
#' @param auto_prompt Logical. Should [the Google One Tap prompt](https://developers.google.com/identity/gsi/web/guides/features) be displayed?
#' @param auto_select Logical. Should [automatic sign-in](https://developers.google.com/identity/gsi/web/guides/automatic-sign-in-sign-out) be enabled?
#'
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/display-button#html>
#' * <https://developers.google.com/identity/gsi/web/reference/html-reference#element_with_id_g_id_onload>
#'
#' @family module functions
#' @export
useGoogleSignIn <- function(client_id, auto_prompt = TRUE, auto_select = TRUE) {
  singleton(
    tagList(
      tags$head(
        tags$script(src = "https://accounts.google.com/gsi/client", defer = "true"),
        includeScript(system.file("js/shinygsi.js", package = "shinygsi")),
      ),
      div(
        id = "g_id_onload",
        `data-client_id` = client_id,
        `data-callback` = "shinygsiHandleGoogleSignIn",
        `data-auto_prompt` = tolower(auto_prompt),
        `data-auto_select` = tolower(auto_select),
      ),
    )
  )
}

#' Create HTML for a Sign In With Google button
#'
#' Creates an HTML element for displaying a Sign In With Google button. Most of
#' the time you probably don't want to use this directly, but through the
#' `googleSignInUI()` module instead.
#'
#' The given `inputId` receives the encoded Google ID [JWT](https://jwt.io)
#' value. Most of the time you probably want `googleSignInUI()` paired with the
#' server module `googleSignInServer()` instead to decode and verify the token.
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
#' @export
googleSignInButton <- function(inputId, options = list()) {
  if (length(names(options)) > 0) {
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
#' Note that while you _can_ have several sign in UIs in the app, whenever new
#' authentication information is received it gets passed to **all** the sign in
#' module inputs in the app.
#'
#' @inheritParams shiny::moduleServer
#' @param options A list of customization options for the included
#'   [googleSignInButton()].
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
#' containing a list with the verified Google ID token's payload.
#'
#' The server module decodes and verifies the encoded Google ID JWT received
#' from the UI module upon succesful completion of the authentication flow. See
#' [gsi_verify()] for details about the verification process.
#'
#' @inheritParams shiny::moduleServer
#' @inheritDotParams gsi_verifier
#'
#' @seealso [gsi_user_info()] for extracting user details from the return value.
#'
#' @family module functions
#' @export
googleSignInServer <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    verifier <- gsi_verifier(...)

    verified_credential <- reactive({
      credential <- input$unverified_credential
      if (is.null(credential)) {
        NULL
      } else {
        payload <- try(gsi_verify(verifier, credential))
        validate(need(payload, "Google ID token verification failed."))
        payload
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
    asGoogleSignOut(actionButton("sign_out", "Sign out")),
  )

  server <- function(input, output, session) {
    auth <- googleSignInServer("auth", client_id)
    user_info <- reactive({ gsi_user_info(auth()) })
    output$user_info <- renderPrint(str(user_info()))
  }

  shinyApp(ui, server)
}
