function shinygsiHandleGoogleSignIn(response) {
  shinygsiSetAllGoogleSignInInputValues(response.credential);
}

function shinygsiHandleGoogleSignOut() {
  // Prevent possible automatic sign-in loop
  google.accounts.id.disableAutoSelect();
  shinygsiSetAllGoogleSignInInputValues(null);
}

function shinygsiSetAllGoogleSignInInputValues(value) {
  $(".g_id_signin").each((_, btn) => Shiny.setInputValue(btn.id, value));
}

// Sign out with clicks on sign-out elements
$(document).on("click", ".g_id_signout", () => {
  $(document).trigger("shinygsi:signout");
});

// Sign out with message from R session
Shiny.addCustomMessageHandler("shinygsi:signout", (message) => {
  $(document).trigger("shinygsi:signout");
});

// Handle JS sign-out event -- actually sign out.
$(document).on("shinygsi:signout", () => shinygsiHandleGoogleSignOut());
