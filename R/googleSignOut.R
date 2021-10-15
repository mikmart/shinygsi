#' Use an HTML element for Google sign-out
#'
#' Clicks on marked elements will trigger a Google sign-out.
#'
#' A sign-out will clear all `googleSignInButton()` inputs, and prevent
#' automatic sign-in from happening afterwards.
#'
#' @param tag An [htmltools::tag] object.
#'
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/automatic-sign-in-sign-out#sign-out>
#'
#' @family sign-out methods
#' @examples
#' library(shiny)
#'
#' # Use a regular action button to trigger a sign out
#' asGoogleSignOut(actionButton("sign_out", "Sign out"))
#' @export
asGoogleSignOut <- function(tag) {
  tagAppendAttributes(tag, class = "g_id_signout")
}

#' Trigger a Google sign-out from server-side
#'
#' @inherit asGoogleSignOut details
#'
#' @param session The `shiny::session` object.
#'
#' @family sign-out methods
#' @export
sendGoogleSignOut <- function(session = getDefaultReactiveDomain()) {
  session$sendCustomMessage("shinygsi:signout", NA)
}
