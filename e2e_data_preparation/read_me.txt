Scripts collected here were used to generate small mzML files, to be used to perform e2e test with glaDIAtor-nf.

Work strategy:

1., Carry out the Tutorial analysis with raw files 210820_Grad090_LFQ_A_01.raw and 210820_Grad090_LFQ_B_01.raw. 
    aux script: ConvertAndPeakPick.R

2., Parse and filter peptide quant matrix output (DIA-peptide-matrix.tsv)
    * peptide intensity >= 3rd quantile ( log2(exp) >= 22
    * log2 FC between A and B sample is <= 1rd quantile <=0.038208
    * only consider HUMAN_ proteins
    * only consider proteotypic hits ^1/... ...
    * ignore peptides with post-translational modifications 
    script: "Collect_peptide_examples.R"
    output: list of peptides to locate in mzML

3., Carry out DIA->peptide search with MSFragger (v4.3)
    input files: "210820_Grad090_LFQ_A_01.PickPeak.mzML, 210820_Grad090_LFQ_B_01.PickPeak.mzML" + decoyed "210820_Human_Ref_Swiss_Can.fasta" + "dia.params2" MSFragger config file
    aux script:
    "Create_decoyed_human.R" #create reference protein sequences with reversed "DECOY_" records
    script:
    "Drive_MSFragger_Tutorial.R" #perform mzML vs protein search with MSFragger
    output: .PickPeak_rank1.pepXML search results files

4., mzML subsetting
    * from pepXML files we take the scanIDs for spectra related to selected peptides. (MS2 scan pick) 
    peptide->scanID assignment can be one->many: take the single best hit, ranked by "num_matched_ions/tot_num_ions" ratios. (the higher the better)
    * complete MS2 scans into complete MS1-MS2-MS2-MS2...MS2 duty cyles
    * mark selected -/+ 1 cycles (3 in total)
    * make selection non-redundant (if the same cycle was marked multiple times, include it only once)
    * using mzR, exctract marked cycles (#warning: mzR ruins mzML format, you can fix that later manually with openms mzml_bad->mzxml->mzml_good conversion
    script: SubSetMZML.R
5., test glaDIAtor-nf with smaller-scale mzML files
    #results: test run completes in ~8 minutes.
    
