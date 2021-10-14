#' Decode and verify an encoded Google ID token
#'
#' @param credential A string containing an encoded Google ID JWT.
#' @param client_ids A character vector of recognized client IDs for your app.
#'
#' @return The decoded JWT payload. Throws an error if verification failed.
#'
#' @seealso [gsi_user_info()] for extracting user details from the decoded JWT.
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/verify-google-id-token>
#'
#' @export
gsi_verify_credential <- function(credential, client_ids) {
  # Check all keys -- the token could be signed with either.
  for (key in google_public_keys()) {
    payload <- tryCatch(
      jose::jwt_decode_sig(credential, key),
      error = identity
    )
    if (!rlang::is_condition(payload)) {
      break
    }
  }

  # Check if decoding or signature verification failed
  if (rlang::is_condition(payload)) {
    abort_verification(payload$message)
  }

  # Check payload conditions
  checks_passed <- c(
    iss = payload$iss %in% paste0(c("", "https://"), "accounts.google.com"),
    aud = payload$aud %in% client_ids,
    exp = payload$exp > Sys.time()
  )

  if (!all(checks_passed)) {
    abort_verification(
      message = "Google ID token payload verification failed.",
      payload = payload,
      checks = checks_passed,
      class = "gsi_payload_error"
    )
  }

  payload
}

abort_verification <- function(..., class = character()) {
  rlang::abort(class = c(class, "gsi_verification_error"), ...)
}


#' Get Google's JWK public key for verifying signatures
#'
#' Get Google's JWK public key via an API call. The result is cached according
#' to the `Cache-Control` header with the [httc] package.
#'
#' @return An OpenSSL RSA public key object. See [openssl::rsa_keygen()].
#' @keywords internal
google_public_keys <- function() {
  response <- httc::GET("https://www.googleapis.com/oauth2/v3/certs")
  json_keys <- httr::content(response, "parsed")$keys
  lapply(json_keys, jose::read_jwk)
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
