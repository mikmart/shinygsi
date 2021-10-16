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
    exp = isTRUE(payload$exp > Sys.time())
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

#' Get Google's JWK public key
#'
#' Get Google's JWK public key via an API call. The result is cached according
#' to the `Cache-Control` header. Used to verify JWT signatures.
#'
#' @return An OpenSSL RSA public key object. See [openssl::rsa_keygen()].
#' @keywords internal
google_public_keys <- function(cache = getOption("shinygsi.cache")) {
  handle_keys_response <- function(response) {
    lapply(httr::content(response)$keys, jose::read_jwk)
  }

  cached_result <- cache$get("google_public_keys")
  cached_response <- attr(cached_result, "response")

  if (cachem::is.key_missing(cached_result)) {
    response <- httr::GET("https://www.googleapis.com/oauth2/v3/certs")
  } else {
    response <- httr::rerequest(cached_response)
  }

  if (identical(response, cached_response)) {
    result <- cached_result
  } else {
    result <- handle_keys_response(response)
    cache$set("google_public_keys", http_cache_item(result, response))
  }

  result
}

http_cache_item <- function(x, response) {
  structure(x, response = response, class = c("http_cache_item", class(x)))
}


#' Get user details from a Google ID token
#'
#' @param credential A list containing a decoded Google ID token.
#'
#' @return A list with fields describing basic user data for the Google user, or
#'   `NULL` if `credential` is `NULL`. Included fields are:
#'
#'    * `user_id` A string with Google's unique user ID.
#'    * `email` User's current email address.
#'    * `email_verified` Logical. Has the email address been verified?
#'    * `full_name` User's current full name.
#'    * `given_name` User's current given name.
#'    * `family_name` User's current family name.
#'    * `picture_url` A URL to get the user's current profile picture.
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
