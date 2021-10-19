#' Create a verifier for verifying ID tokens
#'
#' @param client_ids A character vector of client IDs your app recognizes.
#' @param public_keys A list of public keys tried for signature verification,
#'   or a function that returns them. Keys can be objects, or paths to read
#'   with [openssl::read_pubkey()]. If left `NULL`, fetch Google's current
#'   public keys from their API when verifying.
#'
#' @seealso `gsi_verify()` for performing the verification.
#'
#' @examples
#' gsi_verifier()
#' @export
gsi_verifier <- function(client_ids = character(), public_keys = NULL) {
  if (is.function(public_keys)) {
    get_public_keys <- function() public_keys()
  } else if (is.null(public_keys)) {
    get_public_keys <- function() google_public_keys()
  } else {
    get_public_keys <- function() public_keys
  }

  structure(
    list(
      client_ids = client_ids,
      get_public_keys = get_public_keys,
      issuers = paste0(c("", "https://"), "accounts.google.com")
    ),
    class = "gsi_verifier"
  )
}

#' @export
print.gsi_verifier <- function(x, ...) {
  cat("<gsi_verifier>\n")
  str(unclass(x))
  invisible(x)
}


#' Decode and verify an encoded Google ID token
#'
#' @param verifier A verifier object. See `gsi_verifier()`.
#' @param token A string with an encoded Google ID [JWT](https://jwt.io).
#'
#' @return The decoded JWT payload. Signals an error if verification failed.
#'
#' @seealso [gsi_user_info()] for extracting user details from the decoded JWT.
#' @references
#' * <https://developers.google.com/identity/gsi/web/guides/verify-google-id-token>
#'
#' @export
gsi_verify <- function(verifier, token) {
  # Decode token, and verify that it is signed by Google.
  # Check all public keys, as it could be signed with any.
  for (key in verifier$get_public_keys()) {
    claims <- tryCatch(
      rlang::with_abort(
        jose::jwt_decode_sig(token, key)
      ),
      error = identity
    )

    # Stop on success -- others won't work.
    if (!rlang::is_condition(claims)) break
  }

  if (rlang::is_condition(claims)) {
    abort_verification(
      message = "Decoding or signature verification failed.",
      parent = claims,
      class = "gsi_decode_sig_error"
    )
  }

  # Check claims included in the token
  claims_valid <- c(
    # Token is issued by Google Accounts
    iss = claims$iss %in% verifier$issuers,

    # Intended audience includes this app
    aud = any(verifier$client_ids %in% claims$aud),

    # Token has not already expired
    exp = isTRUE(claims$exp > Sys.time())
  )

  if (!all(claims_valid)) {
    abort_verification(
      message = "Token includes invalid claims.",
      data = list(
        invalid_claims = claims[names(which(!claims_valid))]
      ),
      class = "gsi_invalid_claims_error"
    )
  }

  claims
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
  json_keys <- httr::content(response, type = "application/json")$keys
  lapply(json_keys, jose::read_jwk)
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
#' @seealso `gsi_verify()` for decoding and verifying an encoded Google ID JWT.
#'
#' @export
gsi_user_info <- function(credential) {
  if (is.null(credential)) {
    NULL
  } else if (!is.list(credential)) {
    rlang::abort("`credential` must be a list.")
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
