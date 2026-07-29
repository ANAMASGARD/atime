\name{glob_find_replace}
\alias{glob_find_replace}
\title{Find and replace within files}
\description{Find and replace for every file specified by glob.}
\usage{glob_find_replace(glob, FIND, REPLACE, warn=TRUE, fixed=FALSE)}
\arguments{
  \item{glob}{character string: glob defining files.}
  \item{FIND}{character string: pattern to find (regex unless
    \code{fixed=TRUE}).}
  \item{REPLACE}{character string: replacement (regex unless
    \code{fixed=TRUE}).}
  \item{warn}{logical (default \code{TRUE}): warn if nothing replaced.}
  \item{fixed}{logical (default \code{FALSE}): treat \code{FIND} and
    \code{REPLACE} as literal strings?}
}
\value{nothing.}

\author{Toby Dylan Hocking}

\examples{

## see vignette("data.table", package="atime")

}
