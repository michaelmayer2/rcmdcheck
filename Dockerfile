FROM rockylinux:9 

ARG R_VERSION=4.3.2
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

RUN crb enable && dnf install -y https://cdn.rstudio.com/r/rhel-9/pkgs/R-${R_VERSION}-1-1.x86_64.rpm

RUN ln -s /opt/R/${R_VERSION}/bin/{R,Rscript} /usr/local/bin

RUN R -q -e 'install.packages("renv",repos="https://packagemanager.posit.co/cran/__linux__/rhel9/latest")'

RUN mkdir /work

#COPY test.R /work
#COPY renv.lock /work

RUN dnf install -y perl xz

#RUN cd /work && R -q -e 'renv::activate()' && R -q -e 'renv::restore()' && R CMD BATCH test.R


#RUN cd /work && R -q -e 'source("test.R")'
