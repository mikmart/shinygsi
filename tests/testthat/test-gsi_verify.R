test_that("can decode and verify valid tokens", {
  claim <- valid_claim()
  verify(sign(claim, private_key_1)) %>% expect_equal(claim)
  verify(sign(claim, private_key_2)) %>% expect_equal(claim)
})

test_that("verifying faked token fails", {
  random_private_key <- openssl::rsa_keygen()
  verify(sign(valid_claim(), random_private_key)) %>%
    expect_error(class = "gsi_decode_sig_error")
})

test_that("verifying token from other valid issuers succeeds", {
  claim <- valid_claim()
  claim$iss <- "https://accounts.google.com"
  verify(sign(claim)) %>%
    expect_equal(claim)
})

test_that("verifying token from incorrect issuer fails", {
  claim <- valid_claim()

  claim$iss <- "drive.google.com"
  verify(sign(claim)) %>%
    expect_error(class = "gsi_invalid_claims_error")

  claim$iss <- NULL
  verify(sign(claim)) %>%
    expect_error(class = "gsi_invalid_claims_error")
})

test_that("verifying token for unrecognized client fails", {
  claim <- valid_claim()

  claim$aud <- "FAKE-CLIENT.apps.googleusercontent.com"
  verify(sign(claim)) %>%
    expect_error(class = "gsi_invalid_claims_error")

  claim$aud <- NULL
  verify(sign(claim)) %>%
    expect_error(class = "gsi_invalid_claims_error")
})

test_that("verifying expired token fails", {
  claim <- valid_claim()

  claim$exp <- as.double(Sys.time() - 3600)
  verify(sign(claim)) %>%
    expect_error(class = "gsi_invalid_claims_error")

  claim$exp <- NULL
  verify(sign(claim)) %>%
    expect_error(class = "gsi_invalid_claims_error")
})

test_that("can get public keys from the web", {
  library(webmockr)

  httr_mock()
  stub_request("get", "https://www.googleapis.com/oauth2/v3/certs") %>%
    to_return(body = list(keys = lapply(public_keys, jose::write_jwk)))

  claim <- valid_claim()
  gsi_verifier(CLIENT_ID) %>%
    gsi_verify(sign(claim)) %>%
    expect_equal(claim)
})
