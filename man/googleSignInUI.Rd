% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/googleSignIn.R
\name{googleSignInUI}
\alias{googleSignInUI}
\title{User interface for a Sign In With Google module}
\usage{
googleSignInUI(id, options = list())
}
\arguments{
\item{id}{An ID string that corresponds with the ID used to call the module's
UI function.}

\item{options}{A list of customization options for the included
\code{\link[=googleSignInButton]{googleSignInButton()}}.}
}
\description{
Creates a "Sign in with Google" button in the UI that links the
authentication response to the server side \code{\link[=googleSignInServer]{googleSignInServer()}}.
To render and function properly, you must call \code{\link[=useGoogleSignIn]{useGoogleSignIn()}}
somewhere in your UI code.
}
\details{
Note that while you \emph{can} have several sign in UIs in the app, whenever new
authentication information is received it gets passed to \strong{all} the sign in
module inputs in the app.
}
\seealso{
\code{\link[=googleSignInButton]{googleSignInButton()}} for details on the included button.

Other module functions: 
\code{\link{googleSignInServer}()},
\code{\link{useGoogleSignIn}()}
}
\concept{module functions}
