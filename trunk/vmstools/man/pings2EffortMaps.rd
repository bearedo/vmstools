\name{pings2EffortMaps}
\alias{pings2EffortMaps}
\title{
generate some fishing effort maps from the merged output table
}
\description{
generate some effort maps (jpeg files) from the merged table per year, per metier (level6), per metier-quarter all together
}
\usage{pings2EffortMaps()}
\arguments{
  \item{all.merged}{the data.frame from merged VMS with logbooks }
  \item{output}{a path for the output folder to be created}
  \item{...}{additional arguments for mapGrid}
}
\details{
using some arguments informing mapGrid(). Performing automatic creation of a hierarchy of output folders. 
see also pings2LandingsMaps(). 
}
\source{
}
\references{
}
\author{
Francois Bastardie
}
\examples{
 
\dontrun{
 
 
  for(a.year in as.character(2005:2009)){

     # ...and load the merged output table for all vessels
     load(file.path("C:","output",paste("all_merged__",a.year,".RData",sep=''))) 

     # generate the effort maps (jpeg files) and store in a hierarchy of folders
     pings2EffortMaps (all.merged=all.merged,  output= file.path("C:","VMSanalysis", "FemernBelt"),
        cellsizeX =0.05, cellsizeY =0.05, we=9.8, ea=12.7, no=55.2, so=54.0,
         breaks0=c(0,25, 50,100,200,400,800,1600, 3200,6400,12800, 100000))

     # generate the landings maps (jpeg files) and store in a hierarchy of folders
     pings2LandingsMaps (all.merged=all.merged, sp="LE_KG_COD",
             output= file.path("C:","VMSanalysis", "FemernBelt"),
                    cellsizeX =0.05, cellsizeY =0.05, we=9.8, ea=12.7, no=55.2, so=54.0, # fehmarn Belt area
                        breaks0= c(0,100, 100*(2^1),100*(2^2),100*(2^3),100*(2^4),100*(2^5),100*(2^6), 100*(2^7),100*(2^8),100*(2^9), 10000000)
                        )
     }                     
 
  # create some animations from the sequential jpeg files...
  # (need the 'animation' R package and ImageMagik installed)
  mapsLandings2GIFanim(idir = file.path("C:","VMSanalysis","FemernBelt","jpegLandings"), spp=c("COD") )
 

  }

}
\keyword{}
