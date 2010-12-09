##############################################################################################################
#                                                                                                            #
#     CLASSIF : FUNCTION FOR SPECIES SELECTION, PCA, CLASSIFICATION OF LOGEVENTS AND M�TIERS COMPUTATION     #
#                                                                                                            #
##############################################################################################################

                                                                                
#############################################################
#  PARAMETERS TO FILL IN DEPENDING OF THE SELECTED METHODS  #
#############################################################
#
# STEP 1 : Choose the method for the selection of species : 3 methods : HAC, totale, logevent
#
# HAC : we view as main species, all species which are not belonging to the cluster with the smaller mean
# 2 parameters to fill in : param1 for the distance between individuals ("euclidean", "maximum", "manhattan", "canberra", "binary" or "minkowski")
#                           param2 for the agregative distance (distance between clusters) ("ward", "single", "complete", "average", "mcquitty", "median" or "centroid")
#
# totale : we take all species by decreasing importance order until having a given percentage (70, 80, 90%) of the total capture
# 1 parameter to fill in : param1 = the threshold (70, 80, 90...)
#
# logevent : we take all species which represents at least a given percentage (10, 20, 30%) for at least a logevent
# 1 parameter to fill in : param1 = the threshold (10, 20, 30...)
#
#
# STEP 2 : PCA or not ?
#
# pca : we execute a PCA on the individuals "logevents", and compute the classification on the factorial coordinates of the logevents
# 1 parameter to fill in : criterion for the criterion of number of factorial axis selection (70percents for taking all first factorial axis until having at least 70% of initial inertia)
#                                                                                            (screetest for using the scree-test)
#
# nopca : we choose to work with the raw data to compute the classification of logevents
#
#
# STEP 3 : Choose the method for the classification of logevents : HAC, KMEANS, PAM, CLARA ?
#
# HAC, 2 parameters to fill in : param3 for the distance between individuals ("euclidean", "maximum", "manhattan", "canberra", "binary" or "minkowski")
#                                param4 for the agregative distance (distance between clusters) ("ward", "single", "complete", "average", "mcquitty", "median" ou "centroid")
#
# KMEANS, no parameter to fill in
#
# PAM, no parameter to fill in
#
# CLARA, 1 parameter to fill in : param3 for the dissimilarity between individuals ("euclidean" or "manhattan")



# Classif : function for the selection of species (hac, totale, logevent), PCA (pca, nopca), classification of logevents (hac, kmeans, pam, and clara) and m�tiers computation (thanks to test-values)
classif_step1 <-function(dat,NamesMainSpeciesHAC,paramTotal=95,paramLogevent=100){

    print("######## STEP 1 COMBINATION OF MAIN SPECIES FROM THE THREE EXPLORATORY METHODS ########")
  
    t1 <- Sys.time()
    
    # clu : first select the appropriate columns
    #dat <- dat[,c("LE_ID",grep(Val,names(dat),value=T))]
    
    #dat[is.na(dat)] <- 0
      
                                                             
    # then simplify the names of columns
    #names(dat)[-1] <- unlist(lapply(strsplit(names(dat[,-1]),"_"),function(x) x[[3]]))
    #names(dat)
    
    #list Species Totale
    p=ncol(dat)   # Number of species +1
    #for (i in 2:p) dat[is.na(dat[,i]),i] <-0

    
    print("calculating proportions...") 
        
    propdat=transformation_proportion(dat[,2:p])
    nameSpecies=colnames(propdat)
    
    # Total quantity caught species by species
    sumcol=rep(as.numeric(NA),p-1) #numeric()
    for(i in 2:p) sumcol[i-1]=sum(dat[,i])

    names(sumcol) <- names(dat)[-1]
    
    # Total quantity caught
    # sumtotale=sum(sumcol,na.rm=T)
    # Percent of each species in the total catch
    propesp=sumcol/sum(sumcol,na.rm=T)*100
    # Columns number of each species by decreasing order of capture
    numesp=order(propesp,decreasing=T)
    # Cumulative percent of catch
    propesp=cumsum(propesp[order(propesp,decreasing=T)])

    
    Store(objects())#[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
    gc(reset=TRUE)
    
    # We are taking all species until having at least param1% of total catch
    if (is.null(paramTotal) | !is.numeric(paramTotal)) stop("param1 must be numeric between 0 and 100")
    seuil=paramTotal
    pourcent=which(propesp<=seuil)
    # We are taking the name of selected species
    espsel=numesp[1:(length(pourcent)+1)]
    nomespselTotal=nameSpecies[espsel]
    
#    #eventually removing MZZ
#    nomespselTotal <- nomespsel[!nomespsel=="MZZ"]      
#    #cat("main species:",sort(nomespsel),"\n")

    #LogEvent
    if (is.null(paramLogevent) | !is.numeric(paramLogevent)) stop("paramLogevent must be numeric between 0 and 100")
    
    seuil=paramLogevent
    # Selection of species making up over param1% of logevent's captures
#    pourcent <- apply(propdat,1,function(x) which(x>=seuil))   
#    nomespselLogevent <- names(propdat)[unique(unlist(pourcent))] 
    nomespselLogevent=character()
    for (i in nameSpecies) if (any(propdat[,i]>=seuil)) nomespselLogevent=c(nomespselLogevent,i)
    
    #eventually removing MZZ
   # nomespselLogevent <- nomespsel[!nomespsel=="MZZ"]  

    #merge with explospecies
    ListSpeciesAll <- sort(unique(c(NamesMainSpeciesHAC,nomespselTotal,nomespselLogevent)))
    ListSpeciesAll <- ListSpeciesAll[!ListSpeciesAll=="MZZ"]

    # We are bulding the table with main species and aggregated other species
    datSpecies=building_tab_pca(propdat,ListSpeciesAll)

  
  
    datSpecies <- cbind(LE_ID=dat$LE_ID,datSpecies)

  

    print(" --- end of step 1 ---")
    print(Sys.time()-t1)


    return(datSpecies)

}







##############################################################################################################################################
#                                                          STEP 2 : PCA OR NOT                                                               #
##############################################################################################################################################

classif_step2 <-function(datSpecies,analysisName="",pcaYesNo="pca",criterion="70percents"){
LE_ID <- datSpecies[,1]
datSpecies <- datSpecies[,-1]


  print("######## STEP 2 PCA/NO PCA ON CATCH PROFILES ########")
  
  t1 <- Sys.time()
  print(paste(" --- selected method :",pcaYesNo, "---"))
   

  if(pcaYesNo=="pca"){                                                                 
    print("running PCA on all axes...")  
    # PCA (Principal Component Analysis)
    log.pca <- PCA(datSpecies, graph=T, ncp=ncol(datSpecies))

    savePlot(filename=paste(analysisName,'Species projection on the two first factorial axis',sep="_"), type='png', restoreConsole = TRUE)
    dev.off()
    savePlot(filename=paste(analysisName,'Individuals projection on the two first factorial axis',sep="_"), type='png', restoreConsole = TRUE)
    dev.off()
    plot(log.pca,label=NULL)   
    savePlot(filename=paste(analysisName,'Individuals projection on the two first factorial axis',sep="_"), type='png', restoreConsole = TRUE)
    dev.off()
    
#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
    # Data frame given eigenvalues, inertia and cumulative inertia of factorial axis
    #tabInertia=data.frame(cbind(Axis=1:length(log.pca$eig[,1]), Eigenvalues=log.pca$eig[,1], Inertia=log.pca$eig[,2], CumulativeInertia=log.pca$eig[,3]))                  
    #tabInertia=as.matrix(log.pca$eig)
    
    # Determine the number of axis to keep
    if(criterion=="70percents"){
      nbaxes=which(log.pca$eig[,3]>70)[1]   # we are taking the axis until having 70% of total inertia
      cat("--- number of axes:",nbaxes,"\n")
      cat("--- percentage inertia explained:",log.pca$eig[nbaxes,3],"\n")
    } else 
    # OR
    if(criterion=="screetest"){
      nbaxes=which(scree(log.pca$eig[,1])[,"epsilon"]<0)[2]  # thanks to the scree-test
      cat("--- number of axes:",nbaxes,"\n")
      cat("--- percentage inertia explained:",log.pca$eig[nbaxes,3],"\n")
    } else stop("Criterion for PCA must be 70percents or screetest")
      
    # Eigenvalues and relative graphics
    log.pca$eig                                                  

    png(paste(analysisName,"Eigen values.png",sep="_"), width = 1200, height = 800)
    x=1:length(log.pca$eig[,1])
    barplot(log.pca$eig[,1],names.arg=x, main="Eigen values")
    dev.off()
    png(paste(analysisName,"Percentage of Inertia.png",sep="_"), width = 1200, height = 800)
    color=rep("grey",length(log.pca$eig[,1]))
    if(criterion=="screetest") color[1:nbaxes]="green" 
    barplot(log.pca$eig[,2],names.arg=x, col=color, main="Percentage of Inertia of factorial axis", xlab="Axis", ylab="% of Inertia")
    dev.off()
    png(paste(analysisName,"Cumulative Percentage of Inertia.png",sep="_"), width = 1200, height = 800)
    color=rep("grey",length(log.pca$eig[,1]))
    if(criterion=="70percents") color[1:nbaxes]="green"
    barplot(log.pca$eig[,3],names.arg=x, col=color, main="Cumulative Percentage of Inertia of factorial axis", xlab="Axis", ylab="% of Inertia")
    abline(h=70, col="red")
    text(1,72, "70% of Inertia", col = "red", adj = c(0, -.1))
    dev.off()       
    

#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
    
    # Projection of variables Species on the first factorial axis
    png(paste(analysisName,"Projection of Species on first factorial axis.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(2,3))
    plot(log.pca,choix="var",axes = c(1, 2),new.plot=FALSE,lim.cos2.var = 0.3)
    plot(log.pca,choix="var",axes = c(2, 3),new.plot=FALSE,lim.cos2.var = 0.3)
    plot(log.pca,choix="var",axes = c(1, 3),new.plot=FALSE,lim.cos2.var = 0.3)
    plot(log.pca,choix="var",axes = c(1, 4),new.plot=FALSE,lim.cos2.var = 0.3)
    plot(log.pca,choix="var",axes = c(2, 4),new.plot=FALSE,lim.cos2.var = 0.3)
    plot(log.pca,choix="var",axes = c(3, 4),new.plot=FALSE,lim.cos2.var = 0.3)
    par(op)
    title(main=paste("Projection of Species on first factorial axis","\n","\n",sep=""))
    dev.off()


    # PCA with the good number of axis
    print("running PCA on selected axes...")
    log.pca=log.pca$ind$coord[,1:nbaxes]

    datLog=round(log.pca,4)
    
    #write.table(datLog, file="datLog_OTB2008euroNA_26_11_10.txt", quote=T, dec='.', sep=';', col.names=T, row.names=F)

  } else 


  if(pcaYesNo=="nopca"){
    datLog=datSpecies
  }  else stop("pcaYesNo must be pca or nopca")

  Store(objects())
  gc(reset=TRUE)

  print(" --- end of step 2 ---")
  print(Sys.time()-t1)
  
  return(datLog)

}



##############################################################################################################################################
#                                               STEP 3 : CLUSTERING OF THE LOGEVENTS                                                         #
##############################################################################################################################################



########################################################################################################################################   HAC

classif_step3 <-function(datSpecies, datLog, analysisName="",methMetier="clara",param3="euclidean",param4=NULL){

le_id <- datSpecies[,1]
datSpecies <- datSpecies[,-1]

print("######## STEP 3 CLUSTERING ########")

t1 <- Sys.time()
print(paste(" --- selected method :",methMetier, "---"))  


  if(methMetier=="hac"){
  
    classifWithinVar=numeric()
    classifBetweenVar=numeric()
    classifQuality=numeric()
    sampleList=numeric()
    mProfilSample=numeric()
    classifVarExplain=numeric()

    #totaleVarPart=numeric()   #(used for the calcul of totale variance)
    nbLog=nrow(datLog)
    nbDim=ncol(datLog)
    
    # Center of gravity of datLog
    centerOfGravityDatLog=colMeans(datLog)
    
    # HAC like CLARA (HAC on sample, affectation of each logevent to a cluster, quality of classification, do it 5 times, choose the sample which gives the best quality of classification)
    print("hac on subsets...")
    
    for(i in 1:5){
      
      numSample=i
      print(paste("sample",i))
      # Sample of size 15000 logevents
      minsam=min(nbLog,15000)
      sam=sample(1:nbLog,size=minsam,replace=F)
      # Record the 5 samples
      sampleList=rbind(sampleList,sam)
      outofsam=setdiff(1:nbLog,sam)
      sampleDatLog=datLog[sam,]
      sampleDatSpecies=datSpecies[sam,]
      
      # HAC on the sample
      log.hac=hcluster(sampleDatLog, method=param3, link=param4)
      inerties.vector=log.hac$height[order(log.hac$height,decreasing=T)]
      nbClust=which(scree(inerties.vector)[,"epsilon"]<0)[2]
    
      # Cut the dendogram at the selected level
      sampleClusters=cutree(log.hac,k=nbClust)

#      Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#      gc(reset=TRUE)

      # Add the cluster to each logevent of the sample
      sampleDatLogWithClusters=cbind(sampleDatLog,sampleClusters)

      sampleClusters=sampleDatLogWithClusters[,ncol(sampleDatLogWithClusters)]
      
      # Within and between variance of clusters and classification
      centerOfGravityClassif=numeric()
      withinVarClusters=numeric()
      centerOfGravitySampleDatLog=colMeans(sampleDatLog)
      centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravitySampleDatLog)
      for(k in 1:nbClust){  # Within variance by cluster
  
        clusti=sampleDatLogWithClusters[which(sampleClusters==k),1:nbDim]
        centerOfGravityClusti=colMeans(clusti)
        centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravityClusti)
        sizeClusti=nrow(clusti)
        centerOfGravityClusti=colMeans(clusti)
        withinVarClustiPart=numeric()
        withinVarClusters[k]=1/sizeClusti*sum(apply(clusti,1,function(x) withinVar(x,centerOfGravityClusti)))
  
      }
      # Between variance
      classifBetweenVar=1/nbLog*sum(sizeClusti*((dist(centerOfGravityClassif)[1:nbClust])^2))
      # Within variance of clusters on totale variance (pourcent) and between variance on totale variance of classification
      withinVarClusterOnTot=withinVarClusters/(classifBetweenVar+sum(withinVarClusters))*100
      betweenVarClassifOnTot=classifBetweenVar/(classifBetweenVar+sum(withinVarClusters))*100
      classifVarExplain=c(classifVarExplain,betweenVarClassifOnTot)

      # Mean profiles by cluster for each sample
      nbSpec=ncol(datSpecies)
      mprofil=numeric()
      blank=rep(00,nbSpec)
      for(k in 1:nbClust){
        mprofilclusti=colMeans(sampleDatSpecies[which(sampleClusters==k),])
        mprofil=rbind(mprofil,mprofilclusti)
      }
      mprofil=rbind(mprofil,blank)
      
      mProfilSample=rbind(mProfilSample,mprofil)


      # Graphics
      
      # Calculation of each cluster size
      sizeClusters=numeric()
      for(k in 1:nbClust){
        sizeClusters[k]=length(which(sampleClusters==k))
      }
  
      # Compute the test-values for species
      resval=test.values(sampleClusters,sampleDatSpecies)
      # Determine the target species
      target=targetspecies(resval)
      #cat("target species:", target,"\n")
      #print(target$tabnomespcib)
      
  
#      Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#      gc(reset=TRUE)
  
  
      # Projections on the first factorial plans
      png(paste(analysisName,numSample,"Sample_Projections.png",sep="_"), width = 1200, height = 800)
      op <- par(mfrow=c(2,3))
      plot(sampleDatLog[,1], sampleDatLog[,2], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(sampleClusters)], main="Projection of HAC classification on the factorial plan 1-2", xlab="axis 1", ylab="axis 2")
      if(dim(datLog)[2]>2) {
      plot(sampleDatLog[,2], sampleDatLog[,3], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(sampleClusters)], main="Projection of HAC classification on the factorial plan 2-3", xlab="axis 2", ylab="axis 3")
      plot(sampleDatLog[,1], sampleDatLog[,3], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(sampleClusters)], main="Projection of HAC classification on the factorial plan 1-3", xlab="axis 1", ylab="axis 3")
      if(dim(datLog)[2]>3) {
      plot(sampleDatLog[,1], sampleDatLog[,4], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(sampleClusters)], main="Projection of HAC classification on the factorial plan 1-4", xlab="axis 1", ylab="axis 4")
      plot(sampleDatLog[,2], sampleDatLog[,4], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(sampleClusters)], main="Projection of HAC classification on the factorial plan 2-4", xlab="axis 2", ylab="axis 4")
      plot(sampleDatLog[,3], sampleDatLog[,4], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(sampleClusters)], main="Projection of HAC classification on the factorial plan 3-4", xlab="axis 3", ylab="axis 4")
      }}
      par(op)
      dev.off()
  
      
      # Rectangles plotting
      png(paste(analysisName,numSample,"Sample_Dendogram.png",sep="_"), width = 1200, height = 800)
      plclust(log.hac,labels=F,hang=-1,ann=F)
      title(main="HAC dendogram",xlab="Logevents",ylab="Height")
      rect.hclust(log.hac, k=nbClust)
      dev.off()
  
  
      # Mean profile of the dataset
      meanprofile=colMeans(sampleDatSpecies)
      png(paste(analysisName,numSample,"Sample_Mean profile of the sample.png",sep="_"), width = 1200, height = 800)
      op <- par(las=2)
      barplot(meanprofile, main="Mean profile of the sample", xlab="Species", ylab="Percentage of catch")
      par(op)
      mtext(paste(nrow(datSpecies)," logevents"), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
      dev.off()
      
  
      # Mean profiles by cluster
      nbSpec=ncol(sampleDatSpecies)
      summarySampleClusters=array(0,dim=c(6,nbSpec,nbClust))
      dimnames(summarySampleClusters)[[1]]=c("Min.","1st Qu.","Median", "Mean", "3rd Qu.", "Max.")
      dimnames(summarySampleClusters)[[2]]=names(meanprofile)
      dimnames(summarySampleClusters)[[3]]=paste("Cluster ",1:nbClust)
      for(k in 1:nbClust){
        if(sizeClusters[k]==1){
          summarySampleClusters[,,k]=apply(t(as.matrix(sampleDatSpecies[which(sampleClusters==k),])),2, 
            function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
        }else{
          summarySampleClusters[,,k]=apply(sampleDatSpecies[which(sampleClusters==k),],2, 
            function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
        }
      }
      # Species names for mean profile plots
      nameSpPlot=character()
      catchMeanThreshold=2
      for(k in 1:nbClust){
        namSpi=names(meanprofile[which(t(summarySampleClusters["Mean",,k])>catchMeanThreshold)])
        numSpi=which(t(summarySampleClusters["Mean",,k])>catchMeanThreshold)
        nameSpPloti=rep("",nbSpec)
        nameSpPloti[numSpi]=namSpi
        nameSpPlot=rbind(nameSpPlot,nameSpPloti)
      }      
      png(paste(analysisName,numSample,"Sample_Mean profile by cluster of the sample.png",sep="_"), width = 1200, height = 800)
      op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
      for(k in 1:nbClust){
        op2 <- par(las=2)
        barplot(t(summarySampleClusters["Mean",,k]), names.arg=nameSpPlot[k,], xlab="Species", ylab="Percentage of catch", col="gray")
        par(op2)
        mtext(paste("Cluster",k), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
      }
      par(op)    
      title(main=paste("Mean profile by cluster of the sample","\n","\n",sep=""))
      dev.off()
      
     
      # Standard deviation profile by cluster
      sdprofil=matrix(0,nrow=nbClust,ncol=nbSpec)
      namSdPlot=character()
      SdThreshold=2
      for(k in 1:nbClust){
        if(length(which(sampleClusters==k))==1){ sdprofilclusti=rep(0,nbSpec)
        }else{sdprofilclusti=sd(sampleDatSpecies[which(sampleClusters==k),])}
        namSDi=names(which(sdprofilclusti>SdThreshold))
        numSDi=which(sdprofilclusti>SdThreshold)
        namSdPloti=rep("",nbSpec)
        namSdPloti[numSDi]=namSDi
        sdprofil[k,]=sdprofilclusti
        namSdPlot=rbind(namSdPlot,namSdPloti)
      }
      rownames(sdprofil) <- 1:nrow(sdprofil)
      png(paste(analysisName,numSample,"Sample_Standard deviation profile by cluster.png",sep="_"), width = 1200, height = 800)
      op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
      for(k in 1:nbClust){
        op2 <- par(las=2)
        barplot(sdprofil[k,], names.arg=namSdPlot[k,], xlab="Species", ylab="Percentage of catch")
        par(op2)
        mtext(paste("Cluster",k), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
      }
      par(op)
      title(main=paste("Standard deviation profile by cluster","\n","\n",sep=""))
      dev.off()  

      
      # Number of Logevents by cluster
      x=c(1:nbClust)
      png(paste(analysisName,numSample,"Sample_Number of Logevents by cluster.png",sep="_"), width = 1200, height = 800)
      coord=barplot(sizeClusters, names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents")
      barplot(sizeClusters, names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents", col="skyblue")
      text(coord,sizeClusters+200,sizeClusters,font=2,xpd=NA)
      dev.off()
  
  
      # Target Species profiles (test-value)
      targetresval=numeric()
      nameTargetPlot=character()
      for(k in 1:nbClust){
        nomtargeti=as.character(target$tabnomespcib[k,which(!is.na(target$tabnumespcib[k,]))])
        numtargeti=as.numeric(target$tabnumespcib[k,which(!is.na(target$tabnumespcib[k,]))])
        nameTargetPloti=rep("",nbSpec)
        nameTargetPloti[numtargeti]=nomtargeti
        nameTargetPlot=rbind(nameTargetPlot,nameTargetPloti)
        targetresvalclusti=rep(0,nbSpec)
        targetresvalclusti[numtargeti]=resval[nomtargeti,k]
        targetresval=rbind(targetresval,targetresvalclusti)
      }
  
      png(paste(analysisName,numSample,"Sample_Profile of target species by cluster.png",sep="_"), width = 1200, height = 800)
      op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
      for(k in 1:nbClust){
        op2 <- par(las=2)
        barplot(targetresval[k,],names.arg=nameTargetPlot[k,], cex.names=1, xlab="Species", ylab="Test-value")
        par(op2)
        mtext(paste("Cluster",k), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
      }
      par(op)
      title(main=paste("Profile of target species by cluster","\n","\n",sep=""))
      dev.off()

#      Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#      gc(reset=TRUE)

    } # end of for(i in 1:5)
      

      
 
    # Select the sample which gives the smaller classification's quality (the best sample)
    sam=sampleList[which.max(classifVarExplain),]
    outofsam=setdiff(1:nbLog,sam)
    sampleDatLog=datLog[sam,]
    
    nbLogSample=nrow(sampleDatLog)
    nbDim=ncol(sampleDatLog)
    
#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
    # HAC with the best sample
    print("Final HAC")
    log.hac=hcluster(sampleDatLog, method=param3, link=param4)
    
    # Determine the number of cluster thanks to the scree-test
    inerties.vector=log.hac$height[order(log.hac$height,decreasing=T)]
    nbClust=which(scree(inerties.vector)[,"epsilon"]<0)[2]

    # Cut the dendogram at the selected level
    sampleClusters=cutree(log.hac,k=nbClust)
    sampleClusters=as.factor(sampleClusters)
    
#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)

    sampleDatLogWithClusters=data.frame()
    sampleDatLogWithClusters=cbind(sampleDatLog,sampleClusters)
    sampleDatLogWithClusters=as.data.frame(sampleDatLogWithClusters)

    # Discriminante analysis on the learning dataset
    learning=lda(sampleClusters~.,data=sampleDatLogWithClusters)
    
    otherLog=datLog[outofsam,]
    otherLog=as.data.frame(otherLog)                              
    
    # Predict the cluster for the other logevent
    pred=predict(learning,otherLog)

    #otherDatLogWithClusters=cbind(otherLog, result.lda$class)
    otherDatLogWithClusters=cbind(otherLog,pred$class)
    colnames(otherDatLogWithClusters)=colnames(sampleDatLogWithClusters)

    # Rebuilt complete datLog with clusters
    clusters=numeric(length=nbLog)
    clusters[sam]=sampleClusters
    clusters[outofsam]=pred$class
    datLogWithClusters=cbind(datLog,clusters)

#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
   
    # Within and between variance of clusters and classification
    centerOfGravityClassif=numeric()
    withinVarClusters=numeric()
    centerOfGravityDatLog=colMeans(datLog)
    centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravityDatLog)
    for(k in 1:nbClust){  # Within variance by cluster

      clusti=datLogWithClusters[which(clusters==k),1:nbDim]
      centerOfGravityClusti=colMeans(clusti)
      centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravityClusti)
      sizeClusti=nrow(clusti)
      withinVarClusters[k]=1/sizeClusti*sum(apply(clusti,1,function(x) withinVar(x,centerOfGravityClusti)))

    }
    # Between variance
    classifBetweenVar=1/nbLog*sum(sizeClusti*((dist(centerOfGravityClassif)[1:nbClust])^2))
    # Within variance of clusters on totale variance (pourcent) and between variance on totale variance of classification
    withinVarClusterOnTot=withinVarClusters/(classifBetweenVar+sum(withinVarClusters))*100
    betweenVarClassifOnTot=classifBetweenVar/(classifBetweenVar+sum(withinVarClusters))*100


    # Calculation of each cluster size
    n=nrow(datLog)
    sizeClusters=numeric()
    for(k in 1:nbClust){
      sizeClusters[k]=length(which(clusters==k))
    }

    # Compute the test-values for species
    resval=test.values(clusters,datSpecies)
    # Determine the target species
    target=targetspecies(resval)
    #cat("target species:", target,"\n")
    #print(target$tabnomespcib)
    

#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)

    # Projections on the first factorial plans
    png(paste(analysisName,"Projections.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(2,3))
    plot(datLog[,1], datLog[,2], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(clusters)], main="Projection of HAC classification on the factorial plan 1-2", xlab="axis 1", ylab="axis 2")
    if(dim(datLog)[2]>2) {
    plot(datLog[,2], datLog[,3], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(clusters)], main="Projection of HAC classification on the factorial plan 2-3", xlab="axis 2", ylab="axis 3")
    plot(datLog[,1], datLog[,3], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(clusters)], main="Projection of HAC classification on the factorial plan 1-3", xlab="axis 1", ylab="axis 3")
    if(dim(datLog)[2]>3) {
    plot(datLog[,1], datLog[,4], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(clusters)], main="Projection of HAC classification on the factorial plan 1-4", xlab="axis 1", ylab="axis 4")
    plot(datLog[,2], datLog[,4], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(clusters)], main="Projection of HAC classification on the factorial plan 2-4", xlab="axis 2", ylab="axis 4")
    plot(datLog[,3], datLog[,4], pch=21, bg=rainbow(length(sizeClusters))[as.numeric(clusters)], main="Projection of HAC classification on the factorial plan 3-4", xlab="axis 3", ylab="axis 4")
    }}
    par(op)
    dev.off()

    
    # Rectangles plotting
    png(paste(analysisName,"Dendogram.png",sep="_"), width = 1200, height = 800)
    plclust(log.hac,labels=F,hang=-1,ann=F)
    title(main="HAC dendogram",xlab="Logevents",ylab="Height")
    rect.hclust(log.hac, k=nbClust)
    dev.off()


    # Mean profile of the dataset
    meanprofile=colMeans(datSpecies)
    png(paste(analysisName,"Mean profile of the dataset.png",sep="_"), width = 1200, height = 800)
    op <- par(las=2)
    barplot(meanprofile, main="Mean profile of the dataset", xlab="Species", ylab="Percentage of catch")
    par(op)
    mtext(paste(nrow(datSpecies)," logevents"), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    dev.off()
    

    # Mean profiles by cluster
    nbSpec=ncol(datSpecies)
    summaryClusters=array(0,dim=c(6,nbSpec,nbClust))
    dimnames(summaryClusters)[[1]]=c("Min.","1st Qu.","Median", "Mean", "3rd Qu.", "Max.")
    dimnames(summaryClusters)[[2]]=names(meanprofile)
    dimnames(summaryClusters)[[3]]=paste("Cluster ",1:nbClust)
    for(i in 1:nbClust){
      if(sizeClusters[i]==1){
        summaryClusters[,,i]=apply(t(as.matrix(datSpecies[which(clusters==i),])),2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }else{
        summaryClusters[,,i]=apply(datSpecies[which(clusters==i),],2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }
    }
    # Species names for mean profile plots
    nameSpPlot=character()
    catchMeanThreshold=2
    for(i in 1:nbClust){
      namSpi=names(meanprofile[which(t(summaryClusters["Mean",,i])>catchMeanThreshold)])
      numSpi=which(t(summaryClusters["Mean",,i])>catchMeanThreshold)
      nameSpPloti=rep("",nbSpec)
      nameSpPloti[numSpi]=namSpi
      nameSpPlot=rbind(nameSpPlot,nameSpPloti)
    }
    png(paste(analysisName,"Mean profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(t(summaryClusters["Mean",,i]), names.arg=nameSpPlot[i,], xlab="Species", ylab="Percentage of catch", col="gray")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Mean profile by cluster","\n","\n",sep=""))
    dev.off()    
    
    
    # Standard deviation profile by cluster
    sdprofil=matrix(0,nrow=nbClust,ncol=nbSpec)
    namSdPlot=character()
    SdThreshold=2
    for(i in 1:nbClust){
      if(length(which(clusters==i))==1){ sdprofilclusti=rep(0,nbSpec)
      }else{sdprofilclusti=sd(datSpecies[which(clusters==i),])}
      namSDi=names(which(sdprofilclusti>SdThreshold))
      numSDi=which(sdprofilclusti>SdThreshold)
      namSdPloti=rep("",nbSpec)
      namSdPloti[numSDi]=namSDi
      sdprofil[i,]=sdprofilclusti
      namSdPlot=rbind(namSdPlot,namSdPloti)
    }
    rownames(sdprofil) <- 1:nrow(sdprofil)
    png(paste(analysisName,"Standard deviation profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(sdprofil[i,], names.arg=namSdPlot[i,], xlab="Species", ylab="Percentage of catch")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Standard deviation profile by cluster","\n","\n",sep=""))
    dev.off()
    
    
#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
    
    # Number of Logevents by cluster
    x=c(1:nbClust)
    png(paste(analysisName,"Number of Logevents by cluster.png",sep="_"), width = 1200, height = 800)
    coord=barplot(sizeClusters, names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents")
    barplot(sizeClusters, names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents", col="skyblue")
    text(coord,sizeClusters+400,sizeClusters,font=2,xpd=NA)
    dev.off()


    # Target Species profiles (test-value)
    targetresval=numeric()
    nameTargetPlot=character()
    for(i in 1:nbClust){
      nomtargeti=as.character(target$tabnomespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      numtargeti=as.numeric(target$tabnumespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      nameTargetPloti=rep("",nbSpec)
      nameTargetPloti[numtargeti]=nomtargeti
      nameTargetPlot=rbind(nameTargetPlot,nameTargetPloti)
      targetresvalclusti=rep(0,nbSpec)
      targetresvalclusti[numtargeti]=resval[nomtargeti,i]
      targetresval=rbind(targetresval,targetresvalclusti)
    }

    png(paste(analysisName,"Profile of target species by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(targetresval[i,],names.arg=nameTargetPlot[i,], cex.names=1, xlab="Species", ylab="Test-value")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Profile of target species by cluster","\n","\n",sep=""))
    dev.off()
    
    
    
    
    # Descriptive and summary tables of clusters
    clusterDesc=matrix(0,nrow=7,ncol=nbClust)
    for(i in 1:nbClust){
      clusterDesc[,i]=c(sizeClusters[i], 
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<50))+1,
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<90))+1,
                        length(which(resval[,i]>1.98)),
                        length(which(resval[,i]>3.29)),
                        length(which(apply(datSpecies,2,function (x) (sizeClusters[i]-length(which(x[clusters==i]==0)))/sizeClusters[i]*100)>50)),
                        length(which(apply(datSpecies,2,function (x) (sizeClusters[i]-length(which(x[clusters==i]==0)))/sizeClusters[i]*100)>90)))
    }
    rownames(clusterDesc)=c("Clusters size","to have 50% of catch", "to have 90% of catch",
                            "with a test-value > 1.98", "with a test-value > 3.29",
                            "catch in 50% of the logevents", "catch in 90% of the logevents")
    colnames(clusterDesc)=1:nbClust                        
    clusterDesc2=as.data.frame(clusterDesc)
    
    
    namesSpecies=matrix(NA,nrow=nbClust,ncol=10)
    namesCapt=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesCatch = min(5,dim(t(summaryClusters["Mean",,]))[[2]])
    namesTarget=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesVT = min(5,dim(target$tabnomespcib)[[2]])
    
    for(i in 1:nbClust){
      namesCapt[i,]=colnames(t(summaryClusters["Mean",,i]))[order(t(summaryClusters["Mean",,i]),decreasing=T)][1:nbSpeciesCatch]
      a=as.data.frame(t(summaryClusters["Mean",target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])],i]))
      colnames(a)= target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])]
      namesTarget[i,1:length(target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])])]=colnames(a[order(a,decreasing=T)])
      namesSpecies[i,1:length(union(namesCapt[i,],namesTarget[i,]))]=union(namesCapt[i,],namesTarget[i,])
    }
    
    tabPropCatch=matrix(NA,nrow=nbClust,ncol=10)
    tabTestVal=matrix(NA,nrow=nbClust,ncol=10)
    tabPropLog=matrix(NA,nrow=nbClust,ncol=10)
    
    for(i in 1:nbClust){
      print("-----------------------------------------------------------------")
      print(paste("Cluster ",i))
      propCatch=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabPropCatch[i,1:length(propCatch)]=propCatch
      print(propCatch)
      testVal=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) resval[x,i]),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabTestVal[i,1:length(testVal)]=testVal
      print(testVal)
      propLog=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (sizeClusters[i]-length(which(datSpecies[clusters==i,x]==0)))/sizeClusters[i]*100),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (sizeClusters[i]-length(which(datSpecies[clusters==i,x]==0)))/sizeClusters[i]*100),digits=1)>=0.1)]
      tabPropLog[i,1:length(propLog)]=propLog
      print(propLog)
    }
    
    tabClusters=array(0,dim=c(10,4,nbClust))
    dimnames(tabClusters)[[2]]=c("FAO","Test-value","% Catch","% Logevents")
    dimnames(tabClusters)[[3]]=paste("Cluster ",1:nbClust)
    for(i in 1:nbClust){
      tabClusters[,,i]=cbind(namesSpecies[i,],tabTestVal[i,],tabPropCatch[i,],tabPropLog[i,])
    }
    
    sizeTabClusters=numeric()
    for(i in 1:nbClust){
      sizeTabClusters[i]=min(length(namesSpecies[i,!is.na(namesSpecies[i,])]),length(tabPropCatch[i,!is.na(tabPropCatch[i,])]),length(tabTestVal[i,!is.na(tabTestVal[i,])]),length(tabPropLog[i,!is.na(tabPropLog[i,])]))
    }
    
    db <- paste(analysisName,"_tables.xls",sep="")
    if(db %in% list.files()) file.remove(db)
    channel <- odbcConnectExcel(xls.file = db,readOnly=FALSE)
    sqlSave(channel, clusterDesc2, tablename = "DescClust")
    
    for(i in 1:nbClust){
      tabClusti=as.data.frame(tabClusters[1:sizeTabClusters[i],,i])
      sqlSave(channel, tabClusti, tablename = paste("Clust",i,sep=""),rownames = TRUE, colnames = TRUE)
    }
    odbcClose(channel)
    
    
    

    LE_ID_clust=cbind(LE_ID=LE_ID,clust=clusters)
    print(" --- end of step 3 ---")
    print(Sys.time()-t1)
    
    return(list(LE_ID_clust=LE_ID_clust, clusters=clusters, sizeClusters=sizeClusters, nameTarget=target$tabnomespcib, betweenVarClassifOnTot=betweenVarClassifOnTot, mProfilSample=mProfilSample, nbClust=nbClust, summaryClusters=summaryClusters, resval=resval, target=target))

  }   else 





########################################################################################################################################   KMEANS

  if(methMetier=="kmeans"){
    # Calculation of optimal k thanks to within variance
    varintra=numeric()
    nbLog=nrow(datLog)
    for (k in 2:15){
      clustersKmeans=kmeans(datLog, k, iter.max=40, nstart=20)
      varintra[k]=1/nbLog*sum(clustersKmeans$withinss)
    }
    png(paste(analysisName,"Within variance of the classification.png",sep="_"), width = 1200, height = 800)
    plot(varintra,main="Within clusters variance",xlab="Number of clusters",ylab="Within Variance")
    dev.off()

#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)

    diffvarintra=diff(varintra,na.rm=T)
    diffdiffvar=diff(diffvarintra,na.rm=T)
    k=which.max(diffdiffvar)+1
    
    # KMEANS with k optimal
    clusters=kmeans(datLog, k, iter.max=40, nstart=20, algorithm="Hartigan-Wong")


    # Quality of classification
    centerOfGravityClassif=numeric()
    centerOfGravityDatLog=colMeans(datLog)
    centerOfGravityClassif=rbind(centerOfGravityDatLog,clusters$centers)
    classifBetweenVar=1/nbLog*sum(clusters$size*((dist(centerOfGravityClassif)[1:k])^2))
    classifWithinVar=1/nbLog*sum(clusters$withinss)
    classifQuality=classifWithinVar/classifBetweenVar
    withinVarClustersOnTot=(clusters$withinss/nbLog)*100/(classifBetweenVar+classifWithinVar)
    betweenVarClassifOnTot=classifBetweenVar/(classifBetweenVar+classifWithinVar)*100

    # Compute the test-values for species
    resval=test.values(clusters$cluster,datSpecies)
    #Determine the target species
    target=targetspecies(resval)

#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)


    # Projections on the first factorial plans
    png(paste(analysisName,"Projections.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(2,3))
    plot(datLog[,1], datLog[,2], pch=21, bg=rainbow(length(clusters$size))[as.numeric(clusters$cluster)], main="Projection of Kmeans classification on the factorial plan 1-2", xlab="axis 1", ylab="axis 2")
    if(dim(datLog)[2]>2) {
    plot(datLog[,2], datLog[,3], pch=21, bg=rainbow(length(clusters$size))[as.numeric(clusters$cluster)], main="Projection of Kmeans classification on the factorial plan 2-3", xlab="axis 2", ylab="axis 3")
    plot(datLog[,1], datLog[,3], pch=21, bg=rainbow(length(clusters$size))[as.numeric(clusters$cluster)], main="Projection of Kmeans classification on the factorial plan 1-3", xlab="axis 1", ylab="axis 3")
    if(dim(datLog)[2]>3) {
    plot(datLog[,1], datLog[,4], pch=21, bg=rainbow(length(clusters$size))[as.numeric(clusters$cluster)], main="Projection of Kmeans classification on the factorial plan 1-4", xlab="axis 1", ylab="axis 4")
    plot(datLog[,2], datLog[,4], pch=21, bg=rainbow(length(clusters$size))[as.numeric(clusters$cluster)], main="Projection of Kmeans classification on the factorial plan 2-4", xlab="axis 2", ylab="axis 4")
    plot(datLog[,3], datLog[,4], pch=21, bg=rainbow(length(clusters$size))[as.numeric(clusters$cluster)], main="Projection of Kmeans classification on the factorial plan 3-4", xlab="axis 3", ylab="axis 4")    
    }}
    par(op)
    dev.off()
    
    
    # Mean profile of the dataset
    meanprofile=colMeans(datSpecies)
    png(paste(analysisName,"Mean profile of the dataset.png",sep="_"), width = 1200, height = 800)
    op <- par(las=2)
    barplot(meanprofile, main="Mean profile of the dataset", xlab="Species", ylab="Percentage of catch")
    par(op)
    mtext(paste(nrow(datSpecies)," logevents"), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    dev.off()


    # Mean profiles by cluster
    nbClust=length(clusters$size)
    nbSpec=ncol(datSpecies)
    summaryClusters=array(0,dim=c(6,nbSpec,nbClust))
    dimnames(summaryClusters)[[1]]=c("Min.","1st Qu.","Median", "Mean", "3rd Qu.", "Max.")
    dimnames(summaryClusters)[[2]]=names(meanprofile)
    dimnames(summaryClusters)[[3]]=paste("Cluster ",1:nbClust)
    for(i in 1:nbClust){
      if(clusters$size[i]==1){
        summaryClusters[,,i]=apply(t(as.matrix(datSpecies[which(clusters$cluster==i),])),2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }else{
        summaryClusters[,,i]=apply(datSpecies[which(clusters$cluster==i),],2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }
    }
    # Species names for mean profile plots
    nameSpPlot=character()
    catchMeanThreshold=2
    for(i in 1:nbClust){
      namSpi=names(meanprofile[which(t(summaryClusters["Mean",,i])>catchMeanThreshold)])
      numSpi=which(t(summaryClusters["Mean",,i])>catchMeanThreshold)
      nameSpPloti=rep("",nbSpec)
      nameSpPloti[numSpi]=namSpi
      nameSpPlot=rbind(nameSpPlot,nameSpPloti)
    }
    png(paste(analysisName,"Mean profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(t(summaryClusters["Mean",,i]), names.arg=nameSpPlot[i,], xlab="Species", ylab="Percentage of catch", col="gray")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Mean profile by cluster","\n","\n",sep=""))
    dev.off()
    
#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
      
    # Standard deviation profile by cluster
    sdprofil=matrix(0,nrow=nbClust,ncol=nbSpec)
    namSdPlot=character()
    SdThreshold=2
    for(i in 1:nbClust){
      if(length(which(clusters$cluster==i))==1){ sdprofilclusti=rep(0,nbSpec)
      }else{sdprofilclusti=sd(datSpecies[which(clusters$cluster==i),])}
      namSDi=names(which(sdprofilclusti>SdThreshold))
      numSDi=which(sdprofilclusti>SdThreshold)
      namSdPloti=rep("",nbSpec)
      namSdPloti[numSDi]=namSDi
      sdprofil[i,]=sdprofilclusti
      namSdPlot=rbind(namSdPlot,namSdPloti)
    }
    rownames(sdprofil) <- 1:nrow(sdprofil)
    png(paste(analysisName,"Standard deviation profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(sdprofil[i,], names.arg=namSdPlot[i,], xlab="Species", ylab="Percentage of catch")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Standard deviation profile by cluster","\n","\n",sep=""))
    dev.off()


    # Number of Logevents by cluster
    x=c(1:nbClust)
    png(paste(analysisName,"Number of Logevents by cluster.png",sep="_"), width = 1200, height = 800)
    coord=barplot(clusters$size, names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents")
    barplot(clusters$size, names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents", col="skyblue")
    text(coord,clusters$size+400,clusters$size,font=2,xpd=NA)
    dev.off()



    # Target Species profiles (test-value)
    targetresval=numeric()
    nameTargetPlot=character()
    for(i in 1:nbClust){
      nomtargeti=as.character(target$tabnomespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      numtargeti=as.numeric(target$tabnumespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      nameTargetPloti=rep("",nbSpec)
      nameTargetPloti[numtargeti]=nomtargeti
      nameTargetPlot=rbind(nameTargetPlot,nameTargetPloti)
      targetresvalclusti=rep(0,nbSpec)
      targetresvalclusti[numtargeti]=resval[nomtargeti,i]
      targetresval=rbind(targetresval,targetresvalclusti)
    }

    png(paste(analysisName,"Profile of target species by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(targetresval[i,], cex.names=1, names.arg=nameTargetPlot[i,], xlab="Species", ylab="Test-value")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Profile of target species by cluster","\n","\n",sep=""))
    dev.off()
    
    
    
        
    # Descriptive and summary tables of clusters
    clusterDesc=matrix(0,nrow=7,ncol=nbClust)
    for(i in 1:nbClust){
      clusterDesc[,i]=c(clusters$size[i], 
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<50))+1,
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<90))+1,
                        length(which(resval[,i]>1.98)),
                        length(which(resval[,i]>3.29)),
                        length(which(apply(datSpecies,2,function (x) (clusters$size[i]-length(which(x[clusters$cluster==i]==0)))/clusters$size[i]*100)>50)),
                        length(which(apply(datSpecies,2,function (x) (clusters$size[i]-length(which(x[clusters$cluster==i]==0)))/clusters$size[i]*100)>90)))
    }
    rownames(clusterDesc)=c("Clusters size","to have 50% of catch", "to have 90% of catch",
                            "with a test-value > 1.98", "with a test-value > 3.29",
                            "catch in 50% of the logevents", "catch in 90% of the logevents")
    colnames(clusterDesc)=1:nbClust                        
    clusterDesc2=as.data.frame(clusterDesc)
    
    
    namesSpecies=matrix(NA,nrow=nbClust,ncol=10)
    namesCapt=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesCatch = min(5,dim(t(summaryClusters["Mean",,]))[[2]])
    namesTarget=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesVT = min(5,dim(target$tabnomespcib)[[2]])
    
    for(i in 1:nbClust){
      namesCapt[i,]=colnames(t(summaryClusters["Mean",,i]))[order(t(summaryClusters["Mean",,i]),decreasing=T)][1:nbSpeciesCatch]
      a=as.data.frame(t(summaryClusters["Mean",target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])],i]))
      colnames(a)= target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])]
      namesTarget[i,1:length(target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])])]=colnames(a[order(a,decreasing=T)])
      namesSpecies[i,1:length(union(namesCapt[i,],namesTarget[i,]))]=union(namesCapt[i,],namesTarget[i,])
    }
    
    tabPropCatch=matrix(NA,nrow=nbClust,ncol=10)
    tabTestVal=matrix(NA,nrow=nbClust,ncol=10)
    tabPropLog=matrix(NA,nrow=nbClust,ncol=10)
    
    for(i in 1:nbClust){
      print("-----------------------------------------------------------------")
      print(paste("Cluster ",i))
      propCatch=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabPropCatch[i,1:length(propCatch)]=propCatch
      print(propCatch)
      testVal=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) resval[x,i]),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabTestVal[i,1:length(testVal)]=testVal
      print(testVal)
      propLog=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (clusters$size[i]-length(which(datSpecies[clusters$cluster==i,x]==0)))/clusters$size[i]*100),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (clusters$size[i]-length(which(datSpecies[clusters$cluster==i,x]==0)))/clusters$size[i]*100),digits=1)>=0.1)]
      tabPropLog[i,1:length(propLog)]=propLog
      print(propLog)
    }
    
    tabClusters=array(0,dim=c(10,4,nbClust))
    dimnames(tabClusters)[[2]]=c("FAO","Test-value","% Catch","% Logevents")
    dimnames(tabClusters)[[3]]=paste("Cluster ",1:nbClust)
    for(i in 1:nbClust){
      tabClusters[,,i]=cbind(namesSpecies[i,],tabTestVal[i,],tabPropCatch[i,],tabPropLog[i,])
    }
    
    sizeTabClusters=numeric()
    for(i in 1:nbClust){
      sizeTabClusters[i]=min(length(namesSpecies[i,!is.na(namesSpecies[i,])]),length(tabPropCatch[i,!is.na(tabPropCatch[i,])]),length(tabTestVal[i,!is.na(tabTestVal[i,])]),length(tabPropLog[i,!is.na(tabPropLog[i,])]))
    }
    
    db <- paste(analysisName,"_tables.xls",sep="")
    if(db %in% list.files()) file.remove(db)
    channel <- odbcConnectExcel(xls.file = db,readOnly=FALSE)
    sqlSave(channel, clusterDesc2, tablename = "DescClust")
    
    for(i in 1:nbClust){
      tabClusti=as.data.frame(tabClusters[1:sizeTabClusters[i],,i])
      sqlSave(channel, tabClusti, tablename = paste("Clust",i,sep=""),rownames = TRUE, colnames = TRUE)
    }
    odbcClose(channel)




    LE_ID_clust=cbind(LE_ID=LE_ID,clust=clusters$cluster)
    print(" --- end of step 3 ---")
    print(Sys.time()-t1)
    
    return(list(LE_ID_clust=LE_ID_clust, clusters=clusters, nameTarget=target$tabnomespcib, betweenVarClassifOnTot=betweenVarClassifOnTot, nbClust=nbClust, summaryClusters=summaryClusters, resval=resval, target=target))

  } else                                                                                                        





########################################################################################################################################   PAM

  if(methMetier=="pam"){

    # Calculation of optimal k thanks to the silhouette
    clustersPam.silcoeff=numeric()
    for (k in 2:15){
      clustersPam=pam(datLog,k)
      clustersPam.silcoeff[k]=clustersPam$silinfo$avg.width
    }

    png(paste(analysisName,"Silhouette of the classification.png",sep="_"), width = 1200, height = 800)
    plot(clustersPam.silcoeff, main="Silhouette of the classification", xlab="Number of clusters", ylab="Silhouette") # k optimal corresponds to maximum of silhouette's coefficients
    dev.off()

    clustersPam.silcoeff                                           
    max=max(clustersPam.silcoeff, na.rm=T)
    k=which(clustersPam.silcoeff==max)
    
#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
    # PAM with optimal k
    clusters=pam(datLog,k)
    summary(clusters)

#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
    # Quality of classification
    nbLog=nrow(datLog)
    centerOfGravityClassif=numeric()
    centerOfGravityDatLog=colMeans(datLog)
    centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravityDatLog)

    for(i in 1:k){
      clusti=datLog[which(clusters$clustering==i),]
      centerOfGravityClusti=colMeans(clusti)
      centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravityClusti)
    }
    classifBetweenVar=1/nbLog*sum(clusters$clusinfo[,1]*((dist(centerOfGravityClassif)[1:k])^2))
    classifWithinVar=1/nbLog*sum(clusters$clusinfo[,1]*clusters$clusinfo[,3])
    classifQuality=classifWithinVar/classifBetweenVar
    withinVarClustersOnTot=(clusters$clusinfo[,1]*clusters$clusinfo[,3]/nbLog)*100/(classifWithinVar+classifBetweenVar)
    betweenVarClassifOnTot=classifBetweenVar/(classifBetweenVar+classifWithinVar)*100
    

    # Compute the test-values for species
    resval=test.values(clusters$clustering,datSpecies)
    # Determine the target species
    target=targetspecies(resval)

    
    # Projections on the first factorial plans
    png(paste(analysisName,"Projections.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(2,3))
    plot(datLog[,1], datLog[,2], pch=21, bg=rainbow(length(clusters$id.med))[as.numeric(clusters$clustering)], main="Projection of PAM classification on the factorial plan 1-2", xlab="axis 1", ylab="axis 2")
    if(dim(datLog)[2]>2) {
    plot(datLog[,2], datLog[,3], pch=21, bg=rainbow(length(clusters$id.med))[as.numeric(clusters$clustering)], main="Projection of PAM classification on the factorial plan 2-3", xlab="axis 2", ylab="axis 3")
    plot(datLog[,1], datLog[,3], pch=21, bg=rainbow(length(clusters$id.med))[as.numeric(clusters$clustering)], main="Projection of PAM classification on the factorial plan 1-3", xlab="axis 1", ylab="axis 3")
    if(dim(datLog)[2]>3) {
    plot(datLog[,1], datLog[,4], pch=21, bg=rainbow(length(clusters$id.med))[as.numeric(clusters$clustering)], main="Projection of PAM classification on the factorial plan 1-4", xlab="axis 1", ylab="axis 4")
    plot(datLog[,2], datLog[,4], pch=21, bg=rainbow(length(clusters$id.med))[as.numeric(clusters$clustering)], main="Projection of PAM classification on the factorial plan 2-4", xlab="axis 2", ylab="axis 4")
    plot(datLog[,3], datLog[,4], pch=21, bg=rainbow(length(clusters$id.med))[as.numeric(clusters$clustering)], main="Projection of PAM classification on the factorial plan 3-4", xlab="axis 3", ylab="axis 4")
    }}
    par(op)
    dev.off()

    
    # Mean profile of the dataset
    meanprofile=colMeans(datSpecies)
    png(paste(analysisName,"Mean profile of the dataset.png",sep="_"), width = 1200, height = 800)
    op <- par(las=2)
    barplot(meanprofile, main="Mean profile of the dataset", xlab="Species", ylab="Percentage of catch")
    par(op)
    mtext(paste(nrow(datSpecies)," logevents"), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    dev.off()


    # Mean profile by cluster
    nbClust=length(clusters$id.med)
    nbSpec=ncol(datSpecies)
    summaryClusters=array(0,dim=c(6,nbSpec,nbClust))
    dimnames(summaryClusters)[[1]]=c("Min.","1st Qu.","Median", "Mean", "3rd Qu.", "Max.")
    dimnames(summaryClusters)[[2]]=names(meanprofile)
    dimnames(summaryClusters)[[3]]=paste("Cluster ",1:nbClust)  
    for(i in 1:nbClust){
      if(clusters$clusinfo[i,1]==1){
        summaryClusters[,,i]=apply(t(as.matrix(datSpecies[which(clusters$clustering==i),])),2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }else{
        summaryClusters[,,i]=apply(datSpecies[which(clusters$clustering==i),],2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }
    }
    # Species names for mean profile plots
    nameSpPlot=character()
    catchMeanThreshold=2
    for(i in 1:nbClust){
      namSpi=names(meanprofile[which(t(summaryClusters["Mean",,i])>catchMeanThreshold)])
      numSpi=which(t(summaryClusters["Mean",,i])>catchMeanThreshold)
      nameSpPloti=rep("",nbSpec)
      nameSpPloti[numSpi]=namSpi
      nameSpPlot=rbind(nameSpPlot,nameSpPloti)
    }
    png(paste(analysisName,"Mean profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(t(summaryClusters["Mean",,i]), names.arg=nameSpPlot[i,], xlab="Species", ylab="Percentage of catch", col="gray")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Mean profile by cluster","\n","\n",sep=""))
    dev.off()
    
    
#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)
    
      
    # Standard deviation profile by cluster
    sdprofil=matrix(0,nrow=nbClust,ncol=nbSpec)
    namSdPlot=character()
    SdThreshold=2
    for(i in 1:nbClust){
      if(length(which(clusters$clustering==i))==1){ sdprofilclusti=rep(0,nbSpec)
      }else{sdprofilclusti=sd(datSpecies[which(clusters$clustering==i),])}
      namSDi=names(which(sdprofilclusti>SdThreshold))
      numSDi=which(sdprofilclusti>SdThreshold)
      namSdPloti=rep("",nbSpec)
      namSdPloti[numSDi]=namSDi
      sdprofil[i,]=sdprofilclusti
      namSdPlot=rbind(namSdPlot,namSdPloti)
    }
    rownames(sdprofil) <- 1:nrow(sdprofil)
    png(paste(analysisName,"Standard deviation profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(sdprofil[i,], names.arg=namSdPlot[i,], xlab="Species", ylab="Percentage of catch")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Standard deviation profile by cluster","\n","\n",sep=""))
    dev.off()
    


    # Number of Logevents by cluster
    x=c(1:nbClust)
    png(paste(analysisName,"Number of Logevents by cluster.png",sep="_"), width = 1200, height = 800)
    coord=barplot(clusters$clusinfo[,1], names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents")
    barplot(clusters$clusinfo[,1], names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents", col="skyblue")
    text(coord,clusters$clusinfo[,1]+200,clusters$clusinfo[,1],font=2,xpd=NA)
    dev.off()


    # Target Species profile (test-value) by cluster
    targetresval=numeric()
    nameTargetPlot=character()
    for(i in 1:nbClust){
      nomtargeti=as.character(target$tabnomespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      numtargeti=as.numeric(target$tabnumespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      nameTargetPloti=rep("",nbSpec)
      nameTargetPloti[numtargeti]=nomtargeti
      nameTargetPlot=rbind(nameTargetPlot,nameTargetPloti)
      targetresvalclusti=rep(0,nbSpec)
      targetresvalclusti[numtargeti]=resval[nomtargeti,i]
      targetresval=rbind(targetresval,targetresvalclusti)
    }

    png(paste(analysisName,"Profile of target species by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(targetresval[i,],names.arg=nameTargetPlot[i,], xlab="Species", ylab="Test-value")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Profile of target species by cluster","\n","\n",sep=""))
    dev.off()



    # Descriptive and summary tables of clusters
    clusterDesc=matrix(0,nrow=7,ncol=nbClust)
    for(i in 1:nbClust){
      clusterDesc[,i]=c(clusters$clusinfo[i,1], 
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<50))+1,
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<90))+1,
                        length(which(resval[,i]>1.98)),
                        length(which(resval[,i]>3.29)),
                        length(which(apply(datSpecies,2,function (x) (clusters$clusinfo[i,1]-length(which(x[clusters$clustering==i]==0)))/clusters$clusinfo[i,1]*100)>50)),
                        length(which(apply(datSpecies,2,function (x) (clusters$clusinfo[i,1]-length(which(x[clusters$clustering==i]==0)))/clusters$clusinfo[i,1]*100)>90)))
    }
    rownames(clusterDesc)=c("Clusters size","to have 50% of catch", "to have 90% of catch",
                            "with a test-value > 1.98", "with a test-value > 3.29",
                            "catch in 50% of the logevents", "catch in 90% of the logevents")
    colnames(clusterDesc)=1:nbClust                        
    clusterDesc2=as.data.frame(clusterDesc)
    
    
    namesSpecies=matrix(NA,nrow=nbClust,ncol=10)
    namesCapt=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesCatch = min(5,dim(t(summaryClusters["Mean",,]))[[2]])
    namesTarget=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesVT = min(5,dim(target$tabnomespcib)[[2]])
    
    for(i in 1:nbClust){
      namesCapt[i,]=colnames(t(summaryClusters["Mean",,i]))[order(t(summaryClusters["Mean",,i]),decreasing=T)][1:nbSpeciesCatch]
      a=as.data.frame(t(summaryClusters["Mean",target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])],i]))
      colnames(a)= target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])]
      namesTarget[i,1:length(target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])])]=colnames(a[order(a,decreasing=T)])
      namesSpecies[i,1:length(union(namesCapt[i,],namesTarget[i,]))]=union(namesCapt[i,],namesTarget[i,])
    }
    
    tabPropCatch=matrix(NA,nrow=nbClust,ncol=10)
    tabTestVal=matrix(NA,nrow=nbClust,ncol=10)
    tabPropLog=matrix(NA,nrow=nbClust,ncol=10)
    
    for(i in 1:nbClust){
      print("-----------------------------------------------------------------")
      print(paste("Cluster ",i))
      propCatch=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabPropCatch[i,1:length(propCatch)]=propCatch
      print(propCatch)
      testVal=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) resval[x,i]),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabTestVal[i,1:length(testVal)]=testVal
      print(testVal)
      propLog=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (clusters$clusinfo[i,1]-length(which(datSpecies[clusters$clustering==i,x]==0)))/clusters$clusinfo[i,1]*100),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (clusters$clusinfo[i,1]-length(which(datSpecies[clusters$clustering==i,x]==0)))/clusters$clusinfo[i,1]*100),digits=1)>=0.1)]
      tabPropLog[i,1:length(propLog)]=propLog
      print(propLog)
    }
    
    tabClusters=array(0,dim=c(10,4,nbClust))
    dimnames(tabClusters)[[2]]=c("FAO","Test-value","% Catch","% Logevents")
    dimnames(tabClusters)[[3]]=paste("Cluster ",1:nbClust)
    for(i in 1:nbClust){
      tabClusters[,,i]=cbind(namesSpecies[i,],tabTestVal[i,],tabPropCatch[i,],tabPropLog[i,])
    }
    
    sizeTabClusters=numeric()
    for(i in 1:nbClust){
      sizeTabClusters[i]=min(length(namesSpecies[i,!is.na(namesSpecies[i,])]),length(tabPropCatch[i,!is.na(tabPropCatch[i,])]),length(tabTestVal[i,!is.na(tabTestVal[i,])]),length(tabPropLog[i,!is.na(tabPropLog[i,])]))
    }
    
    db <- paste(analysisName,"_tables.xls",sep="")
    if(db %in% list.files()) file.remove(db)
    channel <- odbcConnectExcel(xls.file = db,readOnly=FALSE)
    sqlSave(channel, clusterDesc2, tablename = "DescClust")
    
    for(i in 1:nbClust){
      tabClusti=as.data.frame(tabClusters[1:sizeTabClusters[i],,i])
      sqlSave(channel, tabClusti, tablename = paste("Clust",i,sep=""),rownames = TRUE, colnames = TRUE)
    }
    odbcClose(channel)
    
    
    LE_ID_clust=cbind(LE_ID=LE_ID,clust=clusters$clustering)
    print(" --- end of step 3 ---")
    print(Sys.time()-t1)

    return(list(LE_ID_clust=LE_ID_clust, clusters=clusters, nameTarget=target$tabnomespcib, betweenVarClassifOnTot=betweenVarClassifOnTot, nbClust=nbClust, summaryClusters=summaryClusters, resval=resval, target=target))

  } else 





########################################################################################################################################   CLARA

  if(methMetier=="clara"){
    nbLog=nrow(datLog)

    # Calculation of optimal k thanks to the silhouette
    clustersClara.silcoeff=numeric()
    for (k in 3:15){
      clustersClara=clara(datLog, k, metric=param3, stand=F, samples=10, sampsize=min(nbLog,round(0.01*nbLog+10*k)))
      clustersClara.silcoeff[k]=clustersClara$silinfo$avg.width
    }

    png(paste(analysisName,"Silhouette of the classification.png",sep="_"), width = 1200, height = 800)
    plot(clustersClara.silcoeff, main="Silhouette of the classification", xlab="Number of clusters", ylab="Silhouette")               # k optimal corresponds to maximum of silhouette's coefficients
    dev.off()
    
    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
    gc(reset=TRUE)

    cat("silcoeff",clustersClara.silcoeff,"\n")
    
    k=which.max(clustersClara.silcoeff)
    
    # CLARA with optimal k
    clusters=clara(datLog, k, metric=param3, stand=F, samples=10, sampsize=min(nbLog,round(0.01*nbLog+10*k)))  # CLARA with optimal k
    summary(clusters)

#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)


    # Quality of classification
    centerOfGravityClassif=numeric()
    centerOfGravityDatLog=colMeans(datLog)
    centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravityDatLog)

    for(i in 1:k){
      clusti=datLog[which(clusters$clustering==i),]
      centerOfGravityClusti=colMeans(clusti)
      centerOfGravityClassif=rbind(centerOfGravityClassif,centerOfGravityClusti)
    }
    classifBetweenVar=1/nbLog*sum(clusters$clusinfo[,1]*((dist(centerOfGravityClassif)[1:k])^2))
    classifWithinVar=1/nbLog*sum(clusters$clusinfo[,1]*clusters$clusinfo[,3])
    classifQuality=classifWithinVar/classifBetweenVar
    withinVarClustersOnTot=(clusters$clusinfo[,1]*clusters$clusinfo[,3]/nbLog)*100/(classifWithinVar+classifBetweenVar)
    betweenVarClassifOnTot=classifBetweenVar/(classifBetweenVar+classifWithinVar)*100


#    Store(objects()[-which(objects() %in% c('dat','methSpecies','param1','param2','pcaYesNo','methMetier','param3','param4'))])
#    gc(reset=TRUE)


    # Compute the test-values for species
    resval=test.values(clusters$cluster,datSpecies)
    # Determine the target species
    target=targetspecies(resval)
    
    # Projections on the first factorial plans
    png(paste(analysisName,"Projections.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(2,3))
    plot(datLog[,1], datLog[,2], pch=21, bg=rainbow(length(clusters$i.med))[as.numeric(clusters$clustering)], main="Projection of CLARA classification on the factorial plan 1-2", xlab="axis 1", ylab="axis 2")
    if(dim(datLog)[2]>2) {
    plot(datLog[,2], datLog[,3], pch=21, bg=rainbow(length(clusters$i.med))[as.numeric(clusters$clustering)], main="Projection of CLARA classification on the factorial plan 2-3", xlab="axis 2", ylab="axis 3")
    plot(datLog[,1], datLog[,3], pch=21, bg=rainbow(length(clusters$i.med))[as.numeric(clusters$clustering)], main="Projection of CLARA classification on the factorial plan 1-3", xlab="axis 1", ylab="axis 3")
    if(dim(datLog)[2]>3) {
    plot(datLog[,1], datLog[,4], pch=21, bg=rainbow(length(clusters$i.med))[as.numeric(clusters$clustering)], main="Projection of CLARA classification on the factorial plan 1-4", xlab="axis 1", ylab="axis 4")
    plot(datLog[,2], datLog[,4], pch=21, bg=rainbow(length(clusters$i.med))[as.numeric(clusters$clustering)], main="Projection of CLARA classification on the factorial plan 2-4", xlab="axis 2", ylab="axis 4")
    plot(datLog[,3], datLog[,4], pch=21, bg=rainbow(length(clusters$i.med))[as.numeric(clusters$clustering)], main="Projection of CLARA classification on the factorial plan 3-4", xlab="axis 3", ylab="axis 4")
    }}
    par(op)
    dev.off()


    # Mean profile of the dataset
    meanprofile=colMeans(datSpecies)
    png(paste(analysisName,"Mean profile of the dataset.png",sep="_"), width = 1200, height = 800)
    op <- par(las=2)
    barplot(meanprofile, main="Mean profile of the dataset", xlab="Species", ylab="Percentage of catch")
    par(op)
    mtext(paste(nrow(datSpecies)," logevents"), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    dev.off()


    # Mean profile by cluster
    nbClust=length(clusters$i.med)
    nbSpec=ncol(datSpecies)
    summaryClusters=array(0,dim=c(6,nbSpec,nbClust))
    dimnames(summaryClusters)[[1]]=c("Min.","1st Qu.","Median", "Mean", "3rd Qu.", "Max.")
    dimnames(summaryClusters)[[2]]=names(meanprofile)
    dimnames(summaryClusters)[[3]]=paste("Cluster ",1:nbClust)
    for(i in 1:nbClust){
      if(clusters$clusinfo[i,1]==1){
        summaryClusters[,,i]=apply(t(as.matrix(datSpecies[which(clusters$clustering==i),])),2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }else{
        summaryClusters[,,i]=apply(datSpecies[which(clusters$clustering==i),],2, 
          function(x) rbind(min(as.vector(x)),quantile(as.vector(x),0.25),quantile(as.vector(x),0.50),mean(as.vector(x)),quantile(as.vector(x),0.75),max(as.vector(x))))
      }
    }
    # Species names for mean profile plots
    nameSpPlot=character()
    catchMeanThreshold=2
    for(i in 1:nbClust){
      namSpi=names(meanprofile[which(t(summaryClusters["Mean",,i])>catchMeanThreshold)])
      numSpi=which(t(summaryClusters["Mean",,i])>catchMeanThreshold)
      nameSpPloti=rep("",nbSpec)
      nameSpPloti[numSpi]=namSpi
      nameSpPlot=rbind(nameSpPlot,nameSpPloti)
    }
    png(paste(analysisName,"Mean profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(t(summaryClusters["Mean",,i]), names.arg=nameSpPlot[i,], xlab="Species", ylab="Percentage of catch", col="gray")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Mean profile by cluster","\n","\n",sep=""))
    dev.off()

    
    # Standard deviation profile by cluster
    sdprofil=matrix(0,nrow=nbClust,ncol=nbSpec)
    namSdPlot=character()
    SdThreshold=5
    for(i in 1:nbClust){
      if(length(which(clusters$clustering==i))==1){ sdprofilclusti=rep(0,nbSpec)
      }else{sdprofilclusti=sd(datSpecies[which(clusters$clustering==i),])}
      namSDi=names(which(sdprofilclusti>SdThreshold))
      numSDi=which(sdprofilclusti>SdThreshold)
      namSdPloti=rep("",nbSpec)
      namSdPloti[numSDi]=namSDi
      sdprofil[i,]=sdprofilclusti
      namSdPlot=rbind(namSdPlot,namSdPloti)
    }
    rownames(sdprofil) <- 1:nrow(sdprofil)
    png(paste(analysisName,"Standard deviation profile by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(sdprofil[i,], names.arg=namSdPlot[i,], xlab="Species", ylab="Percentage of catch")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Standard deviation profile by cluster","\n","\n",sep=""))
    dev.off()
    

    # Number of Logevents by cluster
    x=c(1:nbClust)
    png(paste(analysisName,"Number of Logevents by cluster.png",sep="_"), width = 1200, height = 800)
    coord=barplot(clusters$clusinfo[,1], names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents")
    barplot(clusters$clusinfo[,1], names.arg=x, main="Number of Logevents by cluster", xlab="Cluster", ylab="Number of Logevents", col="skyblue")
    text(coord,clusters$clusinfo[,1]+400,clusters$clusinfo[,1],font=2,xpd=NA)
    dev.off()


    # Target Species profile (test-value) by cluster
    targetresval=matrix(0,nrow=nbClust,ncol=nbSpec)
    colnames(targetresval)=colnames(datSpecies)
    rownames(targetresval)=1:nbClust
    nameTargetPlot=matrix(NA,nrow=nbClust,ncol=nbSpec)
    for(i in 1:nbClust){
      nomtargeti=as.character(target$tabnomespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      numtargeti=as.numeric(target$tabnumespcib[i,which(!is.na(target$tabnumespcib[i,]))])
      nameTargetPlot[i,numtargeti]=nomtargeti
      targetresval[i,numtargeti]=resval[nomtargeti,i]
    }

    png(paste(analysisName,"Profile of target species by cluster.png",sep="_"), width = 1200, height = 800)
    op <- par(mfrow=c(ceiling(sqrt(nbClust)),round(sqrt(nbClust))))
    for(i in 1:nbClust){
      op2 <- par(las=2)
      barplot(targetresval[i,],names.arg=nameTargetPlot[i,], xlab="Species", ylab="Test-value")
      par(op2)
      mtext(paste("Cluster",i), side=3, outer=F, adj=0.5, line=0.5, col="darkblue")
    }
    par(op)
    title(main=paste("Profile of target species by cluster","\n","\n",sep=""))
    dev.off()
    
    
    
    # Descriptive and summary tables of clusters
    clusterDesc=matrix(0,nrow=7,ncol=nbClust)
    for(i in 1:nbClust){
      clusterDesc[,i]=c(clusters$clusinfo[i,1], 
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<50))+1,
                        length(which(cumsum(t(summaryClusters["Mean",,i])[order(t(summaryClusters["Mean",,i]),decreasing=T)])<90))+1,
                        length(which(resval[,i]>1.98)),
                        length(which(resval[,i]>3.29)),
                        length(which(apply(datSpecies,2,function (x) (clusters$clusinfo[i,1]-length(which(x[clusters$clustering==i]==0)))/clusters$clusinfo[i,1]*100)>50)),
                        length(which(apply(datSpecies,2,function (x) (clusters$clusinfo[i,1]-length(which(x[clusters$clustering==i]==0)))/clusters$clusinfo[i,1]*100)>90)))
    }
    rownames(clusterDesc)=c("Clusters size","to have 50% of catch", "to have 90% of catch",
                            "with a test-value > 1.98", "with a test-value > 3.29",
                            "catch in 50% of the logevents", "catch in 90% of the logevents")
    colnames(clusterDesc)=1:nbClust                        
    clusterDesc2=as.data.frame(clusterDesc)
    
    
    namesSpecies=matrix(NA,nrow=nbClust,ncol=10)
    namesCapt=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesCatch = min(5,dim(t(summaryClusters["Mean",,]))[[2]])
    namesTarget=matrix(NA,nrow=nbClust,ncol=5)
    nbSpeciesVT = min(5,dim(target$tabnomespcib)[[2]])
    
    for(i in 1:nbClust){
      namesCapt[i,]=colnames(t(summaryClusters["Mean",,i]))[order(t(summaryClusters["Mean",,i]),decreasing=T)][1:nbSpeciesCatch]
      a=as.data.frame(t(summaryClusters["Mean",target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])],i]))
      colnames(a)= target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])]
      namesTarget[i,1:length(target$tabnomespcib[i,1:nbSpeciesVT][!is.na(target$tabnomespcib[i,1:nbSpeciesVT])])]=colnames(a[order(a,decreasing=T)])
      namesSpecies[i,1:length(union(namesCapt[i,],namesTarget[i,]))]=union(namesCapt[i,],namesTarget[i,])
    }
    
    tabPropCatch=matrix(NA,nrow=nbClust,ncol=10)
    tabTestVal=matrix(NA,nrow=nbClust,ncol=10)
    tabPropLog=matrix(NA,nrow=nbClust,ncol=10)
    
    for(i in 1:nbClust){
      print("-----------------------------------------------------------------")
      print(paste("Cluster ",i))
      propCatch=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabPropCatch[i,1:length(propCatch)]=propCatch
      print(propCatch)
      testVal=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) resval[x,i]),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) t(summaryClusters["Mean",x,i])),digits=1)>=0.1)]
      tabTestVal[i,1:length(testVal)]=testVal
      print(testVal)
      propLog=round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (clusters$clusinfo[i,1]-length(which(datSpecies[clusters$clustering==i,x]==0)))/clusters$clusinfo[i,1]*100),digits=1)[which(round(sapply(namesSpecies[i,][!is.na(namesSpecies[i,])],function(x) (clusters$clusinfo[i,1]-length(which(datSpecies[clusters$clustering==i,x]==0)))/clusters$clusinfo[i,1]*100),digits=1)>=0.1)]
      tabPropLog[i,1:length(propLog)]=propLog
      print(propLog)
    }
    
    tabClusters=array(0,dim=c(10,4,nbClust))
    dimnames(tabClusters)[[2]]=c("FAO","Test-value","% Catch","% Logevents")
    dimnames(tabClusters)[[3]]=paste("Cluster ",1:nbClust)
    for(i in 1:nbClust){
      tabClusters[,,i]=cbind(namesSpecies[i,],tabTestVal[i,],tabPropCatch[i,],tabPropLog[i,])
    }
    
    sizeTabClusters=numeric()
    for(i in 1:nbClust){
      sizeTabClusters[i]=min(length(namesSpecies[i,!is.na(namesSpecies[i,])]),length(tabPropCatch[i,!is.na(tabPropCatch[i,])]),length(tabTestVal[i,!is.na(tabTestVal[i,])]),length(tabPropLog[i,!is.na(tabPropLog[i,])]))
    }
    
    db <- paste(analysisName,"_tables.xls",sep="")
    if(db %in% list.files()) file.remove(db)
    channel <- odbcConnectExcel(xls.file = db,readOnly=FALSE)
    sqlSave(channel, clusterDesc2, tablename = "DescClust")
    
    for(i in 1:nbClust){
      tabClusti=as.data.frame(tabClusters[1:sizeTabClusters[i],,i])
      sqlSave(channel, tabClusti, tablename = paste("Clust",i,sep=""),rownames = TRUE, colnames = TRUE)
    }
    odbcClose(channel)


    
    LE_ID_clust=cbind(LE_ID=le_id,clust=clusters$clustering)
    print(" --- end of step 3 ---")
    print(Sys.time()-t1)

    return(list(LE_ID_clust=LE_ID_clust, clusters=clusters, nameTarget=target$tabnomespcib, betweenVarClassifOnTot=betweenVarClassifOnTot, nbClust=nbClust, summaryClusters=summaryClusters, resval=resval, target=target))

  }  else stop("methMetier must be hac, kmeans, pam or clara")
  # end of the methods
  
  
} # end of the function "classif step2"