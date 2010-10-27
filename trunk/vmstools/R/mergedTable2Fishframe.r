

 mergedTable2Fishframe <- function(general=list(output.path=
             file.path("H:","DIFRES","VMSanalysis","results_merged","DKWaters"),
                                          a.year=2009, a.country="DNK")){
                                          
  ve   <- mergedTable2FishframeVE  (general=general)
  vsl  <- mergedTable2FishframeVSL (general=general)


  # add a fake column to get the same ncol()
  vsl <- cbind(vsl, 0)
  colnames(ve) <- paste('col', 1:ncol(ve), sep='')
  colnames(vsl) <- paste('col', 1:ncol(vsl), sep='')

  # bind and order
  #(to get a VE line and then VSL lines, VE and then VSL lines, etc.)
  ff <- rbind(ve,vsl)
  library(doBy)
  ff <- orderBy(~col7+col9+col5+col1, data=ff)


  # save
  write.table(ff, file=file.path(general$output.path,
         paste("ff_", general$a.year, ".txt", sep='')),  dec=".", sep=";",
          quote=FALSE, row.names=FALSE, col.names=FALSE)


  return(ff)
  }


# calls
# vsl <- mergedTable2FishframeVSL (general=list(output.path=file.path("C:","VMSanalysis","results_merged","DKWaters"),
#                                          a.year=2009, a.country="DNK") )
# ve <- mergedTable2FishframeVE (general=list(output.path=file.path("C:","VMSanalysis","results_merged","DKWaters"),
#                                          a.year=2009, a.country="DNK") )
 #ff <- mergedTable2Fishframe (general=list(output.path=file.path("C:","VMSanalysis","results_merged","DKWaters"),
 #                                         a.year=2009, a.country="DNK") )