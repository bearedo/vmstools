
# assign an identifier in'HL_ID' to each of the fishing sequences
# (based on SI_STATE, assuming the "h", "f", "s" coding)
# (useful to count them in a grid...)
labellingHauls <- function(tacsat){
            tacsat$SI_STATE2                             <- tacsat$SI_STATE
            tacsat$SI_STATE                              <- as.character(tacsat$SI_STATE)
            tacsat[is.na(tacsat$SI_STATE), 'SI_STATE']   <- '2' # assign steaming
            tacsat[tacsat$SI_STATE!='f', 'SI_STATE']     <- '2' # assign steaming
            tacsat[tacsat$SI_STATE=='f', 'SI_STATE']     <- '1' # assign fishing
            tacsat$SI_STATE                              <- as.numeric(tacsat$SI_STATE)
            tacsat$SS_ID                              <- c(0, diff(tacsat$SI_STATE))   # init
            tacsat$SS_ID                              <- cumsum(tacsat$SS_ID) # steaming sequences detected.
            tacsat$HL_ID                              <- 1- tacsat$SS_ID  # fishing sequences detected.
            tacsat$HL_ID                              <- cumsum(tacsat$SS_ID ) # fishing sequences labelled.
            tacsat[tacsat$SI_STATE==2, 'HL_ID']       <- 0 # correct label 0 for steaming
            tacsat$HL_ID                              <- factor(tacsat$HL_ID)
            levels(tacsat$HL_ID) <- 0: (length(levels(tacsat$HL_ID))-1) # rename the id for increasing numbers from 0
            tacsat$HL_ID                             <- as.character(tacsat$HL_ID)
            # then assign a unique id
            idx <- tacsat$HL_ID!=0
            tacsat[idx, "HL_ID"] <- paste(
                                    tacsat$VE_REF[idx], "_",
                                    tacsat$LE_GEAR[idx], "_",
                                    tacsat$HL_ID[idx],
                                    sep="")
          tacsat <- tacsat[, !colnames(tacsat) %in% 'SS_ID'] # remove useless column
          tacsat$SI_STATE <- tacsat$SI_STATE2
          return(tacsat)
       }

# label fishing sequecnes with a unique identifier (method based on SI_STATE)
#tacsat <- labellingHauls(tacsat)



