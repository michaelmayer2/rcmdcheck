FROM rockylinux:9 

ARG R_VERSION=4.3.2
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

RUN crb enable && dnf install -y https://cdn.rstudio.com/r/rhel-9/pkgs/R-${R_VERSION}-1-1.x86_64.rpm

RUN ln -s /opt/R/${R_VERSION}/bin/{R,Rscript} /usr/local/bin

RUN R -q -e 'install.packages("renv",repos="https://packagemanager.posit.co/cran/__linux__/rhel9/latest")'

RUN mkdir /work

#COPY test.R /work
#COPY renv.lock /work

RUN dnf install -y perl xz texinfo-tex texlive-preprint texlive  

#RUN curl -L -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
#	zcat < install-tl-unx.tar.gz | tar xf - && \
#	cd install-tl-2* && \
#	perl ./install-tl --scheme full  --no-interaction --no-doc-install && \
#	 echo -e "PATH=`dirname /usr/local/texlive/*/bin/x86_64-linux`:\$PATH\nMANPATH=`dirname /usr/local/texlive/*/texmf-dist/doc/man`:\$MANPATH\nINFOPATH=`dirname /usr/local/texlive/*/texmf-dist/doc/info`:\$INFOPATH" > /etc/profile.d/texlive.sh 

#RUN cd /work && R -q -e 'renv::activate()' && R -q -e 'renv::restore()' && R CMD BATCH test.R


#RUN cd /work && R -q -e 'source("test.R")'
