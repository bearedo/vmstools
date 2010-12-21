 # author F.Bastardie
 # automatic creation of .gif animation using library(animation)
 # need to install the ImageMagik freeware
mapsLandings2GIFanim <- function(idir = file.path("C:","VMSanalysis","FemernBelt","jpegLandings"),
                           spp=c("COD","SPR","HER","PLE","FLE","DAB","WHB")){
library(animation)
for(sp in spp){
    for(met in list.files(file.path(idir, sp))){
           setwd(file.path(idir, sp, met,what,"quarter"))
           filename <- paste("map_landings_",what,"_merged_vessels_",sp,"_",met,"_",sep='')
           wildcard = paste(filename, "*.", "jpeg", sep = "")
           im.convert(wildcard, interval = 1, loop = 0, output = "anim.gif",  # library(animation)
           outdir = getwd(), convert = "convert", cmd.fun = system, clean = FALSE)
  } # end met
 } # end sp
return()
}

 # MergedTable2LandingMaps (all.merged=all.merged, sp="LE_EURO_COD",  output= file.path("C:","VMSanalysis", "FemernBelt"),
 #                   cellsizeX =0.05, cellsizeY =0.05, we=9.8, ea=12.7, no=55.2, so=54.0, # fehmarn Belt area
 #                       breaks0= c(0,100, 100*(2^1),100*(2^2),100*(2^3),100*(2^4),100*(2^5),100*(2^6), 100*(2^7),100*(2^8),100*(2^9), 10000000)
 #                       )
 # mapsLandings2GIFanim(idir = file.path("C:","VMSanalysis","FemernBelt","jpegLandings"), spp=c("COD","SPR") )