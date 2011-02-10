###################################################################################
##     FINDING METIERS FROM EFLALO USING MULTIVARIATE CLUSTERING METHODS         ##
##                                                                               ##
##              LOT 2 - VMS LOGBOOKS (WP2)                                       ##
##                                                                               ##
##                                                                               ##
## Authors : Nicolas Deporte (IFREMER / OCEANIC DEVELOPPEMENT)                   ## 
##           St�phanie Mah�vas, S�bastien Deman�che (IFREMER)                    ##
##           Clara Ulrich, Francois Bastardie (DTU Aqua)                         ##
##                                                                               ##
## Last update : February 2011   ,                                               ##
##                                                                               ##
## Runs with R 2.11.1                                                            ##
##                                                                               ##
###################################################################################



rm(list=ls(all=TRUE))
gc(reset=TRUE)

path <- "C:/Nicolas/Scripts/R/Analyses"
setwd(path) # you must choose the path of your working directory

source("multivariateClassificationUtils.r")
source("extractTableMainSpecies.r")
source("getTableAfterPCA.r")
source("getMetierClusters.r")
source("selectMainSpecies.r")
source("compareToOrdination.r")
source("predictMetier.r")
source("getEflaloMetierLevel7.r")
memory.limit(size=4000)

# Load correspLevel7to5 (when the package will be compilated, the following lines will be to remove)
# (data(correspLevel7to5) at the start of getEflaloMetierLevel7 will be enough)
correspLevel7to5=read.table(file="ASFIS_sp_Feb_2010_DCF-Level5.txt", sep="\t",header = TRUE, quote="\"", dec=".")
correspLevel7to5=correspLevel7to5[,c(1,3,4,5,6,12,13)]

path <- "C:/Nicolas/Scripts/R/Analyses/Donnees_completes"
setwd(path)

#-----------------------------
# I. GETTING THE DATA IN AND CLEANING FOR MISSING AND NEGATIVE VALUES ETC
#-----------------------------

country <- "All"
year <- 2007
AreaCodename <- "3a4"
Gear <- c("OTB")

analysisName=paste(country,"_",Gear,year,"_",AreaCodename,sep="")

# Load your own dataset (called dat1 here)
load("All_eflalo_2007OTB3a4.Rdata")

eflalo_level7=getEflaloMetierLevel7(dat1, analysisName, path, critData="EURO", runHACinSpeciesSelection=TRUE, paramTotal=95, paramLogevent=100, critPca="PCA_70", algoClust="CLARA")

save(eflalo_level7,file="eflalo_level7.Rdata")
