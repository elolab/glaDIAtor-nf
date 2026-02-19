# ROG 7093

wd <- "/data/LauraEloGroup/glaDIAtor-nf_optim/Tutorial/RAW"
setwd(wd)
f <- list.files(pattern = "\\.raw$")

converter <- function(x, pick_peak = FALSE) {
    cat(paste0("Processing ", x, ".\n"))
    if (pick_peak) {
        outfile <- gsub("\\.raw", ".PickPeak.mzXML", x)
        cmd <- paste0("docker run --rm -v ", wd, ":/data chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:x64 wine msconvert /data/", x, " --mzML  --filter ", '"peakPicking true 1-"', " -o /data --outfile ", outfile)
        cat("Performing mzML conversion with Peak Picking\n")
        cat(paste0("Running ", cmd, "\n"))
    } else {
        outfile <- gsub("\\.raw", ".FullProfile.mzXML", x)
        cmd <- paste0("docker run --rm -v ", wd, ":/data chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:x64 wine msconvert /data/", x, " --mzML -o /data --outfile ", outfile)
        cat("Performing mzML conversion without Peak Picking\n")
        cat(paste0("Running ", cmd, "\n"))
    }
    system(cmd)
}

library(parallel)

# peak_picking for DIA-NN: FALSE
# peak_picking for quantMS: TRUE

mclapply(f, FUN = converter, pick_peak = FALSE, mc.cores = 2)
