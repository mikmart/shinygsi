% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/googleSignIn.R
\name{googleSignInApp}
\alias{googleSignInApp}
\title{A demo Shiny app for using Sign In With Google}
\usage{
googleSignInApp(client_id)
}
\arguments{
\item{client_id}{A string containing the Google API client ID of your app.
See Details for acquiring one.}
}
\description{
A demo Shiny app for using Sign In With Google
}
\section{Client ID}{
In order to use Sign In With Google in Shiny, you need to register a client
in a Google Cloud Platform project and set it up for OAuth use. You can find
details for the process in \href{https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid}{Google's setup guide}.
}

\seealso{
Individual components: \code{\link[=useGoogleSignIn]{useGoogleSignIn()}}, \code{\link[=googleSignInUI]{googleSignInUI()}} and
\code{\link[=googleSignInServer]{googleSignInServer()}}.
}
