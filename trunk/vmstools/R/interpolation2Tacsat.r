
interpolation2Tacsat <- function(interpolation,tacsat,npoints=10){

# This function takes the list of tracks output by interpolateTacsat and converts them back to tacsat format.
# The npoints argument is the optional number of points between each 'real' position.

if(!"SI_DATIM" %in% colnames(tacsat)) tacsat$SI_DATIM  <- as.POSIXct(paste(tacsat$SI_DATE,  tacsat$SI_TIME,   sep=" "), tz="GMT", format="%d/%m/%Y  %H:%M")
interpolationEQ <- equalDistance(interpolation,npoints)  #Divide points equally along interpolated track (default is 10).

res <- lapply(interpolationEQ,function(x){
                                  idx                     <- x[1,]; x <- data.frame(x)
                                  colnames(x)             <- c("SI_LONG","SI_LATI")
                                  cls                     <- which(apply(tacsat[idx,],2,function(y){return(length(unique(y)))})==1)
                                  for(i in cls){
                                    x           <- cbind(x,rep(tacsat[idx[1],i],nrow(x)));
                                    colnames(x) <- c(colnames(x)[1:(ncol(x)-1)],colnames(tacsat)[i])
                                  }
                                  if(!"VE_COU" %in% colnames(x)) x$VE_COU                <- rep(tacsat$VE_COU[idx[1]],nrow(x))
                                  if(!"VE_REF" %in% colnames(x)) x$VE_REF                <- rep(tacsat$VE_REF[idx[1]],nrow(x))
                                  if(!"FT_REF" %in% colnames(x)) x$FT_REF                <- rep(tacsat$FT_REF[idx[1]],nrow(x))
                                  x$SI_DATIM              <- tacsat$SI_DATIM[idx[1]]
                                  x$SI_DATIM[-c(1:2)]     <- as.POSIXct(cumsum(rep(difftime(tacsat$SI_DATIM[idx[2]],tacsat$SI_DATIM[idx[1]],unit="secs")/(nrow(x)-2),nrow(x)-2))+tacsat$SI_DATIM[idx[1]],tz="GMT",format = "%d/%m/%Y  %H:%M")
                                  x$SI_DATE               <- format(x$SI_DATIM,format="%d/%m/%Y")
                                  timeNotation            <- ifelse(length(unlist(strsplit(tacsat$SI_TIME[1],":")))>2,"secs","mins")
                                  if(timeNotation == "secs") x$SI_TIME  <- format(x$SI_DATIM,format="%H:%M:%S")
                                  if(timeNotation == "mins") x$SI_TIME  <- format(x$SI_DATIM,format="%H:%M")
                                  x$SI_SP                 <- mean(c(tacsat$SI_SP[idx[1]],tacsat$SI_SP[idx[2]]),na.rm=T)
                                  x$SI_HE                 <- NA;
                                  x$SI_HE[-c(1,nrow(x))]  <- bearing(x$SI_LONG[3:nrow(x)],x$SI_LATI[3:nrow(x)],x$SI_LONG[2:(nrow(x)-1)],x$SI_LATI[2:(nrow(x)-1)])
                                return(x[-c(1,2,nrow(x)),])})

#interpolationTot  <- do.call(rbind,res)
interpolationTot  <- res[[1]][,which(duplicated(colnames(res[[1]]))==F)]
if(length(res)>1) for(i in 2:length(res)) interpolationTot  <- rbindTacsat(interpolationTot,res[[i]][,which(duplicated(colnames(res[[i]]))==F)])
#tacsatInt         <- rbind(interpolationTot,tacsat[,colnames(interpolationTot)])
tacsatInt         <- rbindTacsat(tacsat,interpolationTot)
tacsatInt         <- sortTacsat(tacsatInt)

return(tacsatInt)

}
