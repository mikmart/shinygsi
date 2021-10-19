library(shiny)

testServer(googleSignInServer, {
  test_that("returns NULL with no input", {
    expect_equal(session$returned(), NULL)
  })

  test_that("claims are retrieved from valid token", {
    claim <- valid_claim()
    session$setInputs(unverified_credential = sign(claim))

    expect_equal(session$returned(), claim)
  })

  test_that("invalid token returns validation error", {
    claim <- valid_claim()
    random_key <- openssl::rsa_keygen()

    session$setInputs(unverified_credential = sign(claim, random_key))
    expect_error(session$returned(), class = "validation")

    claim$exp <- as.double(Sys.time() - 3600)

    session$setInputs(unverified_credential = sign(claim))
    expect_error(session$returned(), class = "validation")
  })
}, args = list(CLIENT_ID, public_keys))
