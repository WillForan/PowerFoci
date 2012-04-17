###
#community detection similarity code
setwd(file.path(getMainDir(), "rs-fcMRI_Motion"))

communities <- read.table("CommunityDetection.txt", header=FALSE, col.names=c("roiNum", "reg", "robust", "scrapped"))
assignments <- communities[,2:4]

pipelineROIMatch <- list()
for (col in names(assignments)) {
  thisComm <- list()
  for (comm in sort(unique(assignments[[col]]))) {
    #check that class does not consist of a single fractionated node
    thisClass <- as.numeric(assignments[[col]] == comm)
#    if (!sum(thisClass) == 1) #okay, allow these weird guys to pass
    thisComm[[paste("c", comm, sep=".")]] <- thisClass
  }
  pipelineROIMatch[[col]] <- as.data.frame(thisComm)
}

library(gdata)
library(vcd)
library(plyr)

combs <- combinations(length(pipelineROIMatch), 2)

phiResults <- list()
for (p in combs) {
  p1 <- names(pipelineROIMatch)[combs[p,1]]
  p2 <- names(pipelineROIMatch)[combs[p,2]]
  
  compName <- paste(p1, p2, sep="_vs_")
  
  p1cat <- pipelineROIMatch[[p1]]
  p2cat <- pipelineROIMatch[[p2]]
  
  corMat <- matrix(NA_real_, nrow=ncol(p1cat), ncol=ncol(p2cat))
  rownames(corMat) <- paste(p1, "_", names(p1cat), sep="")
  colnames(corMat) <- paste(p2, "_", names(p2cat), sep="")
  for (i in 1:ncol(p1cat)) {
    iname <- names(p1cat)[i]
    for (j in 1:ncol(p2cat)) {
      jname <- names(p2cat)[j]

      corMat[i,j] <- assocstats(table(p1cat[[iname]], p2cat[[jname]]))$phi
    }
  }
  
  phiResults[[compName]]$corMat <- corMat
}

#sort into top three matches
for (comp in 1:length(phiResults)) {
  #sort the rows by decreasing corr
  ordCorr <- adply(phiResults[[comp]]$corMat, 1, function(row) {
        ord <- order(abs(row), decreasing=TRUE)
        data.frame(match1=names(row)[ord[1]], match1.corr=round(row[ord[1]], 3),
            match2=names(row)[ord[2]], match2.corr=round(row[ord[2]], 3),
            match3=names(row)[ord[3]], match3.corr=round(row[ord[3]], 3))
      })
  #adply adds the row name as X1, rename to c.target
  ordCorr <- plyr::rename(ordCorr, c(X1="c.target"))
  phiResults[[comp]]$ordCorr <- ordCorr  
}

sink("CommunitySimilarities.txt")
print(lapply(phiResults, "[[", "ordCorr"))
sink()

#from psych
#library(psych)
#      corMat[i,j] <- phi(table(p1cat[[iname]], p2cat[[jname]]))
