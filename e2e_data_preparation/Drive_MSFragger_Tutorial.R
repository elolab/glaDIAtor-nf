#7093, dell
#add decoy sequences to DB
wd="/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/MZML"
setwd(wd)
library(xml2)
MSF.jar="/home/babali/MSFragger-4.3/MSFragger-4.3.jar"
dia.conf="/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/MSFragger/dia.params2"
spec.f=list.files("/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/MZML",pattern="mzML$",full.name=T)
names(spec.f)=gsub("^.+/","",gsub("\\.PickPeak.mzML","",spec.f))
callMSF=function(x,bin,conf,ram="16G")
{
cat(paste0("Working with ",x,".\n"))
cmd=paste0("java -Xmx",ram," -jar ",bin," ",conf," ",x)
system(cmd)
pepxml.f=gsub(".PickPeak.mzML",".PickPeak_rank1.pepXML",x)
peptlist.f=gsub(".PickPeak.mzML",".Peptides.txt",x)
cat(paste0("Reading ",pepxml.f,".\n"))
xml_doc = read_xml(pepxml.f)
ns <- xml_ns(xml_doc)
search_hits <- xml_find_all(xml_doc, ".//d1:search_hit", ns)
peptides <- xml_attr(search_hits, "peptide") 
writeLines(peptides,peptlist.f)
}
pepres=lapply(spec.f,FUN=callMSF,bin=MSF.jar,conf=dia.conf,ram="16G")
#/scratch/babali/PXD034709_mouse_in_yeast/msfragger_config/dia.params_YMA