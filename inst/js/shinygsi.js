function handleGoogleSignInCredentialResponse(response) {
  var signInButtons = document.querySelectorAll('.g_id_signin');
  for (var button of signInButtons) {
    Shiny.onInputChange(button.id, response.credential);
  }
}
