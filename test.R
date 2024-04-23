library(rcmdcheck)
library(remotes)
library(tinytex)

if (length(tinytex::tl_pkgs()) == 0) {
  tinytex::install_tinytex(bundle = "TinyTeX")
}

if (length(tinytex::tl_pkgs()) <= 104) {
  tinytex::install_tinytex(bundle = "TinyTeX", force = TRUE)
}

options(pak.no_extra_messages = TRUE)
library(pak)

myrepo = "https://cran.r-project.org/"
options(repos = c(CRAN = myrepo))
options(repos = BiocManager::repositories())

av_packages <- as.data.frame(available.packages())

testing_packages = c("knitr", "dplyr", "testthat")

packages <- c("clustermq")

deps_testing <- unique(c(packages, unlist(
  tools::package_dependencies(
    packages,
    which = c("Imports", "LinkingTo"),
    recursive = TRUE
  )
)))

deps_install <-
  unique(unlist(tools::package_dependencies(
    c(deps_testing, packages),
    which = c("Imports", "LinkingTo", "Suggests", "Enhances")
  )))

deps_install <-
  unique(c(
    packages,
    testing_packages,
    unlist(tools::package_dependencies(
      c(deps_testing, packages), which = c("Imports", "LinkingTo")
    ))
  ))

deps_install <-
  paste0(av_packages[av_packages$Package %in% deps_install,]$Package, "@", 
            av_packages[av_packages$Package %in% deps_install,]$Version)

deps_testing <-
  paste0(av_packages[av_packages$Package %in% deps_testing,]$Package, "@", 
            av_packages[av_packages$Package %in% deps_testing,]$Version)

#.libPaths("/tmp/libs")
callr::r_vanilla(
  pak::pkg_install(deps_install, "./libs"),
  repos = options()$repos,
  libPath = "./libs"
)

pk <-
  pak::pkg_download(deps_testing, dest_dir = "pkgs", platform = "source")


libpath = paste0(getwd(), "/libs")
#for (i in seq(nrow(pk))) {

for (i in 2) {
  print(pk[["package"]][[i]])
  
  rcmdcheck::rcmdcheck(
    path = pk$fulltarget[[i]],
    libpath = libpath,
    quiet = FALSE,
    env = c("_R_CHECK_FORCE_SUGGESTS_" = 0)
  )
}
