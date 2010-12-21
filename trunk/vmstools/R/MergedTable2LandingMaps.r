 # Author: F.Bastardie
  MergedTable2LandingMaps <-
     function (all.merged, sp="LE_KG_COD", output= file.path("C:","VMSanalysis", "FemernBelt"),
        cellsizeX =0.05, cellsizeY =0.05, we=9.8, ea=12.7, no=55.2, so=54.0,
          breaks0= c(0,100, 100*(2^1),100*(2^2),100*(2^3),100*(2^4),100*(2^5),100*(2^6), 100*(2^7),100*(2^8),100*(2^9), 10000000)){

    if(!"quarter" %in% colnames(all.merged))
          stop("please add a 'quarter' column to the merged table")

    dir.create(file.path(output, "jpegLandings"))

    a.year <- format(strptime( paste(all.merged$SI_DATE[1]) , tz='GMT',  "%e/%m/%Y" ), "%Y")

    if (any(grep("EURO", sp)>0)) what <- "value"
    if (any(grep("KG", sp)>0))  what <- "weight"

    if(what=="weight") a.unit <- "(KG)"
    if(what=="value") a.unit <- "(EURO)"

    get.sp <- function (nm) unlist(lapply(strsplit(nm, split="_"), function(x) x[3]))
    a.sp <- get.sp(sp)

    df1 <- all.merged[all.merged$SI_STATE==1, colnames(all.merged)%in% c("SI_LATI","SI_LONG",sp)]
    df1$SI_LATI <- as.numeric(as.character(df1$SI_LATI )) # debug...
    df1$SI_LONG <- as.numeric(as.character(df1$SI_LONG )) # debug...
    df1[,sp] <- replace(df1[,sp], is.na(df1[,sp]) | df1[,sp]<0, 0)
    vmsGridCreate(df1, nameVarToSum=sp,  numCats=10,  plotPoints =FALSE, legendtitle=paste("landing",what,a.unit,sep=' '),
          colLand="darkolivegreen4",  addICESgrid=TRUE,
            nameLon="SI_LONG", nameLat="SI_LATI",cellsizeX =cellsizeX, cellsizeY =cellsizeY, we=we, ea=ea, no=no, so=so,
             breaks0=breaks0, legendncol=2)
    title(a.sp)
          # create folders
    dir.create(file.path(output, "jpegLandings", a.sp))
    dir.create(file.path(output, "jpegLandings", a.sp, "overall"))
    savePlot(filename = file.path(output, "jpegLandings", a.sp, "overall",
                            paste("map_landings_kg_merged_vessels_",what,"_",a.sp,"_",a.year,".jpeg",sep="")),type ="jpeg")

    dev.off()

    # per fleet
    for (met in levels(all.merged$LE_MET_level6) ){


      df1 <- all.merged[all.merged$LE_MET_level6==met &
                all.merged$SI_STATE==1, colnames(all.merged)%in% c("SI_LATI","SI_LONG",sp)]
      df1$SI_LATI <- as.numeric(as.character(df1$SI_LATI )) # debug...
      df1$SI_LONG <- as.numeric(as.character(df1$SI_LONG )) # debug...
      df1[,sp] <- replace(df1[,sp], is.na(df1[,sp]) | df1[,sp]<0, 0)
      if(nrow(df1)!=0){
      vmsGridCreate(df1, nameVarToSum=sp,  numCats=10,  plotPoints =FALSE, legendtitle=paste("landings",what,a.unit,sep=' '),
          colLand="darkolivegreen4",  addICESgrid=TRUE,
            nameLon="SI_LONG", nameLat="SI_LATI",cellsizeX =cellsizeX, cellsizeY =cellsizeY, we=we, ea=ea, no=no, so=so,
             breaks0=breaks0,legendncol=2)
         title(paste(met, "-", a.sp) )
      a.met <- gsub(">=", replacement="o",met)
      a.met <- gsub("<", replacement="",a.met)
      a.met <- gsub(">", replacement="o",a.met)
      # create folders and save
      dir.create(file.path(output, "jpegLandings", a.sp, a.met))
      savePlot(filename = file.path(output, "jpegLandings", a.sp, a.met,
                            paste("map_landings_kg_merged_vessels_",what,"_",a.sp,"_", a.met,"_",a.year,".jpeg",sep="")),type ="jpeg")
      dev.off()
      }
   }

   # per fleet, quarter
   for (met in levels(all.merged$LE_MET_level6) ){
     for (a.quarter in levels(all.merged$quarter) ){

      df1 <- all.merged[all.merged$LE_MET_level6==met &
                all.merged$quarter==a.quarter  &
                all.merged$SI_STATE==1, colnames(all.merged)%in% c("SI_LATI","SI_LONG",sp)]
      df1$SI_LATI <- as.numeric(as.character(df1$SI_LATI )) # debug...
      df1$SI_LONG <- as.numeric(as.character(df1$SI_LONG )) # debug...
      df1[,sp] <- replace(df1[,sp], is.na(df1[,sp]) | df1[,sp]<0, 0)
      if(nrow(df1)!=0){
      vmsGridCreate(df1, nameVarToSum=sp,  numCats=10,  plotPoints =FALSE, legendtitle=paste("landing",what,a.unit,sep=' '),
          colLand="darkolivegreen4",  addICESgrid=TRUE,
            nameLon="SI_LONG", nameLat="SI_LATI",cellsizeX =cellsizeX, cellsizeY =cellsizeY, we=we, ea=ea, no=no, so=so,
             breaks0=breaks0,legendncol=2)
         title(paste(met, "-", a.sp) )
      a.met <- gsub(">=", replacement="o",met) # debug
      a.met <- gsub("<", replacement="",a.met) # debug
      a.met <- gsub(">", replacement="o",a.met)# debug
      savePlot(filename = file.path(output, "jpegLandings", a.sp, a.met,
        paste("map_landings_kg_merged_vessels_",what,"_",a.sp,"_", a.met,"_",a.year,"_",a.quarter,".jpeg",sep="")),type ="jpeg")
      dev.off()
      }
     }}

 return()
 }
  #  in value
 # MergedTable2LandingMaps (all.merged=all.merged, sp="LE_EURO_COD",
 #                   cellsizeX =0.05, cellsizeY =0.05, we=9.8, ea=12.7, no=55.2, so=54.0, # fehmarn Belt area
 #                       breaks0= c(0,100, 100*(2^1),100*(2^2),100*(2^3),100*(2^4),100*(2^5),100*(2^6), 100*(2^7),100*(2^8),100*(2^9), 10000000)
 #                       )

