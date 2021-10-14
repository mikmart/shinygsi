#' Decode and verify an encoded Google ID token
#'
#' @param credential A string containing an encoded Google ID JWT.
#' @param client_ids A character vector of recognized client IDs for your app.
#'
#' @return `NULL` if verification failed, otherwise the decoded JWT payload.
#'
#' @seealso [gsi_user_info()] for extracting user details from the decoded JWT.
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/verify-google-id-token>
#'
#' @export
gsi_verify_credential <- function(credential, client_ids) {
  credential <- tryCatch(
    jose::jwt_decode_sig(credential, google_public_key()),
    error = function(e) NULL
  )

  # Decoding or signature verification failed
  if (is.null(credential)) return(NULL)

  conditions_met <- c(
    credential$iss %in% paste0(c("", "https://"), "accounts.google.com"),
    credential$aud %in% client_ids,
    credential$exp > Sys.time()
  )

  # Could emit check results to a log in the future
  if (!all(conditions_met)) NULL else credential
}

#' Get Google's JWK public key for verifying signatures
#'
#' Get Google's JWK public key via an API call. The result is cached according
#' to the `Cache-Control` header with the [httc] package.
#'
#' @return An OpenSSL RSA public key object. See [openssl::rsa_keygen()].
#' @keywords internal
google_public_key <- function() {
  response <- httc::GET("https://www.googleapis.com/oauth2/v3/certs")
  json_key <- httr::content(response, "parsed")$keys[[1]]
  jose::read_jwk(json_key)
}

#' Get user details from a Google ID token
#'
#' @param credential A list containing a decoded Google ID token.
#'
#' @return A list with fields describing basic user data for the Google user, or
#'   `NULL` if given a `NULL` value as `credential`.
#'
#' @seealso `gsi_verify_credential()` for decoding and verifying an encoded
#'   Google ID JWT.
#'
#' @export
gsi_user_info <- function(credential) {
  if (is.null(credential)) {
    NULL
  } else {
    list(
      user_id = credential$sub,
      email = credential$email,
      email_verified = credential$email_verified,
      full_name = credential$name,
      given_name = credential$given_name,
      family_name = credential$family_name,
      picture_url = credential$picture
    )
  }
}
