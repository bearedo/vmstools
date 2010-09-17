pointInHarbour <- function(lon,lat,harbours,rowSize=30){

    xharb     <- unlist(lapply(harbours,function(x){return(x[,"lon"])}))
    yharb     <- unlist(lapply(harbours,function(x){return(x[,"lat"])}))
    rharb     <- unlist(lapply(harbours,function(x){return(x[,"range"])}))
    harb      <- cbind(xharb,yharb,rharb)
    harb      <- orderBy(~xharb+yharb,data=harb)

    nChunks   <- ceiling(length(lon)/rowSize)
    store     <- numeric(length(lon))
    for(chunks in 1:nChunks){
      if(chunks == nChunks){
        x1    <- lon[(chunks*rowSize-rowSize+1):length(lon)]
        y1    <- lat[(chunks*rowSize-rowSize+1):length(lon)]
      } else {
          x1    <- lon[(chunks*rowSize-rowSize+1):(chunks*rowSize)]
          y1    <- lat[(chunks*rowSize-rowSize+1):(chunks*rowSize)]
        }

      xr        <- range(x1,na.rm=T); xr <- c(xr[1]-0.05,xr[2]+0.05)
      yr        <- range(y1,na.rm=T); yr <- c(yr[1]-0.05,yr[2]+0.05)
      res1      <- which(harb[,"xharb"] >= xr[1] & harb[,"xharb"] <= xr[2])
      res2      <- which(harb[,"yharb"] >= yr[1] & harb[,"yharb"] <= yr[2])
      res3      <- res1[which(is.na(pmatch(res1,res2))==F)]

      if(length(res3)>0){
        for(hars in res3){
          #print(hars)
          x2  <- harb[hars,"xharb"]
          y2  <- harb[hars,"yharb"]

          pd  <- pi/180

          a1  <- sin(((y2-y1)*pd)/2)
          a2  <- cos(y1*pd)
          a3  <- cos(y2*pd)
          a4  <- sin(((x2-x1)*pd)/2)
          a   <- a1*a1+a2*a3*a4*a4

          c   <- 2*atan2(sqrt(a),sqrt(1-a));
          R   <- 6371;
          dx1 <- R*c

          res <- numeric(length(x1))
          res[which(dx1<=harb[hars,"rharb"])] <- 1

          if(chunks==nChunks){ store[(chunks*rowSize-rowSize+1):length(lon)]  <- pmax(store[(chunks*rowSize-rowSize+1):length(lon)],res,na.rm=T)
          } else { store[(chunks*rowSize-rowSize+1):(chunks*rowSize)]         <- pmax(store[(chunks*rowSize-rowSize+1):(chunks*rowSize)],res,na.rm=T)}
        }
      }
    }

return(store)}
    


