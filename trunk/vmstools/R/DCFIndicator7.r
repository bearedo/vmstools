## DCFIndicator7.r
## by Fabrizio Manco, 23/09/2010
## calculates the DCF7 indicator : area of cells not containing activity

DCFIndicator7 <- function ( vmsWithGear,
                            mobileBottomGear="",          # a list of gear code
                            inShapeArea="",               # the name of the shapefile without the .shp extension
                            cellresX=0.05,
                            cellresY=0.05,
                            calcAreaMethod="trapezoid",   # "trapezoid" (fast and less accurate, good for small cellsizes) or "UTMproj" (accurate but slow, good for huge cellsizes)
                            minThreshold=10,              # if time interval has been calculated (and named SI_INTV), it's a minimal nb of minutes, otherwise, it's minimal number of points
                            plotMapTF = FALSE
                            )          

{ require(shapefiles)
  require(sp)
  vmsWithGear<-vmsWithGear[complete.cases(vmsWithGear),]
  if (mobileBottomGear!="") {vmsWithGear<-subset(vmsWithGear, vmsWithGear$SI_GEAR %in% mobileBottomGear)}

  if (inShapeArea!="")
    { # read the shapefile 

      shapeAll<-read.shapefile(inShapeArea)
    
      vmsPingsCoord<-cbind(vmsWithGear$SI_LONG, vmsWithGear$SI_LATI)
      
      for (x in 1:length(shapeAll$shp$shp)){
        
        polyCoord<-cbind(shapeAll$shp$shp[[x]]$points$X,shapeAll$shp$shp[[x]]$points$Y)
        if (x==1) {pointInOutByPoly<-point.in.polygon(vmsPingsCoord[,1], vmsPingsCoord[,2], polyCoord[,1], polyCoord[,2])} else { pointInOutByPoly <- pointInOutByPoly + (point.in.polygon(vmsPingsCoord[,1], vmsPingsCoord[,2], polyCoord[,1], polyCoord[,2]))}
        }
        

      vmsWithGear$pointInOut<-pointInOutByPoly
      vmsWithGear<-subset(vmsWithGear, pointInOut==1)
      }
  
  # Grid the points
  if ("SI_INTV" %in% colnames(vmsWithGear)) { nameVarToSum="SI_INTV"} else {nameVarToSum=""}
  vmsGrid<-vmsGridCreate(vmsWithGear, nameLon = "SI_LONG", nameLat = "SI_LATI", cellsizeX=cellresX, cellsizeY=cellresY, nameVarToSum, plotMap=plotMapTF, plotPoints = FALSE)
  
  # calculate the area of each cell in square km
  if (calcAreaMethod=="trapezoid") {vmsGrid<-surface(vmsGrid)} else 
    {if (calcAreaMethod=="UTMproj") {vmsGrid<-calcAreaOfCells(vmsGrid, includeNA=TRUE)} else 
      {stop("You must choose a cell area calculation method between 'trapezoid' and 'UTMproj'")}}
                                                                     
  if (inShapeArea!="")
    { # read the shapefile   
      # specify which grid cell is in the polygon
      gridPointsCoord<-coordinates(vmsGrid)
      for (x in 1:length(shapeAll$shp$shp)){
        
            polyCoord<-cbind(shapeAll$shp$shp[[x]]$points$X,shapeAll$shp$shp[[x]]$points$Y)
            if (x==1) {gridCellInOutByPoly<-point.in.polygon(gridPointsCoord[,1], gridPointsCoord[,2], polyCoord[,1], polyCoord[,2])} else { gridCellInOutByPoly <- gridCellInOutByPoly + (point.in.polygon(gridPointsCoord[,1], gridPointsCoord[,2], polyCoord[,1], polyCoord[,2]))}
          }
  
      vmsGrid$inPolygon<-gridCellInOutByPoly
      areaInPolygon<-sum(vmsGrid@data$cellArea[vmsGrid@data$inPolygon>0])
      } else {areaInPolygon<-sum(vmsGrid@data$cellArea)}
      
  # calculate the areas  
  areaFishing<-sum(vmsGrid@data$cellArea[!is.na(vmsGrid@data$fishing) & vmsGrid@data$fishing>minThreshold])

  
  # calculate the result
  resultDCF7<-areaInPolygon-areaFishing
  
  return(resultDCF7)
}


  
  