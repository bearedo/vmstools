\name{mergeTacsat2EflaloAndDispatchLandingsAtThePingScale}
\alias{mergeTacsat2EflaloAndDispatchLandingsAtThePingScale}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Coupling of VMS and logbooks data including landings dispatching between fishing pings.
}
\description{
The first step of the merging routine consisted of assigning a common identifier joining each
VMS trip to a logbook trip by searching for the nearest trip among all logbook trips based on the
temporal mid-point of trips. This circumvents problems where the start and end time of VMS
and logbook trips do not match exactly and ensure that each logbook trip will be merged with a
given VMS trip even if the reporting of the start and end date by fishermen is uncertain. We
observed in the data that this reporting date may fluctuate with +/- 1 day around the VMS trip
dates possibly because of error in reporting. Additionally, the possible few remaining logbook
trips were also linked with the nearest VMS trips. This latter event may occur from unknown
failure in the VMS device while fishermen were still fishing. In the processing, links were then
forced to nearest VMS trips to prevent loss of any reported landings. The second step of the
process evaluated the consistency between both types of data sources. Sequentially, a quality
flag was issued for each recorded position depending on the various degrees of matching, from
finer to coarser, if both data have in common: (i) the trip identifier, the same area (ICES
rectangle), and the catch date (ii) only the trip identifier and the area, or (iii) only the trip
identifier. The initial datasets (both VMS and logbooks) were split into sub-blocks according to
this flag. Each pair of sub-blocks was then joined separately and all merged sub-blocks were
bound in one dataset afterwards.
}
\usage{
mergeTacsat2EflaloAndDispatchLandingsAtThePingScale(logbooks, vms, general = general, ...)
}

\arguments{
  \item{logbooks}{
%%     data.frame, eflalo format
}
  \item{tacsat}{
%%     data.frame, tacsat format
}
  \item{general}{
%%     list, general settings to go through all functions
}
  \item{\dots}{
%%     character, a.vesselid = name of the vessel(s) in tacsat (and hopefully, in eflalo)
}
}
\details{
in tacsat SI_STAT, fishing should be coded 1 and non-fishing should be coded 2
}
\value{
Nothing is returned but a merged data.frame per vessel in the output folder
}
\references{
Bastardie et al. 2010. Fisheries Research
}
\author{
Francois Bastardie
}
\note{
}


\seealso{
vmsGridCreate
}

\examples{

 
  data(eflalo2)
  data(tacsat)
  data(harbours)
  tacsat$SI_HARB <- NA
  library(doBy)
  inHarb <- pointInHarbour(lon=tacsat$SI_LONG,lat=tacsat$SI_LATI,harbours=harbours,30)
  tacsat$SI_FT <- 1 # init
  idx <- which(inHarb==0)
  tacsat[idx,"SI_FT"] <- cumsum(inHarb) [idx] # add a SI_FT index
  tacsat <- tacsat[which(inHarb==0),] # keep out of harbour points only
  tacsat$SI_STATE <- 2 # init (1: fishing; 2: steaming)
  tacsat$SI_STATE [(tacsat$SI_SP>4 & tacsat$SI_SP<8)] <-1 # fake speed rule for fishing state

 
  
  # debug: change funny names of vesselid
  eflalo2$VE_REF <- matrix(unlist(strsplit(as.character(eflalo2$VE_REF),":")),ncol=2,byrow=T)[,2]
  tacsat$VE_REF <- matrix(unlist(strsplit(as.character(tacsat$VE_REF),":")),ncol=2,byrow=T)[,2]

  
  # reduce the size of the eflalo data by merging species (e.g. merge if <100 tons)
  eflalo <- mergeEflaloSpecies (eflalo2, threshold=100000) 
  
  # TEST FOR A GIVEN SET OF VESSELS
  mergeTacsat2EflaloAndDispatchLandingsAtThePingScale (logbooks=eflalo, tacsat=tacsat, a.vesselid=c("35", "1518"),
                                                             general=list(output.path=file.path("C:","output"),
                                                                            a.year=2009, visual.check=TRUE))
  # ...OR APPLY FOR ALL VESSELS IN eflalo2
  mergeTacsat2EflaloAndDispatchLandingsAtThePingScale (logbooks=eflalo2, tacsat=tacsat,
                                                             general=list(output.path=file.path("C:","output"),
                                                                            a.year=2009, visual.check=TRUE))
  gc(reset=TRUE)

  # load the merged output table for one vessel
  load(file.path("C:","output","merged_35_2009.RData"))
  
  # ...or bind all vessels
  bindAllMergedTables (vessels=c("35", "1518"), species.to.merge=character(), what=character(), 
                      folder = file.path("C:","output"))
 
   # load the merged output table for all vessels
  load(file.path("C:","output","all_merged_2009.RData"))
             
  # map landing of sole from all studied vessels
  df1<- all.merged[,colnames(all.merged)%in% c("SI_LATI","SI_LONG","LE_KG_SOL")]
  df1$SI_LONG <-as.numeric(as.character(df1$SI_LONG))
  df1$SI_LATI <-as.numeric(as.character(df1$SI_LATI))
  vmsGridCreate(df1,nameLon="SI_LONG",nameLat="SI_LATI",cellsizeX =0.05,cellsizeY =0.05)

  # remove steaming points before gridding!
  df2<-df1[-which(is.na(df1$LE_KG_SOL)),]
  vmsGridCreate(df2,nameLon="SI_LONG",nameLat="SI_LATI",cellsizeX =0.05,cellsizeY =0.05)

   # TO FISHFRAME FORMAT:
  # add a month code
  all.merged$month <- factor(format(as.POSIXct(all.merged$SI_DATE), "%m")) 
  # add an area code
  all.merged$CSquare <- CSquare (lon=as.numeric(as.character(all.merged$SI_LONG)), 
                                   lat=as.numeric(as.character(all.merged$SI_LATI)),
                                     degrees=0.05)
  # TO DO : aggregate LE_EURO_SP, LE_KG_SP, and LE_EFF_VMS per level6, month and area code
  nm         <- names(all.merged)
  idx.col.w  <- grep('KG', nm) # index columns with species weight
  idx.col.v  <- grep('EURO', nm) # index columns with species value
  idx.col.vms  <- grep('VMS', nm) # index columns related to VMS calculation
  idx.col    <- c(idx.col.w, idx.col.v, idx.col.vms)
  all.merged.agg  <- aggregate(all.merged[,idx.col],
                      list(all.merged$LE_MET_level6, all.merged$month, all.merged$CSquare), sum, na.rm=TRUE )
       #=> but this piece of code likely to be inefficient with large data set?

  # TO DO: a rountine to convert further toward the fishframe format 


}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
