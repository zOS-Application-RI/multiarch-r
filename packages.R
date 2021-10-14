## If a package is installed, it will be loaded. If any 
## are not, the missing package(s) will be installed 
## from CRAN and then loaded.
.libPaths()
 # Installing ggplot2 from GitHub
# install_github("tidyverse")
update.packages(ask = FALSE, repo='http://cran.rstudio.com/')
install.packages(c("devtools"),dependencies=TRUE, repo='http://cran.rstudio.com/')
library(devtools)
## First specify the packages of interest
install.packages(c("pacman"),dependencies=TRUE, repo='http://cran.rstudio.com/')
# update.packages(checkBuilt = TRUE, ask = FALSE)
# install.packages(c('devtools','pacman'), dependencies=TRUE, repo = '$CRAN')
pacman::p_load(tidyverse,ggplot2, tidyr, dplyr,shinydashboard, docopt,shiny,rJava,RJDBC,curl,shinyalert,stringr,
             dplyr, rmarkdown,httr,jsonlite,DT,plotly,leaflet,htmlwidgets,data.table,
             shinyjs,DBI,plumber,gmailr,pander)
update.packages(checkBuilt = TRUE, ask = FALSE, repo='http://cran.rstudio.com/')