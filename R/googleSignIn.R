#' Set up a Shiny app to use Sign In With Google
#'
#' Call this function at least once in your Shiny app UI to set up the necessary
#' elements for Sign In With Google to work.
#'
#' @details # Client ID
#' In order to use Sign In With Google in Shiny, you need to register a client
#' in a Google Cloud Platform project and set it up for OAuth use. Google
#' provides details for the setup steps
#' ([https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid]()).
#'
#' @param client_id A string containing the client ID of your Google web app.
#'   See Details for acquiring one.
#' @param auto_prompt Logical. Should the Google One Tap prompt be displayed?
#'
#' @references
#' * [https://developers.google.com/identity/gsi/web/guides/display-button#html]()
#' * [https://developers.google.com/identity/gsi/web/reference/html-reference#element_with_id_g_id_onload]()
useGoogleSignIn <- function(client_id, auto_prompt = TRUE) {
  singleton(tags$head(
    tags$script(src = "https://accounts.google.com/gsi/client", defer = "true"),
    tags$script(HTML("
      function handleGoogleSignInCredentialResponse(response) {
        var signInButton = document.querySelector('.g_id_signin');
        Shiny.onInputChange(signInButton.id, response.credential);
      }
    ")),
    div(
      id = "g_id_onload",
      `data-client_id` = client_id,
      `data-callback` = "handleGoogleSignInCredentialResponse",
      `data-auto_prompt` = tolower(auto_prompt)
    ),
  ))
}

#' HTML for a Sign In With Google button
#'
#' Creates the HTML element for displaying a Sign In With Google button. Most of
#' the time you probably don't want to use this directly, but through the UI
#' module `googleSignInUI()` instead. That allows the server to decode and
#' verify the token received from the authentication process.
#'
#' @param inputId The `input` slot that authentication information will be
#'   available in. Note that while you can have several buttons in an app, the
#'   `inputId` of the first one found will determine the name of the Shiny
#'   `input` where authentication information will be passed.
#' @param options A list of customization options to control the appearance of
#'   the button. `data-` will be automatically appended to the names. See [GSI
#'   reference](https://developers.google.com/identity/gsi/web/reference/html-reference#element_with_class_g_id_signin)
#'    for possible values.
#'
#' @references
#' * [https://developers.google.com/identity/gsi/web/guides/display-button#html]()
#' * [https://developers.google.com/identity/gsi/web/reference/html-reference#element_with_class_g_id_signin]()
#'
#' @export
googleSignInButton <- function(inputId, options = list()) {
  names(options) <- paste0("data-", names(options))
  div(id = inputId, class = "g_id_signin", !!!options)
}

#' User interface for a Sign In With Google module
#'
#' @details While you _can_ include several of these in an app, only the first
#'   one will ever receive input from the sign in button due to the way Sign In
#'   With Google is set up on the JavaScript side.
#'
#' @inheritParams shiny::moduleServer
#' @inheritParams googleSignInButton
#'
#' @seealso [googleSignInServer()] for the module server part.
#'
#' @export
googleSignInUI <- function(id, options = list()) {
  ns <- NS(id)
  tagList(
    googleSignInButton(ns("unverified_credential"), options),
  )
}

#' Server side for a Sign In With Google module
#'
#' The module provides a reactive return value containing a decoded and verified
#' Google ID token, or NULL. See [gsi_verify_credential()] for details.
#'
#' @inheritParams shiny::moduleServer
#' @inheritParams gsi_verify_credential
#'
#' @seealso [googleSignInUI()] for the module UI part.
#'
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

#' A demo app for using Sign In With Google
#'
#' @inheritParams useGoogleSignIn
#'
#' @seealso Individual components: [useGoogleSignIn()], [googleSignInUI()] and
#'   [googleSignInServer()].
#'
#' @inheritSection useGoogleSignIn Client ID
#' @export
googleSignInApp <- function(client_id) {
  ui <- fluidPage(
    useGoogleSignIn(client_id),
    googleSignInUI("auth"),
    verbatimTextOutput("str_auth"),
  )

  server <- function(input, output, session) {
    auth <- googleSignInServer("auth", client_id)
    output$str_auth <- renderPrint(utils::str(auth()))
  }

  shinyApp(ui, server)
}
