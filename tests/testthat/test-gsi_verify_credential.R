
# Set-up ------------------------------------------------------------------

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

verify_signed <- function(claim, private_key = private_key_1) {
  jwt <- jose::jwt_encode_sig(claim, private_key)
  gsi_verify_credential(jwt, CLIENT_ID, public_keys)
}


# Tests -------------------------------------------------------------------

test_that("can decode and verify valid tokens", {
  claim <- valid_claim()
  expect_equal(verify_signed(claim, private_key_1), claim)
  expect_equal(verify_signed(claim, private_key_2), claim)
})

test_that("verifying faked token fails", {
  random_private_key <- openssl::rsa_keygen()
  valid_claim() %>%
    verify_signed(random_private_key) %>%
    expect_error(class = "gsi_decode_sig_error")
})

test_that("verifying token from other valid issuers succeeds", {
  claim <- valid_claim()
  claim$iss <- "https://accounts.google.com"
  verify_signed(claim) %>%
    expect_equal(claim)
})

test_that("verifying token from incorrect issuer fails", {
  claim <- valid_claim()
  claim$iss <- "drive.google.com"
  verify_signed(claim) %>%
    expect_error(class = "gsi_invalid_claims_error")
})

test_that("verifying token for unrecognized client fails", {
  claim <- valid_claim()
  claim$aud <- "FAKE-CLIENT.apps.googleusercontent.com"
  verify_signed(claim) %>%
    expect_error(class = "gsi_invalid_claims_error")
})

test_that("verifying expired token fails", {
  claim <- valid_claim()
  claim$exp <- as.double(Sys.time() - 3600)
  verify_signed(claim) %>%
    expect_error(class = "gsi_invalid_claims_error")
})

test_that("can get public keys from the web", {
  skip_if_not_installed("webmockr")
  library(webmockr)

  httr_mock()
  stub_request("get", "https://www.googleapis.com/oauth2/v3/certs") %>%
    to_return(body = list(keys = lapply(public_keys, jose::write_jwk)))

  claim <- valid_claim()
  jwt <- jose::jwt_encode_sig(claim, private_key_1)
  gsi_verify_credential(jwt, CLIENT_ID) %>%
    expect_equal(claim)
})
