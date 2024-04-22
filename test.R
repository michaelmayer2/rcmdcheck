library(rcmdcheck)
library(remotes)
library(tinytex)
if(length(tinytex::tl_pkgs)==0) { tinytex::install_tinytex()}

if (!require(pak,quietly = TRUE)) {
  install.packages("pak", repos = sprintf(
    "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
    .Platform$pkgType,
    R.Version()$os,
    R.Version()$arch
  )) 
}

options(pak.no_extra_messages = TRUE)
library(pak)

myrepo="https://packagemanager.posit.co/cran/latest/"
#mybinrepo="https://packagemanager.posit.co/cran/__linux__/focal/latest/"
#options(repos=c(CRAN=mybinrepo))
packages<-available.packages()
packages<-as.data.frame(packages)$Package
packages<-c("tidyverse","clustermq")


deps_test<-remotes::package_deps(packages,dependencies=c("Imports","LinkingTo")) #repos

deps_download<-remotes::package_deps(packages,dependencies=c("Imports","LinkingTo","Suggests")) #repos

deps_install<-paste0(deps_download$package,"@",deps_download$available)
deps_testing<-paste0(deps_test$package,"@",deps_test$available)

#.libPaths("/tmp/libs")
callr::r_vanilla(pak::pkg_install(deps_install,"libs"),repos=options()$repos,libPath="~/libs")

r<-options()$repos
options(repos=c(CRAN=myrepo))

pak::pkg_download(deps_testing,dest_dir="pkgs",platform="source")
options(repos=r)

oldlib<-.libPaths()
.libPaths("~/libs")
rcmdcheck::rcmdcheck(path="~/pkgs/src/contrib/tidyverse")
