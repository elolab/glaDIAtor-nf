#ROG 7093
wd="/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/tutorial_output/dia"
setwd(wd)
library(bitops)
d=read.table("DIA-peptide-matrix.tsv",sep="\t",as.is=T,quote='"',header=T,row.names=1)
d=d[grep("^1/",rownames(d)), ] #only proteotypic hits
dl=log2(d+0.01)
summary(dl[,1])
summary(dl[,2])
#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# -6.644  19.260  20.472  20.559  21.803  30.225 
#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#  11.41   19.24   20.48   20.54   21.79   29.00 


a.filt=as.logical(bitAnd(dl[,1]>=22,dl[,2]>=22))  # from 3rd quartile of protein expression
dlf=dl[a.filt,]

dlf.diff=abs(dlf[,1]-dlf[,2])
summary(dlf.diff) #abs (difference in expression between samples, expressed as log2 FoldChange)

#    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#0.000045 0.038208 0.079354 0.174433 0.149715 5.278557 

dlf=dlf[dlf.diff<=0.038208,] #smallest 1st quartile of differences between sample A and B
dlf=dlf[grep("UniMod",rownames(dlf),invert=T),] #331 peptides #removed all peptides with modifications
dlf=dlf[grep("HUMAN",rownames(dlf)),] #303 peptides #kept only Human proteins
prots=unique(gsub("_.+$","",gsub("^.+\\|","",rownames(dlf)))) #210

writeLines(prots,"AllProteinWishList.txt")
writeLines(rownames(dlf),"AllPeptideWishList.txt")

