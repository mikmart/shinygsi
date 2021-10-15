#' Decode and verify an encoded Google ID token
#'
#' @param credential A string with an encoded Google ID [JWT](https://jwt.io).
#' @param client_ids A character vector of client IDs your app recognizes.
#' @param public_keys A list of public keys tried to verify the `credential`
#'   signature. Objects, or paths to read with [openssl::read_pubkey()]. If
#'   left `NULL`, fetch Google's current public keys from their API.
#'
#' @return The decoded JWT payload. Signals an error if verification failed.
#'
#' @seealso [gsi_user_info()] for extracting user details from the decoded JWT.
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/verify-google-id-token>
#'
#' @importFrom rlang %||%
#' @export
gsi_verify_credential <- function(credential, client_ids, public_keys = NULL) {
  public_keys <- public_keys %||% google_public_keys()

  # Decode, and try to verify with all keys -- could be signed with any.
  for (key in public_keys) {
    payload <- tryCatch(
      rlang::with_abort(
        jose::jwt_decode_sig(credential, key)
      ),
      error = identity
    )

    # Don't need to check others if one succeeded
    if (!rlang::is_condition(payload)) break
  }

  if (rlang::is_condition(payload)) {
    abort_verification(
      message = "Decoding or signature verification failed.",
      parent = payload,
      class = "gsi_decode_sig_error"
    )
  }

  # Check if payload fulfills conditions
  checks_passed <- c(
    iss = payload$iss %in% paste0(c("", "https://"), "accounts.google.com"),
    aud = payload$aud %in% client_ids,
    exp = payload$exp > Sys.time()
  )

  if (!all(checks_passed)) {
    abort_verification(
      message = "Payload checks failed.",
      data = list(
        payload = payload,
        checks = checks_passed
      ),
      class = "gsi_payload_error"
    )
  }

  payload
}

abort_verification <- function(message, ..., class = character()) {
  rlang::abort(message, ..., class = c(class, "gsi_verification_error"))
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
