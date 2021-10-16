test_that("returns NULL for NULL input", {
  expect_equal(gsi_user_info(NULL), NULL)
})

test_that("fails if given an encoded credential", {
  expect_error(gsi_user_info("encoded_jwt"), "must be a list")
})
