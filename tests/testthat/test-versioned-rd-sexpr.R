library(testthat)

write_rd_sexpr_pkg <- function(pkg.path, rd_helper_body, use_sexpr=FALSE){
  dir.create(file.path(pkg.path, "R"), recursive=TRUE)
  dir.create(file.path(pkg.path, "man"), recursive=TRUE)
  writeLines(c(
    "Package: rd.pkg",
    "Title: Rd Sexpr regression package",
    "Version: 1.0.0",
    "Description: Test package for versioned Rd Sexpr installs.",
    "License: GPL-3"
  ), file.path(pkg.path, "DESCRIPTION"))
  writeLines(c(
    "export(my_fun)",
    "export(rd_helper)"
  ), file.path(pkg.path, "NAMESPACE"))
  writeLines(c(
    "my_fun <- function(x) x + 1",
    paste0("rd_helper <- function() ", rd_helper_body)
  ), file.path(pkg.path, "R", "functions.R"))
  details_lines <- if(use_sexpr){
    c(
      "\\details{",
      "  \\Sexpr[results=rd,stage=build]{rd.pkg:::rd_helper()}",
      "}")
  }else{
    "\\details{No build-stage Sexpr.}"
  }
  writeLines(c(
    "\\name{my_fun}",
    "\\alias{my_fun}",
    "\\title{Test Function}",
    "\\description{Uses build-stage Sexpr.}",
    "\\usage{my_fun(x)}",
    "\\arguments{\\item{x}{Numeric value.}}",
    details_lines,
    "\\value{Input plus one.}"
  ), file.path(pkg.path, "man", "my_fun.Rd"))
}

test_that("versioned install rewrites build-stage Rd package references", {
  tdir <- tempfile()
  dir.create(tdir)
  old.lib <- .libPaths()
  new.lib <- file.path(tdir, "library")
  dir.create(new.lib)
  .libPaths(c(new.lib, old.lib))
  on.exit({
    for(pkg in rev(grep("^rd\\.pkg($|\\.)", loadedNamespaces(), value=TRUE))){
      try(unloadNamespace(pkg), silent=TRUE)
    }
    .libPaths(old.lib)
    unlink(tdir, recursive=TRUE, force=TRUE)
  }, add=TRUE)
  current.path <- file.path(tdir, "current")
  write_rd_sexpr_pkg(current.path, 'stop("wrong package version")')
  R.bin <- file.path(R.home("bin"), "R")
  install.status <- system2(
    R.bin,
    c("CMD", "INSTALL", "-l", shQuote(new.lib), shQuote(current.path)),
    stdout=FALSE, stderr=FALSE)
  expect_equal(install.status, 0)
  expect_error(
    get("rd_helper", envir=asNamespace("rd.pkg"))(),
    "wrong package version",
    fixed=TRUE)
  pkg.path <- file.path(tdir, "rdpkg")
  write_rd_sexpr_pkg(pkg.path, '"\\\\code{historical}"', use_sexpr=TRUE)
  git2r::init(pkg.path)
  repo <- git2r::repository(pkg.path)
  git2r::add(repo, c("DESCRIPTION", "NAMESPACE", "R/functions.R", "man/my_fun.Rd"))
  if(is.null(git2r::default_signature(repo))){
    git2r::config(repo, user.name="test", user.email="test@test.com")
  }
  git2r::commit(repo, "historical commit")
  sha <- git2r::revparse_single(repo, "HEAD")$sha
  result <- NULL
  expect_no_error({
    result <- atime::atime_versions(
      pkg.path=pkg.path,
      N=c(1, 2),
      setup={x <- N},
      expr=rd.pkg::my_fun(x),
      test.sha=sha,
      times=1,
      seconds.limit=1)
  })
  expect_s3_class(result, "atime")
  installed <- list.dirs(new.lib, full.names=FALSE, recursive=FALSE)
  versioned.package <- sprintf("rd.pkg.%s", sha)
  expect_length(installed[installed == versioned.package], 1)
})
