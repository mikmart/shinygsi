test_that("sign in button has correct HTML class", {
  btn <- googleSignInButton("btn")
  expect_equal(tagGetAttribute(btn, "class"), "g_id_signin")
})

test_that("options are passed correctly to HTML", {
  btn <- googleSignInButton("btn", options = list(shape = "pill"))
  expect_equal(tagGetAttribute(btn, "data-shape"), "pill")
})
