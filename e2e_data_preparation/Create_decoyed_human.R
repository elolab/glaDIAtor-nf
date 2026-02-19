library(Biostrings)
pin=readAAStringSet("/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/MSFragger/210820_Human_Ref_Swiss_Can.fasta")
names(pin)=sapply(names(pin),function(x) {d=unlist(strsplit(x,"\\|"));return(paste0(d[-1],collapse="|"))})
pin_r=reverse(pin)
names(pin_r)=paste0("DECOY_",names(pin_r))

names(pin)=gsub("^sp\\|.{6,6}\\|","",names(pin))

db=c(pin,pin_r)
db=db[sample(1:length(db))]
all(names(db)%in%c(names(pin_r),names(pin))


pout=writeXStringSet(db,"/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/MSFragger/210820_Human_Ref_Swiss_Can_Decoyed.fasta")