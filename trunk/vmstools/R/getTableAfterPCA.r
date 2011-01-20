################################################################################
#  STEP 2 OF THE MULTIVARIATE CLASSIFICATION :                                 #
#         RUN A PCA ON THE DATASET FROM STEP 1                                 #
#         (2 CRITERIA : 70PERCENTS AND SCREETEST ARE AVAILABLE)                #
#         IT'S POSSIBLE TO KEEP THE DATASET FROM STEP 1 BY CHOOSING "NOPCA"    #
################################################################################


getTableAfterPCA = function(datSpecies,analysisName="",pcaYesNo="pca",criterion="70percents"){
  #LE_ID <- datSpecies[,1]
  LE_ID <- rownames(datSpecies)
  NbSpecies <- dim(datSpecies)[2]
  #datSpecies <- datSpecies[,-1]
  datSpecies <- as.matrix(datSpecies,ncol=NbSpecies,nrow=length(LE_ID))


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

