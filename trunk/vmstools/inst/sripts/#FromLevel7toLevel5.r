# from step 7 to step 5

path <- "C:/CLARA/VMSTools_sandbox/"
setwd(path)

#extracting the step 3

load("DK_OTB2007_3a4/PCA_70/CLARA/Step3.Rdata")

# characteristing the main species

#checking the most robust metrics

par(mfrow=c(2,2))

for (metrics in c("1st Qu.","Mean","Median","3rd Qu.")) {
mean_ <-Step3$summaryClusters[metrics,,]

#plotting the number of main species by percentage threshold
threshold <-seq(50,5,by=-5)
nb_spp <- matrix(0,ncol=Step3$nbClust,nrow=length(threshold),dimnames=list(threshold,1:Step3$nbClust))
for (i in threshold) {
spp <-lapply(colnames(mean_),function(x) which(mean_[,x]>=i))
nb_spp[as.character(i),] <- sapply(spp, length)
}
barplot(t(nb_spp),beside=T, ylab="Nb Main Species",xlab=" min % threshold in cluster",col=rainbow(Step3$nbClust),main=metrics)

}

# final choice - Median 10%
mean_ <-Step3$summaryClusters["Median",,]
spp <-lapply(colnames(mean_),function(x) which(mean_[,x]>=10))  # this gives the name of the main species in the cluster

# linking to level 5

level5 <- lapply(spp, function(x) {
        assemblage <- NULL
      for (i in seq(length(x))) {
   if (names(x[i]) %in% c('NEP','PRA','CRK','CRB','CRG','CRJ','CRA','CRQ','CRR','KCT','LBA','LBE','AES','PEN','PAN','CRU','ERS','CSH','CRE','KEF','SLO'))  assemblage <- c(assemblage,"CRU") else
   if (names(x[i]) %in% c('BLL','COD','HAD','RED','REG','REB','REN','HKS','HKR','PLA','WIT','YEL','GHL','HAL','FLW','FLS','FLD','FLX','FLY','ANG','SRA','TOM','ANT','CUN','USK','GRC','BLI','LIN','LUM','KGF','PUF','ELZ','OPT','POC','RNG','RHG','SCU','CAT','CAA','CAS','GRO','BSS','GUG','LEM','LEZ','SRA',
                'DAB','FLE','PLE','POK','POL','SAN','SOL','WHG','TUR','APO','ANF','ARU','COE','DGS','DGX','LEF','LEM','MUX','MEG','SBR','SKA'))  assemblage <- c(assemblage,"DEF") else # "Demersal_fish"  # FAO sp code
   if (names(x[i]) %in% c('ABR','HLT','KRS','MUS','KNK','KMS','SNE','MOL','CLR','CLH','CLQ','CLS','CLT','COC','SCB','SCC','ISC','SCA','SCX','OYA','WHX','PER'))  assemblage <- c(assemblage,"MOL") else # "Molluscs"  # FAO sp code
   if (names(x[i]) %in% c('ELE','STU'))  assemblage <- c(assemblage,"CAT") else # "Catadromus_species"   # FAO sp code
   if (names(x[i]) %in% c('ANE','HER','SPR','MAC','HKE','SAU','ANB','SSM','MHA','BUT','CAP','PIL','JAX','SHG','ARU','ARY','MAS','GAR','MUL','WHB','NOP'))  assemblage <- c(assemblage,"SPF") else # "Small_pelagic_fish"  # FAO sp code
   if (names(x[i]) %in% c('BLU','CVJ','FRI','KGM','SSM','SAI','WHM','BUM','SWO','ALB','BON','LTA','BET','BFT','SKJ','YFT','POR','DGS','GUQ','DGX','SRX','SKA','SRX','TUN','GUQ'))  assemblage <- c(assemblage,"LPF") else # "Large_pelagic_fish"  # FAO sp code
   if (names(x[i]) %in% c('CHR','SAL','APU','TRS','TRR','SLZ','TLV','PLN','VIV','LAR','STU','SME','TRO','SHG','SHD','PLN','LAU'))  assemblage <- c(assemblage,"ANA") else # "Anadromous_species"
   if (names(x[i]) %in% c('FBM','FPE','FPI','PLN','FBR','FCP','FTE','BRB','FBR','FBU','FCC','FCP','FPP','FRO','SAR','ELP','FFX'))  assemblage <- c(assemblage,"FWS") else # "Freshwater_species"
   if (names(x[i]) %in% c('SQL','SQI','SQU','OCC','CTC','SQR'))  assemblage <- c(assemblage,"CEP") else # "Cephalopods"
   if (names(x[i]) %in% c('MZZ','OTH','FRF','YYY','ZZZ'))  assemblage <- c(assemblage,"OTH") # "Other"  # FAO sp code
   }
   assemblage <- do.call(paste,as.list(unique(assemblage)))
   })




