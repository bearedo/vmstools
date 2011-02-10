getEflaloMetierLevel7=function(dat, analysisName, path, critData="EURO", runHACinSpeciesSelection=TRUE, paramTotal=95, paramLogevent=100, critPca="PCA_70", algoClust="CLARA"){

  #-------------------------------------------------------------------------
  # I. GETTING THE DATA IN AND CLEANING FOR MISSING AND NEGATIVE VALUES ETC
  #-------------------------------------------------------------------------

  # Load the table linking 3A-CODE (FAO CODE of species) to the species assemblage (level 5).
  #data(correspLevel7to5)
  
  timeStart=Sys.time()
  
  print("--- CREATING DIRECTORIES AND REDUCING THE EFLALO DATASET TO THE ONLY DATA NECESSARY FOR THE ANALYSIS ---")
  cat("\n") 
    
  # creating the directory of the analysis
  if (!file.exists(analysisName)) dir.create(analysisName)
  setwd(file.path(path,analysisName))
  #delete old R cache
  if (file.exists(".R_Cache")) unlink(".R_Cache",recursive=TRUE)                                            

  eflalo_ori = dat # keeping this in cached memory for making the final merging at the end
  Store(eflalo_ori)

  # ! KEEPING ONLY LE_ID AND THE OUTPUT YOU WANT TO GET  (KG/EURO)
  dat=dat[,c("LE_ID",grep(critData,names(dat),value=T))]
  dat[is.na(dat)]=0

  #removing negative and null values
  null.value <- vector()
  for (i in grep(critData,names(dat))) null.value <- c(null.value,which(dat[,i]<0))
  null.value <- c(null.value,which(apply(dat[,2:ncol(dat)],1,sum,na.rm=T)==0))

  if(length(null.value)!=0) {LogEvent.removed <- dat[sort(unique(null.value)),] ; dat <- dat[-sort(unique(null.value)),]}
  Store(LogEvent.removed)

  # rename species names
  names(dat)[-1]=unlist(lapply(strsplit(names(dat[,-1]),"_"),function(x) x[[3]]))

  #removing miscellaneous species
  dat <- dat[,!names(dat)=="MZZ"]
  save(dat, file="dat_cleaned.Rdata")


  #----------------------------------------------------------------------------------------------------------
  # II. EXPLORING THE VARIOUS METHODS FOR IDENTIFYING MAIN SPECIES AND KEEPING THEM IN THE DATA SET (STEP 1)
  #----------------------------------------------------------------------------------------------------------
  print("--- EXPLORING THE DATA FOR SELECTION OF MAIN SPECIES ---")
  cat("\n") 

  #EXPLORATION
  explo=selectMainSpecies(dat,analysisName,RunHAC=runHACinSpeciesSelection,DiagFlag=FALSE)

  # Step 1 : selection of main species
  Step1=extractTableMainSpecies(dat,explo$NamesMainSpeciesHAC,paramTotal=paramTotal,paramLogevent=paramLogevent)

  save(explo,Step1,file="Explo_Step1.Rdata")
  
  
  #-----------------------------
  # III. STEP 2 - PCA - NO-PCA
  #-----------------------------

  setwd(paste(path,analysisName,sep="/"))
  if (!file.exists(critPca)) dir.create(critPca)
  setwd(file.path(path,analysisName,critPca))
  if (file.exists(".R_Cache")) unlink(".R_Cache",recursive=TRUE)


  if (critPca=="PCA_70") Step2=getTableAfterPCA(Step1,analysisName,pcaYesNo="pca",criterion="70percents") else    # criterion="70percents"
  if (critPca=="PCA_SC") Step2=getTableAfterPCA(Step1,analysisName,pcaYesNo="pca",criterion="screetest") else    # criterion="screetest"
  if (critPca=="NO_PCA") Step2=getTableAfterPCA(Step1,analysisName,pcaYesNo="nopca",criterion=NULL)

  save(Step2,file="Step2.Rdata")
  
  
  #-------------------------------------------------------
  # IV. STEP 3 - CLUSTERING METHOD : HAC, CLARA OR KMEANS
  #-------------------------------------------------------

  setwd(paste(path,analysisName,critPca,sep="/"))
  if (!file.exists(algoClust)) dir.create(algoClust)
  setwd(file.path(path,analysisName,critPca,algoClust))
  if (file.exists(".R_Cache")) unlink(".R_Cache",recursive=TRUE)

  if (algoClust=="HAC")    Step3=getMetierClusters(Step1,Step2,analysisName,methMetier="hac",param1="euclidean",param2="ward") else
  if (algoClust=="CLARA")  Step3=getMetierClusters(Step1,Step2,analysisName=analysisName,methMetier="clara",param1="euclidean",param2=NULL) else
  if (algoClust=="KMEANS") Step3=getMetierClusters(Step1,Step2,analysisName=analysisName,methMetier="kmeans",param1=NULL,param2=NULL)

  save(Step3,file="Step3.Rdata")


  #------------------------------------------------
  # V. STEP 4 - COMPARISON WITH ORDINATION METHOD
  #------------------------------------------------

  compOrdin="CompOrdin"
  setwd(paste(path,analysisName,critPca,algoClust,sep="/"))
  if (!file.exists(compOrdin)) dir.create(compOrdin)
  setwd(file.path(path,analysisName,critPca,algoClust,compOrdin))
  if (file.exists(".R_Cache")) unlink(".R_Cache",recursive=TRUE)
  
  if (algoClust=="HAC")     clusters=Step3$clusters
  if (algoClust=="CLARA")   clusters=Step3$clusters$clustering
  if (algoClust=="KMEANS")  clusters=Step3$clusters$cluster  
  
  compMetiers=compareToOrdination(dat=dat,Step2=Step2,clusters=clusters,tabClusters=Step3$tabClusters)
  save(compMetiers,file="compMetiers.Rdata")
  
  
  #------------------------------------
  # VI. STEP 5 - MERGING BACK TO EFLALO
  #------------------------------------

  #choosing the final option
  setwd(file.path(path,analysisName))

  load(paste(path,analysisName,critPca,algoClust,"Step3.Rdata",sep="/"))

  if(!nrow(dat)==nrow(Step3$LE_ID_clust)) print("--error : number of lines in step 3 not equal to input eflalo, please check!!--")

  dat <- cbind(dat,CLUSTER=Step3$LE_ID_clust[,"clust"])

  #now reload the full data set
  eflalo_ori[-sort(unique(null.value)),"CLUSTER"] <- Step3$LE_ID_clust[,"clust"]

  print("Congratulation !! You have now a fully working eflalo dataset with a metier Level 7 !")
  print(Sys.time()-timeStart)
  
  return(eflalo_ori)
}