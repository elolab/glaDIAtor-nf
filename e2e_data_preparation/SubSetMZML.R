#ROG 7093
wd="/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/MZML"
setwd(wd)
peptide_wl=gsub("^.+_","",readLines("/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/tutorial_output/dia/AllPeptideWishList.txt"))
library("mzR")
library("pepXMLTab")
library("GenomicRanges")
mzfiles=c("210820_Grad090_LFQ_A_01.PickPeak.mzML","210820_Grad090_LFQ_B_01.PickPeak.mzML")
names(mzfiles)=c("A","B")

pxml=list()
pxml[["A"]]=pepXML2tab("210820_Grad090_LFQ_A_01.PickPeak_rank1.pepXML")
pxml[["B"]]=pepXML2tab("210820_Grad090_LFQ_B_01.PickPeak_rank1.pepXML")
mz=lapply(mzfiles,function(x) openMSfile(x,backend = "pwiz"))

pxml.s=lapply(pxml,function(x) return(x[x[,"peptide"]%in%peptide_wl,]))


pick_best_spectra=function(x)
{
x.s=split(x,x[,"peptide"])
x.s=lapply(x.s,function(s){s.rat=as.numeric(s[,"num_matched_ions"])/as.numeric(s[,"tot_num_ions"]);s=s[order(-s.rat),];return(s[1,])})
return(do.call(rbind,x.s))
#calculate the ratio of matched ions, rank the hits accordingly and take the best hit. 
}

lapply(pxml.s,function(x) dim(x)) 
options(width=300)

pxml.s=lapply(pxml.s,FUN=pick_best_spectra)

scans=lapply(pxml.s,function(x) return(as.numeric(gsub("^.+ scan=","",x[,"spectrumNativeID"]))))
scans=lapply(scans,function(x) unique(x))
scans=lapply(scans,function(x) x[order(x)])

cut_scans=function(x,ms1,up_offset,down_offset)
{
#cat(paste0("scan ",x,"\n"))
scan_start=ms1[max(which(ms1<x)-up_offset)]
scan_end=ms1[(max(which(ms1<x)))+1+down_offset]-1
return(scan_start:scan_end)
}


#example AAVATFLQSVQVPEFTPK in [[1]]

#mz: spectrumId
#pxml: spectrumNativeID

subset_MZ=function(x,add_dummy,u_ofs,d_ofs)
{
hdr_orig=header(mz[[x]])
ms1_starts=hdr_orig[hdr_orig[,"msLevel"]==1,"seqNum"]
ms1_starts=c(ms1_starts,nrow(ms1_starts)+1)
x.scans=lapply(scans[[x]],FUN=cut_scans,ms1=ms1_starts,up_offset=u_ofs,down_offset=d_ofs)
x.scans=unique(unlist(x.scans))
x.scans=x.scans[order(x.scans)]
pks=peaks(mz[[x]],scans=x.scans)
hdr=header(mz[[x]],scans=x.scans)
valid <- !sapply(pks, is.null) & sapply(pks, nrow) > 0
pks <- pks[valid]
hdr <- hdr[valid, ]
summary(factor(valid))
hdr[,"seqNum"]=1:nrow(hdr)
hdr[,"acquisitionNum"]=1:nrow(hdr)
hdr[,"spectrumId"]=gsub(" scan=\\d+$"," scan=",hdr[,"spectrumId"])
hdr[,"spectrumId"]=paste0(hdr[,"spectrumId"],1:nrow(hdr))

out_file=paste0(x,"_subset.mzML")
writeMSData(object = pks, file = out_file, header = hdr,
            backend = "pwiz", outformat = "mzml")
}
subset_MZ("A",u_ofs=1,d_ofs=1) #use default values, take 1 slice up + 1 down, size goes down 50%
subset_MZ("B",u_ofs=1,d_ofs=1) #use default values, take 1 slice up + 1 down, size goes down 50%

test=list()
test[["A"]]=openMSfile("A_subset.mzML",backend = "pwiz")
test[["B"]]=openMSfile("B_subset.mzML",backend = "pwiz")

#warning: mzML is not valid. openMS convert mzml->mzxml->mzml fixes that
#in bash
#conda activate openms
#FileConverter -in A_subset.mzML -out A_subset.mzXML
#FileConverter -in A_subset.mzXML -out A_subset5.mzML

#FileConverter -in B_subset.mzML -out B_subset.mzXML
#FileConverter -in B_subset.mzXML -out B_subset5.mzML