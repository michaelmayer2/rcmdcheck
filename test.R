library(rcmdcheck)
library(tinytex)

if (class(try(tinytex::tl_pkgs(),silent=TRUE)) == "try-error") tinytex::install_tinytex()

if (length(tinytex::tl_pkgs()) <= 104) {
  tinytex::install_tinytex(bundle = "TinyTeX", force = TRUE)
}


# We'll install pak into a subdirectory here so it is accessible via the callr process later
if (!dir.exists("./pak/pak")) {
  dir.create("pak")
  callr::r_vanilla(function() install.packages(
    "pak",
    lib=paste0(getwd(),"/pak"),
    repos = sprintf(
      "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
      .Platform$pkgType,
      R.Version()$os,
      R.Version()$arch
    )
  ))
}

options(pak.no_extra_messages = TRUE)
library(pak, lib.loc = "./pak")

pm_make_url <- function(pm_url, repo, snapshot = "latest") {
  paste0(pm_url, repo, ifelse(nchar(snapshot) > 0, paste0("/", snapshot), ""))
}

pm_url = "http://34.241.81.155:4242/"

options(BioC_mirror = pm_make_url(pm_url, "bioconductor", snapshot = ""))
options(BIOCONDUCTOR_CONFIG_FILE = pm_make_url(pm_url, "bioconductor", snapshot =
                                                 "config.yaml"))

validated_repo = "validated-R"
validated_url = pm_make_url(pm_url, validated_repo)
default_repo = "cran"
default_url = pm_make_url(pm_url, default_repo, snapshot = "2024-01-04")

options(repos = c(CRAN = default_url))
options(repos = BiocManager::repositories())

available_packages <- as.data.frame(available.packages())
validated_available_packages <-
  as.data.frame(available.packages(repos = validated_url))

# We take a subset here only - otherwise the compute time would be too much.
packages_to_be_validated <-
  validated_available_packages$Package[10:15]
packages_to_be_validated <- "tidyverse"


deps_testing <- unique(c(
  packages_to_be_validated,
  unlist(
    tools::package_dependencies(
      packages_to_be_validated,
      which = c("Imports", "LinkingTo"),
      recursive = TRUE
    )
  )
))

deps_install <-
  unique(c(
    packages_to_be_validated,
    unlist(tools::package_dependencies(
      c(deps_testing, packages_to_be_validated),
      which = c("Imports", "LinkingTo", "Suggests", "Enhances")
    ))
  ))

# Now we also need to catch all of those dependencies of the "Suggests" and "Enhances" dependencies all the way
deps_install <- 
  unique(c(
    deps_install, 
    unlist(tools::package_dependencies(
      c(deps_install, packages_to_be_validated),
      which = c("Imports", "LinkingTo"),
      recursive = TRUE
    ))
  ))

#Let's filter out the already installed base and recommended packages
filterBaseRecDeps <- function(deps) {
  deps[!deps %in% as.data.frame(installed.packages(lib.loc = paste0(R.home(), "/library")))$Package]
  
}

#deps_testing = filterBaseRecDeps(deps_testing)
#deps_install = filterBaseRecDeps(deps_install)

packageDepsList <- function(deps, av_pack) {
  paste0(av_pack[av_pack$Package %in% deps, ]$Package, "@",
         av_pack[av_pack$Package %in% deps, ]$Version)
}

deps_install <- packageDepsList(deps_install, available_packages)
deps_testing <- packageDepsList(deps_testing, available_packages)

# we want to run pak::pkg_install in a vanilla session in order to avoid conflicts with already loaded packages
res <-
  callr::r_vanilla(function(deps) {
    .libPaths("./pak")
    pak::pkg_install(deps, lib = "./libs")
  }, args = list(deps = deps_install))

pk <- pak::pkg_download(deps_testing, dest_dir = "pkgs", platform = "source")

libpath = paste0(getwd(), "/libs")

if (!dir.exists("out")) dir.create("out")

for (i in seq(nrow(pk))) {
  if (!pk[["direct"]][[i]]) {
    print(pk[["package"]][[i]])
    res <- rcmdcheck::rcmdcheck(
      path = pk$fulltarget[[i]],
      libpath = libpath,
      quiet = FALSE,
      check_dir = "~/tmp",
      env = c("_R_CHECK_FORCE_SUGGESTS_" = 1)
    )
    write(res$stdout,file=paste0("out/",res$package,"-",res$version,".out"))
  }
}



