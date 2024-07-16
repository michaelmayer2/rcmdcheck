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


deps<-c()

deps$testing <- unique(c(
  packages_to_be_validated,
  unlist(
    tools::package_dependencies(
      packages_to_be_validated,
      which = c("Imports", "LinkingTo"),
      recursive = TRUE
    )
  )
))

deps$install <-
  unique(c(
    packages_to_be_validated,
    unlist(tools::package_dependencies(
      c(deps$testing, packages_to_be_validated),
      which = c("Imports", "LinkingTo", "Suggests", "Enhances")
    ))
  ))

# Now we also need to catch all of those dependencies of the "Suggests" and "Enhances" dependencies all the way
deps$install <- 
  unique(c(
    deps$install, 
    unlist(tools::package_dependencies(
      c(deps$install, packages_to_be_validated),
      which = c("Imports", "LinkingTo"),
      recursive = TRUE
    ))
  ))

#Let's filter out the already installed base and recommended packages
filterBaseRecDeps <- function(deps) {
  deps[!deps %in% as.data.frame(installed.packages(lib.loc = paste0(R.home(), "/library")))$Package]
  
}

deps$testing = sort(filterBaseRecDeps(deps$testing))
deps$install = sort(filterBaseRecDeps(deps$install))

packageDepsList <- function(deps, av_pack) {
  paste0(av_pack[av_pack$Package %in% deps, ]$Package, "@",
         av_pack[av_pack$Package %in% deps, ]$Version)
}

deps$install_ver <- packageDepsList(deps$install, available_packages)
deps$testing_ver <- packageDepsList(deps$testing, available_packages)

# we want to run pak::pkg_install in a vanilla session in order to avoid conflicts with already loaded packages
Sys.setenv("PKG_SYSREQS_PLATFORM" = "rockylinux-9")


libpathpak=paste0(getwd(),"/pak")
libpathlibs=paste0(getwd(),"/libs")

.Library.Site<-"/work/libs"

# mark all already installed packages in libs as such
#deps$install_ver[deps$install_ver %in% deps$testing_ver]<-paste0("deps::/work/libs/",deps$install[deps$install %in% deps$testing ])


pak::lockfile_create(deps$install_ver,lib=libpathlibs)

.libPaths(c("/work/deps",.libPaths()))

#pak::lockfile_install()

