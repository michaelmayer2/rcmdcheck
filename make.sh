sudo docker run -v $PWD:/work r:latest bash -c "cd /work && R -q -e 'renv::activate()' && R -q -e 'renv::restore()' && R CMD BATCH run.R" 
