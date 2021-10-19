CLIENT_ID <- "REAL-CLIENT.apps.googleusercontent.com"

private_keys <- list(
  private_key_1 <- openssl::rsa_keygen(),
  private_key_2 <- openssl::rsa_keygen()
)

public_keys <- lapply(private_keys, function(key) key$pubkey)

valid_claim <- function() {
  jose::jwt_claim(
    iss = "accounts.google.com",
    aud = CLIENT_ID,
    exp = as.double(Sys.time() + 3600)
  )
}

sign <- function(claim, key = NULL) {
  jose::jwt_encode_sig(claim, key %||% private_keys[[1]])
}

verify <- function(token) {
  gsi_verify(gsi_verifier(CLIENT_ID, public_keys), token)
}
