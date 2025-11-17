// [[file:notes.org::*License][License:1]]
/*
 * Copyright (C) 2025
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
// License:1 ends here

// [[file:notes.org::nf-header-block][nf-header-block]]
import nextflow.splitter.CsvSplitter

def readSDRF(filename,params)
{
    def sdrf_file=file(filename)
    def options=[:]
    def errors=[]
    def warnings=[]
    def handlers =[
	this.&parseSDRFFileUri,
	{_sdrf_fields,_params ->
	    parseSDRFTolerance(_sdrf_fields, _params,
						    field_name = "comment[fragment mass tolerance]",  flag_name="fragment_mass_tolerance",supported_units=["Da"])},
	{_sdrf_fields,_params ->
	    parseSDRFTolerance(_sdrf_fields, _params,
						    field_name = "comment[precursor mass tolerance]",  flag_name="precursor_mass_tolerance",supported_units=["ppm"])},
    ]
    def sdrf_fields = new CsvSplitter().target(sdrf_file.text).options(header:true,sep:'	').list()
    sdrf_fields = sdrf_fields.collect(
	{entry ->
	    entry.collectEntries(
		{key, row ->
		    [key,
		     (row =="not available" ||
		      row == "not applicable") ? 
		     null :
		     row]})})
    

    for(handler in handlers) {
	def val = handler(sdrf_fields, params);
	errors += val.errors
	warnings+= val.warnings
	options+=val.values
    }
    for(warning in warnings)
	print("WARNING: " + warnings)
    for(error in errors)
	print("ERROR: " + error)
    if(errors)
	throw new Exception("Errors in SDRF file, see above messages")
    return options
}
def parseSDRFFileUri(sdrf_fields, params){
    def raise_error_on_non_mzml=true
    def retval= [values:[:],warnings:[],errors:[]]
    def field_name = 'comment[file uri]'
    def flag_name = '--diafiles'
    def files = sdrf_fields*.get(field_name)
    // here we intentionally don't break the switch statement so that we can accumulate retval.errors,
    // so that the user can know all at once.
    switch (true) {
	case (params.diafiles):
	    retval.values+=[diafiles:params.diafiles]
	    break;
    case(files == null):
	    retval.errors += ["No column named '$field_name' in sdrf. Add one or supply files with  $flag_name"];
	    break;
	case (isallnull(files) || !files):
	    retval.errors += ["All retval.values are missing in  supplied in sdrf '$field_name'. Enter these or supply CLI $flag_name];"]
	case (!isallnull(files) && issomenull(files)):
	    retval.errors += ["Some entries in sdrf '$field_name'  are not given, fill in or supply $flag_name"];
	case (!isallnull(files) && raise_error_on_non_mzml && files.any({x -> x  && file(x).getExtension() != "mzML"})):
	    retval.errors += ["Some entries in sdrf  '$field_name' are not mzML files"];
	    // if there were no retval.errors
	    // then the files field in the sdrf is correct
	case(!retval.errors):
	    retval.values+=[diafiles:files]
	    break;
	case(retval.errors):
	    retval.values+=[diafiles:null]
	    break;
    }
    return retval
}
def parseSDRFTolerance(sdrf_fields, params,  field_name = "comment[precursor mass tolerance]",  flag_name="precursor_mass_tolerance",supported_units=["ppm"]){
    def retval = [values:[:], warnings:[], errors:[]]
    def tolerances = sdrf_fields*.get(field_name)
    switch(true){
	case(params.get(flag_name) != null):
	    retval.values[flag_name] = params.get(field_name);
	    break
	case(tolerances == null):
	    retval.errors += ["No column named '$field_name' in sdrf. Add one or supply  --$flag_name"];
	    break;
	case (isallnull(tolerances) || !tolerances):
	    retval.errors += ["All values are missing in  supplied in sdrf '$field_name'. Enter these or supply CLI --$flag_name];"]
	case (!isallnull(tolerances) && !tolerances.every()):
	    retval.errors += ["Some entries in sdrf '$field_name'  are not given, fill in or supply $flag_name"];
	case(tolerances.any({it && it.split().size() > 1 && !(supported_units.contains(it.split()[1]))})):
	    retval.errors += ["Some entries in sdrf '$field_name' have an unsupported unit(supported units for $field_name: $supported_units)"];
	case(tolerances.any({it && it.split().size() < 2})):
	    retval.warnings += ["Some entries in sdrd '$field_name' do not have a unit, assuming " + supported_units[0]]
	case(tolerances.unique().size() != 1):
	    retval.errors += ["Gladiator currently requires the $field_name to be the same for all the samples, change it or supply --$flag_name"];
    case(!retval.errors):
	    retval.values[flag_name] = tolerances.unique()[0].split()[0]
    }
    return retval
}
def isallnull(value)
{
    value == null || value.every({x-> x==null})
}
def issomenull(value)
{
    value == null || value.any({x -> x == null})
}
if (params.sdrf){
    params = readSDRF(params.sdrf, params) + params
}
// returns all libgen methods that we supplor
def libgen_methods_get_existing (){
    return [ "dda","custom", "deepdia", "diaumpire","diams2pep"]
}

def libgen_method_any_pseudospectra_method_is_enabled(params){
    def pseudospectra_methods = ["diams2pep","diaumpire"]
    return pseudospectra_methods.inject(false) { acc, val -> acc || libgen_method_is_enabled(val, params)}
}


def libgen_methods_validate_params(params){
    if(params.libgen_method != null){
	def invalid_methods = params.libgen_method.split(",").findAll({	   !libgen_methods_get_existing().contains(it)})
	if(invalid_methods)
	    raise RunTimeError("Invalid libgen methods specified: " + invalid_methods.join(","))
    }
}
def libgen_method_is_enabled(method, params){
    // method to use if the user didnt specify anything
    def fallback_method = "diaumpire";
    if (params.libgen_method){
	return params.libgen_method.split(",").contains(method)
    }
    switch (method) {
	    case "dda": return !!params.ddafiles;
	    case "custom": return !!params.speclib;
	default: return (method == fallback_method) && !params.ddafiles && !params.speclib;  
    }
}

def libgen_method_is_exclusively_enabled(method, params) {
    return libgen_methods_get_existing().inject(true) { acc, val -> acc && ( libgen_method_is_enabled(val, params)  == (val == methods)) }
}
Channel.fromPath(params.fastafiles).set{fasta_files_ch}
Channel
    .fromPath(params.diafiles)
    .multiMap{
	it -> swath_windows: osw: it}
    .set{dia_mzml_files_ch}
// TODO: raise an error if params.libgen_method  is not a supported method
libgen_methods_validate_params(params)
deconvolution_methods = []

if(libgen_method_is_enabled("dda",params)){
    deconvolution_methods += [output: { dda_files_ch } ]
}
if(libgen_method_is_enabled("diaumpire",params)){
    deconvolution_methods += [output: {diaumpire_pseudospectra_ch},
			      input:  {dia_mzml_files_for_diaumpire_ch}]
}
if(libgen_method_is_enabled("diams2pep",params)){
    deconvolution_methods += [output: { diams2pep_pseudospectra},
			      input: { diams2pep_input_mzml}]
}
deconv_input_chs = deconvolution_methods*.input.findAll({it != null})
if(deconv_input_chs){
    Channel
	.fromPath(params.diafiles)
	.into(
	    deconv_input_chs
		.inject() { acc, val -> acc << val })
}
deconv_output_chs = deconvolution_methods*.output.findAll({it != null})
for(ch:deconv_output_chs)
    Channel.create().set(ch.clone())
if(deconv_output_chs){
    Channel.empty()
	.mix(*(deconv_output_chs*.call()))
	.multiMap{ it -> spectrast: comet: xtandem: it }
	.set{maybespectra_ch}
}
if(libgen_method_any_pseudospectra_method_is_enabled(params) || libgen_method_is_enabled("dda",params)){
if(libgen_method_is_enabled("dda",params)){
    Channel.fromPath(params.ddafiles).tap(dda_files_ch)
}
/*
 */ 
if(libgen_method_is_enabled("diaumpire",params)){
// so that this is a singleton channel
diaumpireconfig_ch = Channel.fromPath(params.diaumpireconfig)
} // end of diaumpire guard
if(libgen_method_is_enabled("diams2pep",params)){
} // end of diams2pep guard
max_missed_cleavages = Channel.value(params.max_missed_cleavages)
consensus_pseudospectra_openswath_library_tsv = Channel.create()
consensus_pseudospectra_openswath_library_tsv
    .set{speclib_tsv_for_decoys}
} // end of dda convolution / pseudo spectra convolution guard.
/*
 */
if(libgen_method_is_enabled("deepdia",params))  { 
Channel
    .from(params.deepdia_ms2_entries)
    .map( {
	    charge, model ->
	    tuple(charge, file(model))})
    .set{deepdia_ms2_models}
deepdia_peptide_list = Channel.create()
if (params.deepdia_min_detectability != null){
    deepdia_peptide_list.set{deepdia_prefilt_peptide_list}
    deepdia_filtered_peptide_list = Channel.create()
    deepdia_filtered_peptide_list
	.tap{deepdia_peptides_for_retention_pred}
	.tap{deepdia_peptides_for_library}
	.combine(deepdia_ms2_models)
	.set{deepdia_ms2_inputs_ch}
} else {
    deepdia_peptide_list
    	.tap{deepdia_peptides_for_retention_pred}
	.tap{deepdia_peptides_for_library}
    	.combine(deepdia_ms2_models)
	.set{deepdia_ms2_inputs_ch}
}
deepdia_irt_model = Channel.fromPath(params.deepdia_irt_model)
deepdia_speclib = Channel.create()
   deepdia_speclib.set{speclib_tsv_for_decoys}
}  // end of deepdia guard
if (libgen_method_is_enabled("custom", params)){
    Channel.fromPath(params.speclib).set{speclib_tsv_for_decoys}
}
if(params.oswdg_min_decoy_fraction != null) { 
    Channel.value("-min_decoy_fraction ${params.oswdg_min_decoy_fraction}").set{oswdg_args} 
} else if (libgen_method_is_enabled("deepdia",params)){
 Channel.value("-min_decoy_fraction 0.0").set{oswdg_args}
} else {
  Channel.value("").set{oswdg_args}
}
if(params.pyprophet_subsample_ratio == null){
    Channel.value(1 / Math.max(Channel.fromPath(params.diafiles).toSortedList().size().getVal(), 1))
	.set{subsample_ratio}
} else {
    Channel.value(params.pyprophet_subsample_ratio).set{subsample_ratio}
}
// nf-header-block ends here

// [[file:notes.org::nf-joinfastafiles][nf-joinfastafiles]]
process JoinFastaFiles {
    input:
    file fasta_files from fasta_files_ch.toSortedList()
    output:
    file 'joined_database.fasta' into joined_fasta_database_ch

    """
    #!/usr/bin/env python3
    from Bio import SeqIO
    def join_fasta_files(input_files, output_file):
        IDs = set()
        seqRecords = []
        for filename in input_files:
            records = SeqIO.index(filename, "fasta")
            for ID in records:
                if ID not in IDs:
                    seqRecords.append(records[ID])
                    IDs.add(ID)
                else:
                    print("Found duplicated sequence ID " + str(ID) + ", skipping this sequence from file " + filename)
    
        SeqIO.write(seqRecords, output_file, "fasta")
    join_fasta_files("$fasta_files".split(" "), 'joined_database.fasta')
    """
}
// nf-joinfastafiles ends here

// [[file:notes.org::nf-buildfastadatabase][nf-buildfastadatabase]]
fasta_db_with_decoys = Channel.value()
process BuildFastaDatabase {
    input:
    file joined_fasta_db from joined_fasta_database_ch
    output:
    file "DB_with_decoys.fasta" into joined_fasta_with_decoys_ch
    """
    DecoyDatabase -in $joined_fasta_db -out DB_with_decoys.fasta
    """
}
// nf-buildfastadatabase ends here

// [[file:notes.org::*Branching if user supplied windows][Branching if user supplied windows:2]]
if (params.swath_windows_file) {    
  process RegularizeUserSwathWindow {
      input:
      path user_swath_windows, stageAs: 'userSwathWindow.txt' from Channel.fromPath(params.swath_windows_file).first()
      output:
      file swath_windows into swath_windows_ch
      script:
      swath_windows="swath-windows.txt"
      """
      sort -n $user_swath_windows | awk 'BEGIN {OFS="	"} {print \$1,\$2}' >  $swath_windows
      """
  }  
} else  {
    process InferSwathWindows {
        input:
        file diafile from dia_mzml_files_ch.swath_windows.first()
        output: 
        file "swath-windows.txt" into  swath_windows_ch
        shell:
        '''
        #!/usr/bin/env python3
        import xml.etree.ElementTree as ET
        import os
        
        def read_swath_windows(dia_mzML):
        
            print ("DEBUG: reading_swath_windows: ", dia_mzML)
            
            context = ET.iterparse(dia_mzML, events=("start", "end"))
        
            windows = {}
            for event, elem in context:
        
                if event == "end" and elem.tag == '{http://psi.hupo.org/ms/mzml}precursor':
                    il_target = None
                    il_lower = None
                    il_upper = None
        
                    isolationwindow = elem.find('{http://psi.hupo.org/ms/mzml}isolationWindow')
                    if isolationwindow is None:
                        raise RuntimeError("Could not find isolation window; please supply --swath_windows_file to Gladiator.")
                    for cvParam in isolationwindow.findall('{http://psi.hupo.org/ms/mzml}cvParam'):
                        name = cvParam.get('name')
                        value = cvParam.get('value')
        
                        if (name == 'isolation window target m/z'):
                            il_target = value
                        elif (name == 'isolation window lower offset'):
                            il_lower = value
                        elif (name == 'isolation window upper offset'):
                            il_upper = value
        
                    ionList = elem.find('{http://psi.hupo.org/ms/mzml}selectedIonList')
                   
                    selectedion = ionList.find('{http://psi.hupo.org/ms/mzml}selectedIon')
        
                    if selectedion:
                    
                        for cvParam in selectedion.findall('{http://psi.hupo.org/ms/mzml}cvParam'):
                            name = cvParam.get('name')
                            value = cvParam.get('value')
        
                            if (name == 'selected ion m/z'):
                                if not il_target:
                                    il_target = value
                        
                    if not il_target in windows:
                        windows[il_target] = (il_lower, il_upper)
                    else:
                        lower, upper = windows[il_target]
                        assert (il_lower == lower)
                        assert (il_upper == upper)
                        return windows
        
            return windows
        
        def create_swath_window_files(cwd, dia_mzML):
            windows = read_swath_windows(dia_mzML)
            swaths = []
            for x in windows:
                target_str = x
                lower_str, upper_str = windows[x]
                target = float(target_str)
                lower = float(lower_str)
                upper = float(upper_str)
                assert (lower > 0)
                assert (upper > 0)
                swaths.append((target - lower, target + upper))
            swaths.sort(key=lambda tup: tup[0])
            # here we use chr(10) (equivalent to slash n), and chr(9) (equivalent to slash t)  because i dont wanna deal with nextflow headaches
            newline_character = chr(10)
            tab_character = chr(9)
            with open(os.path.join(cwd, "swath-windows.txt"), "w") as fh_swaths:
                for lower,upper in swaths:
                    fh_swaths.write(str(lower) + tab_character + str(upper)  + newline_character)
            return fh_swaths
        
        swaths = create_swath_window_files(".","!{diafile}")
        '''
    }
}
// Branching if user supplied windows:2 ends here

// [[file:notes.org::*Making the non-overlapping swath-windows][Making the non-overlapping swath-windows:2]]
process InferNonOverlappingSwathWindows {
    input:
    file swath_windows from swath_windows_ch.first()
    output:
    file truncated_swath_windows into truncated_swath_windows_ch
    script:
    truncated_swath_windows="truncated_swath_windows.txt"
    ''' awk '
    BEGIN {OFS="	"}
    function max(a,b){
        if(a > b)
    	return a
        return b
    }
    NR==1 {
        # we start with the special case that the boundary for the first entry
        # should be unchanged
        prev_upper=$1
        # and we add the column names
        print "LowerOffset","HigherOffset"
    }
    {
        if (prev_upper > $2)
        {
    	print "There is a a window thats a subwindow of the previous window"
    	exit 1
        }
        print(max($1,prev_upper),$2)
        prev_upper=$2
    }' ''' + "$swath_windows > $truncated_swath_windows"
}
// Making the non-overlapping swath-windows:2 ends here

// [[file:notes.org::*Building {Pseudo-,}Spectral library from (Pseudo)-Spectra][Building {Pseudo-,}Spectral library from (Pseudo)-Spectra  [5/5]:3]]
if(libgen_method_any_pseudospectra_method_is_enabled(params) || libgen_method_is_enabled("dda",params)){
// Building {Pseudo-,}Spectral library from (Pseudo)-Spectra  [5/5]:3 ends here

// [[file:notes.org::*Steps that are run][Steps that are run:2]]
/*
 */ 
if(libgen_method_is_enabled("diaumpire",params)){
// Steps that are run:2 ends here

// [[file:notes.org::*Steps that are run][Steps that are run:4]]
// create mzxml
process MzmlToMzxml {
    input:
    file diafile from dia_mzml_files_for_diaumpire_ch
    output:
    file "*.mzXML" into dia_mzxml_files_for_diaumpire_ch
    """
    msconvert $diafile --32 --zlib --filter "peakPicking false 1-" --mzXML
    """
}

process GeneratePseudoSpectra  {
    memory '16 GB' 
    input:
    file diafile from dia_mzxml_files_for_diaumpire_ch
    path diaumpireconfig from diaumpireconfig_ch.first()
    output:
    // we flatten here becuase a single mzxml might result in multiple mgf files
    file "*.mgf" into diaumpire_pseudospectra_mgf_ch mode flatten 

    """
    # we set \$1 to the number of gigs of memory
    set -- $task.memory
    if command -v diaumpire-se; 
    then
    	diaumpire-se  -Xmx\$1g -Xms\$1g $diafile $diaumpireconfig
    else 
	java -Xmx\$1g -Xms\$1g -jar /opt/dia-umpire/DIA_Umpire_SE.jar $diafile $diaumpireconfig
    fi
    """
}

process DiaUmpireMgfToMzxml {
    input:
    file mgf from diaumpire_pseudospectra_mgf_ch
    output:
    file "*.mzXML" into diaumpire_pseudospectra_ch
    when:
    // excluding empty files   
    mgf.size()  > 0
    """
    msconvert $mgf --mzXML 
    """
}
// Steps that are run:4 ends here

// [[file:notes.org::*Steps that are run][Steps that are run:8]]
} // end of diaumpire guard
// Steps that are run:8 ends here

// [[file:notes.org::*Creating Pseudospectra with diams2pep][Creating Pseudospectra with diams2pep:3]]
if(libgen_method_is_enabled("diams2pep",params)){
// Creating Pseudospectra with diams2pep:3 ends here

// [[file:notes.org::*Creating Pseudospectra with diams2pep][Creating Pseudospectra with diams2pep:4]]
process convert_for_DIAMS2PEP {
    input:
    file mzml from diams2pep_input_mzml
    output:
    // there is no good way in nextflow that makes a UUUID that persists across -resume things
    // task.hash is forgotten in resume, as is task.id.
    tuple val("${mzml.baseName}"), path(ofile) into diams2pep_mgf_mzml, diams2pep_window_mzml, diams2pep_for_pseudo_mzml
    script:
    ofile="converted/${mzml.baseName}.mzML"
    """
    mkdir -p converted
    msconvert --mzML --mz64 --zlib --inten64 --simAsSpectra --filter "peakPicking cwt msLevel=1-2" --outdir converted $mzml
    """
}
// Creating Pseudospectra with diams2pep:4 ends here

// [[file:notes.org::*Creating Pseudospectra with diams2pep][Creating Pseudospectra with diams2pep:5]]
process convert_mgf_for_DIAMS2PEP {
    input:
    tuple val(hash), path(mzml) from diams2pep_mgf_mzml
    output:
    tuple val(hash), path("${mzml.baseName}.mgf") into diams2pep_mgf
    
    """
    msconvert --mgf $mzml
    """
}
// Creating Pseudospectra with diams2pep:5 ends here

// [[file:notes.org::*Creating Pseudospectra with diams2pep][Creating Pseudospectra with diams2pep:6]]
process DIAMS2PEP_window {
    input:
    tuple val(hash), path(mzml) from  diams2pep_window_mzml
    output:
    tuple val(hash), path("${mzml}.DIA_acquisition_window.txt") into diams2pep_window
    
    """
    DIA_acquistion_window_generator.pl $mzml
    """
}
// Creating Pseudospectra with diams2pep:6 ends here

// [[file:notes.org::*Creating Pseudospectra with diams2pep][Creating Pseudospectra with diams2pep:7]]
if(params.diams2pep_fragment_tolerance == null)
    raise RunTimeError("DIAMSM2PEP enabled but no diams2pep_fragment_tolerance specified.")
process DIAMS2PEP_generate_pseudo {
    input:
    tuple val(hash), path(mzml), path(mgf), path(acq_window) from diams2pep_for_pseudo_mzml.join(diams2pep_mgf).join(diams2pep_window)
    val tolerance from Channel.value(params.diams2pep_fragment_tolerance)
    output:
    file "mgf-output/*.mgf" into diams2pep_pseudospectra_mgf mode flatten
    """
    mkdir -p mgf-output
    DIA_pesudo_MS2_multiforks.pl ${mzml.baseName} mgf-output $tolerance ${task.cpus}
    """
}
// Creating Pseudospectra with diams2pep:7 ends here

// [[file:notes.org::*Creating Pseudospectra with diams2pep][Creating Pseudospectra with diams2pep:8]]
// this will use the default container because we need msconvert
process MgfToMzml_DIAMS2PEP {
    input:
    file mgf from diams2pep_pseudospectra_mgf
    output:
    file "*.mzXML" into diams2pep_pseudospectra
    """
    msconvert --mzXML $mgf
    """
}
// Creating Pseudospectra with diams2pep:8 ends here

// [[file:notes.org::*Creating Pseudospectra with diams2pep][Creating Pseudospectra with diams2pep:9]]
} // end of diams2pep guard
// Creating Pseudospectra with diams2pep:9 ends here

// [[file:notes.org::*Comet][Comet:3]]
process MakeCometConfig {
    // should we instead return a tuple here of fastadb and config
    // because the config.txt refers to it?
    input:
    val max_missed_cleavages
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    path template from Channel.fromPath(params.comet_template)
    output:
    file "comet_config.txt" into comet_config_ch
    """
    sed 's/@DDA_DB_FILE@/$fastadb_with_decoy/g;s/@FRAGMENT_MASS_TOLERANCE@/$params.fragment_mass_tolerance/g;s/@PRECURSOR_MASS_TOLERANCE@/$params.precursor_mass_tolerance/g;s/@MAX_MISSED_CLEAVAGES@/$max_missed_cleavages/g' $template > comet_config.txt 
    """
    
}
// Comet:3 ends here

// [[file:notes.org::*Comet][Comet:4]]
process Comet {
    // we probably also want to publish thees
    memory { 5.GB * 2 *  task.attempt }
    errorStrategy { task.exitStatus in 137..137 ? 'retry' : 'terminate' }
    maxRetries 2
    input:
    file comet_config from comet_config_ch.first()
    // future dev: we can .mix with DDA here?
    // though we might need to tag for DDA / Pseudo
    // so that xinteract 
    file mzxml from maybespectra_ch.comet
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    output:
    file("${mzxml.baseName}.pep.xml") into comet_pepxml_ch
    file mzxml into xinteract_comet_mzxml_ch
    when:
    params.search_engines.contains("comet")

    """
    if command -v command-ms;
    then
      comet-ms -P$comet_config $mzxml
    else
      comet -P$comet_config $mzxml
    fi
    """
}
// Comet:4 ends here

// [[file:notes.org::*Comet][Comet:5]]
process XinteractComet {
    memory '16 GB'
    time '5h'
    // memory usage scales with the number of input files
    // find the correct usage per input file or size
    // also for xinteractxtandem
    // usage there seems to be a lot smaller
    // as input files seems to be smaller
    input:
    file pepxmls from comet_pepxml_ch.toSortedList()
    // the filename of needed fastdadb was defined in cometcfg
    // and stored in pepxml in the comet-ms step
    // -a suppplies the absulute path to the data directory where the mzxmls
    // rather than reading wherer the mfrom the xmls
    // where the mzxml are, because its not very
    // nextflow to look outside the cwd.
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    file mzxmls from  xinteract_comet_mzxml_ch.toSortedList()
    output: 
    file "interact_comet.pep.xml" into comet_search_results_ch
    when:
    pepxmls.size() > 0
    """
    xinteract -a\$PWD -OARPd -dDECOY_ -Ninteract_comet.pep.xml $pepxmls
    """
}
// Comet:5 ends here

// [[file:notes.org::*Xtandem][Xtandem:4]]
process MakeXtandemConfig {
    input:
    file template from Channel.fromPath(params.xtandem_template)
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    val max_missed_cleavages
    output:
    file "xtandem_config.xml" into xtandem_config_ch
    """
    sed 's/@DDA_DB_FILE@/$fastadb_with_decoy/g;s/@FRAGMENT_MASS_TOLERANCE@/$params.fragment_mass_tolerance/g;s/@PRECURSOR_MASS_TOLERANCE@/$params.precursor_mass_tolerance/g;s/@MAX_MISSED_CLEAVAGES@/$max_missed_cleavages/g' $template > xtandem_config.xml
    """
}


process XTandem {
    when:
    params.search_engines.contains("xtandem")

    input:
    file mzxml from maybespectra_ch.xtandem
    file tandem_config from xtandem_config_ch.first()
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    output:
    file("${mzxml.baseName}.tandem.pep.xml") into xtandem_pepxml_ch
    file mzxml into xinteract_xtandem_mzxml_ch
    """
    printf '
    <?xml version="1.0"?>
    <bioml label="x! taxon-to-file matching list">
      <taxon label="DB">
        <file format="peptide" URL="%s" />
      </taxon>
    </bioml>'  $fastadb_with_decoy | tail -n+2 > xtandem_taxonomy.xml
    
    printf '
    <?xml version="1.0"?>
    <bioml>
    	<note>
    	Each one of the parameters for x! tandem is entered as a labeled note node. 
    	Any of the entries in the default_input.xml file can be over-ridden by
    	adding a corresponding entry to this file. This file represents a minimum
    	input file, with only entries for the default settings, the output file
    	and the input spectra file name. 
    	See the taxonomy.xml file for a description of how FASTA sequence list 
    	files are linked to a taxon name.
    	</note>
    
    	<note type="input" label="list path, default parameters">%s</note>
    	<note type="input" label="list path, taxonomy information">%s</note>
    
    	<note type="input" label="protein, taxon">DB</note>
    	
    	<note type="input" label="spectrum, path">%s</note>
    
    	<note type="input" label="output, path">%s</note>
    </bioml>' $tandem_config xtandem_taxonomy.xml $mzxml ${mzxml.baseName}.TANDEM.OUTPUT.xml | tail -n+2 > input.xml
    tandem input.xml
    Tandem2XML ${mzxml.baseName}.TANDEM.OUTPUT.xml ${mzxml.baseName}.tandem.pep.xml 
    """
}

process XinteractXTandem {
    memory '16 GB'
    input:
    file pepxmls from xtandem_pepxml_ch.toSortedList()
    // the filename of needed fastdadb was defined in cometcfg
    // and stored in pepxml in the comet-ms step
    // -a suppplies the absulute path to the data directory where the mzxmls
    // rather than reading wherer the mfrom the xmls
    // where the mzxml are, because its not very
    // nextflow to look outside the cwd.
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    file mzxmls from  xinteract_xtandem_mzxml_ch.toSortedList()
    output: 
    file "interact_xtandem.pep.xml" into xtandem_search_results_ch
    when:
    pepxmls.size() > 0 
    """
    xinteract -a\$PWD -OARPd -dDECOY_ -Ninteract_xtandem.pep.xml $pepxmls
    """
}
// Xtandem:4 ends here

// [[file:notes.org::*Joining Comet & Xtandem][Joining Comet & Xtandem:1]]

// Joining Comet & Xtandem:1 ends here

// [[file:notes.org::*Joining Comet & Xtandem][Joining Comet & Xtandem:2]]
// we handle the one or two engines case
// DSL2 incompat
// would be in workflow body

if (params.search_engines.size() > 1) {  
    process CombineSearchResults {
	publishDir "${params.outdir}/speclib"
	when:
	
	input:
	file xtandem_search_results from xtandem_search_results_ch
	file comet_search_results from comet_search_results_ch
	output:
	file "lib_iprophet.peps.xml" into combined_search_results_ch
	"""
	InterProphetParser DECOY=DECOY_ THREADS=${task.cpus} $xtandem_search_results $comet_search_results lib_iprophet.peps.xml
	"""
    }
} else if (params.search_engines.contains("comet")) {
    combined_search_results_ch = comet_search_results_ch
} else if (params.search_engines.contains("xtandem")) {
    combined_search_results_ch =xtandem_search_results_ch
} else {
    combined_search_results_ch = Channel.create()
}
// Joining Comet & Xtandem:2 ends here

// [[file:notes.org::*Mayu][Mayu:2]]
process  FindMinimumPeptideProbability {
    input: 
    file combined_search_results from combined_search_results_ch.first()
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    val max_missed_cleavages
    output:
    env PEPTIDEPROBABILITY into  minimum_peptide_probability
    /* explanation of paramaters
     -G  $params.protFDR            | maximum allowed mFDR of $params.protFDR 
     -P protFDR=$params.protFDR:t   |  print out PSMs of targets who have a protFDR of $params.protFDR
     -
     -H | defines the resolution of error analysis (mFDR steps)
     -I number of missed cleavages used for database search
     -M | file name base
     */
    script:
    prefix="filtered"
    // you can change this to a glob-pattern (e.g. "*") for future-proofing
    mayu_version="1.07"
    psm_csv="${prefix}_psm_protFDR${params.protFDR}_t_${mayu_version}.csv"
    """
    Mayu.pl -verbose -A $combined_search_results -C $fastadb_with_decoy -E DECOY_ -G $params.protFDR -P protFDR=${params.protFDR}:t -H 51 -I $max_missed_cleavages -M $prefix
    # test if psm_csv was made
    test -e $psm_csv || exit 1
    # test if the results arent empty
    test `wc -l $psm_csv | cut -d' ' -f1` -gt 1 || exit 1 
    PEPTIDEPROBABILITY=`cat $psm_csv | cut -f 5 -d ',' |tail -n+2 |sort -u | head -n1`
    """
}
// Mayu:2 ends here

// [[file:notes.org::*Converting traml into spectrast friendly format][Converting traml into spectrast friendly format:3]]
process CreateSpectrastIrtFile {
    input:
    file irt_traml from Channel.fromPath(params.irt_traml_file)
    output:
    file ("irt.txt") into irt_txt_ch
    script:
    intermediate_tsv="intermediate_irt.tsv"
    """
    TargetedFileConverter -in $irt_traml -out_type tsv -out $intermediate_tsv
    """ + '''  awk '
    BEGIN {FS="	"; OFS="	"}
    NR==1 {
        for (i=1; i<=NF; i++) {
            f[$i] = i
        }
    }
    NR>1 { print $(f["PeptideSequence"]), $(f["NormalizedRetentionTime"]) }' ''' + "$intermediate_tsv > irt.txt"
}
// Converting traml into spectrast friendly format:3 ends here

// [[file:notes.org::*Running Spectrast][Running Spectrast:1]]
// spectrast will create *.splib, *.spidx, *.pepidx, 
// note that where-ever a splib goes, so must its spidx and pepidx
///and they must have the same part
process SpectrastCreateSpecLib {
    input:
    file irtfile from irt_txt_ch
    file combined_search_results from combined_search_results_ch.first()
    file fastadb_with_decoy from joined_fasta_with_decoys_ch.first()
    file spectra from maybespectra_ch.spectrast.toSortedList()
    val cutoff from minimum_peptide_probability
    output:
    tuple file ("${prefix}_cons.splib"), file("${prefix}_cons.spidx") into spectrast_ch
    file("${prefix}_cons.sptxt") into consensus_lib_sptxt_ch
    script:
    prefix = "SpecLib"
    to_run = "spectrast -cN${prefix} -cIHCD -cf\"Protein! ~ DECOY_\" -cP$cutoff -c_IRR "
    if (params.use_irt)
	to_run += "-c_IRT$irtfile "
    to_run +=  "$combined_search_results" // spectrast really wants its input-files last.
    to_run += "\n spectrast -cN${prefix}_cons -cD$fastadb_with_decoy -cIHCD -cAC ${prefix}.splib"
}
// Running Spectrast:1 ends here

// [[file:notes.org::*Running Spectrast][Running Spectrast:5]]
process Spectrast2OpenSwathTsv {
 /*
     Choice parts of sprectrast2.tsv --help
     
     spectrast2tsv.py
     ---------------
     This script is used as filter from spectraST files to swath input files.
     python spectrast2tsv.py [options] spectrast_file(s)
     
     -d                  Remove duplicate masses from labeling
     -e                  Use theoretical mass
     -k    output_key    Select the output provided. Keys available: openswath, peakview. Default: peakview
     -l    mass_limits   Lower and upper mass limits of fragment ions. Example: -l 400,2000
     -s    ion_series    List of ion series to be used. Example: -s y,b

     -w    swaths_file   File containing the swath ranges. This is used to remove transitions with Q3 falling in the swath mass range. (line breaks in windows/unix format)
     -n    int           Max number of reported ions per peptide/z. Default: 20
     -o    int           Min number of reported ions per peptide/z. Default: 3
     -a    outfile       Output file name (default: appends _peakview.txt)
     */
    input:
    file swath_windows from swath_windows_ch.first()
    file sptxt from consensus_lib_sptxt_ch.first()
    output:
    file consensus_pseudospectra_openswath_library_tsv
    script:
    consensus_pseudospectra_openswath_library_tsv="SpecLib_cons_openswath.tsv"
    """
    MINWINDOW=`head -n1 $swath_windows | cut -d'	' -f1`
    MAXWINDOW=`tail -n1 $swath_windows | cut -d'	' -f2`
    spectrast2tsv.py -l \$MINWINDOW,\$MAXWINDOW -s y,b -d -e -o 6 -n 6 -w $swath_windows -k openswath -a $consensus_pseudospectra_openswath_library_tsv $sptxt
    """
}
// Running Spectrast:5 ends here

// [[file:notes.org::*End of {Pseudo-,}Spectral section][End of {Pseudo-,}Spectral section:2]]
} // end of dda convolution / pseudo spectra convolution guard.
// End of {Pseudo-,}Spectral section:2 ends here

// [[file:notes.org::#section-deepdia][Building Spectral library from Machine learning:1]]
/*
 */
if(libgen_method_is_enabled("deepdia",params))  {
// Building Spectral library from Machine learning:1 ends here

// [[file:notes.org::#section-deepdia][Building Spectral library from Machine learning:5]]
process DeepDIADigestProtein
{
    input:
    file joined_fasta from joined_fasta_database_ch
    output:
    file deepdia_peptide_list
    script:
    deepdia_peptide_list="deepdia_peptide_list.csv"
    """
    digest_proteins.py --in $joined_fasta --out $deepdia_peptide_list --no-group_duplicated
    """
}
// Building Spectral library from Machine learning:5 ends here

// [[file:notes.org::#section-deepdia][Building Spectral library from Machine learning:7]]
if (params.deepdia_min_detectability != null){
    // we seperate these two so that --resume allows for easy tweaking of --minimum-detectability
    process DeepDIATrainDetectibility {
	memory '64 GB'
	input:
	file model from Channel.fromPath(params.deepdia_detectability_model)
	file deepdia_prefilt_peptide_list
	output:
	set file(deepdia_detectability_prediction), file(deepdia_prefilt_peptide_list) into deepdia_detectability
	script:
	deepdia_detectability_prediction="${deepdia_prefilt_peptide_list.baseName}.detectability.csv"
	"predict_detectability.py --in $deepdia_prefilt_peptide_list --model $model --out $deepdia_detectability_prediction"
    }
    
    process DeepDIAMinimumDetectabilityFiltering
    {
	input:
	set file(detectability_prediction), file(prefilt_peptide_list) from deepdia_detectability
	val min_detectability from Channel.value(params.deepdia_min_detectability)
	output:
	file deepdia_filtered_peptide_list
	script:
	deepdia_filtered_peptide_list="deepdia_filtered_peptide_list.csv"
	"""
	filter_peptide_by_detectability.py --peptide $prefilt_peptide_list --detect $detectability_prediction --min_detectability $min_detectability --out ${deepdia_filtered_peptide_list}
	"""
    }
}
// Building Spectral library from Machine learning:7 ends here

// [[file:notes.org::#section-deepdia][Building Spectral library from Machine learning:8]]
process DeepDIAPredictCharge {
    memory '64 GB'
    input:
    set file(peptides),charge,file(model)  from deepdia_ms2_inputs_ch
    output:
    file deepdia_ions
    script:
    deepdia_ions="predictions.charge.${charge}.ions.json"
    """
    predict_ms2.py --charge $charge --in $peptides --model $model --out $deepdia_ions
    """
}
// Building Spectral library from Machine learning:8 ends here

// [[file:notes.org::#section-deepdia][Building Spectral library from Machine learning:11]]
process DeepDIAPredictRetention {
    memory '32 GB'
    input:
    file deepdia_irt_model
    file deepdia_peptides_for_retention_pred
    output:
    file predicted_rt
    script:
    predicted_rt="prediction.irt.csv"
    """
    predict_rt.py --in $deepdia_peptides_for_retention_pred --model $deepdia_irt_model --out $predicted_rt
    """
}
// Building Spectral library from Machine learning:11 ends here

// [[file:notes.org::#section-deepdia][Building Spectral library from Machine learning:12]]
process DeepDIAPredictionsToLibrary {
    memory '32 GB'
    input:
    file predicted_rt
    file ions from deepdia_ions.toSortedList()
    file deepdia_peptides_for_library
    output:
    file deepdia_speclib
    script:
    deepdia_speclib="speclib.tsv"
    """
    build_assays_from_prediction.py --peptide ${deepdia_peptides_for_library} --rt ${predicted_rt} --ions ${ions} --out prediction.assay.pickle
    convert_assays_to_openswath.py --in prediction.assay.pickle --out ${deepdia_speclib}
    """
}
// Building Spectral library from Machine learning:12 ends here

// [[file:notes.org::#section-deepdia][Building Spectral library from Machine learning:14]]
}  // end of deepdia guard
// Building Spectral library from Machine learning:14 ends here

// [[file:notes.org::*OpenSwathDecoys][OpenSwathDecoys:3]]
process AddDecoysToOpenSwathTransitions {
    input:
    file speclib_tsv from speclib_tsv_for_decoys.first()
    val oswdg_args
    output:
    file outputfile into openswath_transitions_ch
    script:
    outputfile="SpecLib_cons_decoys.pqp"

    """
    TargetedFileConverter -in $speclib_tsv -out SpecLib_cons.TraML
    OpenSwathDecoyGenerator -decoy_tag DECOY_ -in SpecLib_cons.TraML -out $outputfile -method reverse $oswdg_args
    """
}
// OpenSwathDecoys:3 ends here

// [[file:notes.org::*OpenSwathWorkflow][OpenSwathWorkflow:4]]
// we will need the osw to go to various processes
if (params.pyprophet_use_legacy){
    openswath_transitions_ch.into{openswath_transitions_ch_for_legacy}
 process OpenSwathWorkflow_legacy {
 	memory { 16.GB * (libgen_method_is_enabled("deepdia",params) ? 2 : 1 )}
 	input:
 	file dia_mzml_file from dia_mzml_files_ch.osw
 	// file openswath_transitions from Channel.fromPath("data_from_original/bruderer-pwiz-no-dda/SpecLib_cons_decoy.TraML").first()
 	file openswath_transitions from openswath_transitions_ch_for_legacy.first()
 	file swath_truncated_windows from truncated_swath_windows_ch.first()
 	file irt_traml from Channel.fromPath(params.irt_traml_file).first()
 	output:
 	file dia_tsv_file  into openswath_tsv_ch
 	script:
 	dia_tsv_file = "${dia_mzml_file.baseName}-DIA.tsv"
 	to_execute =
             "OpenSwathWorkflow " +
             "-force " +
             "-in $dia_mzml_file " +
             "-tr $openswath_transitions " +
             "-threads ${task.cpus} " +
             "-min_upper_edge_dist 1 " +
             "-sort_swath_maps " +
             "-out_tsv ${dia_tsv_file} " + 
             "-swath_windows_file $swath_truncated_windows " +
             params.osw_extra_flags + " "
 	if (params.use_irt)
             to_execute +=  "-tr_irt $irt_traml "
 	to_execute
 }
} else {
    openswath_transitions_ch.into{openswath_transitions_ch_for_nonlegacy;openswath_transitions_ch_for_pyprophet}
  openswath_osw_indirect_ch = Channel.create()
  openswath_osw_indirect_ch.multiMap{ it ->
      pyprophet_subsample: pyprophet_score  : it}.set{openswath_osw_ch}
  process OpenSwathWorkflow {
      memory { 16.GB * (libgen_method_is_enabled("deepdia",params) ? 2 : 1 )}
      input:
      file dia_mzml_file from dia_mzml_files_ch.osw
      // file openswath_transitions from Channel.fromPath("data_from_original/bruderer-pwiz-no-dda/SpecLib_cons_decoy.TraML").first()
      file openswath_transitions from openswath_transitions_ch_for_nonlegacy.first()
      file swath_truncated_windows from truncated_swath_windows_ch.first()
      file irt_traml from Channel.fromPath(params.irt_traml_file).first()
      output:
      file dia_osw_file  into openswath_osw_indirect_ch
      script:
      dia_osw_file = "${dia_mzml_file.baseName}-DIA.osw"
      to_execute =
          "OpenSwathWorkflow " +
          "-force " +
          "-in $dia_mzml_file " +
          "-tr $openswath_transitions " +
          "-threads ${task.cpus} " +
          "-min_upper_edge_dist 1 " +
          "-sort_swath_maps " +
          "-out_osw ${dia_osw_file} " + 
          "-swath_windows_file $swath_truncated_windows " +
          params.osw_extra_flags + " "
      
      if (params.use_irt)
          to_execute +=  "-tr_irt $irt_traml "
      to_execute
  }
}
// OpenSwathWorkflow:4 ends here

// [[file:notes.org::*Legacy Pyprophet][Legacy Pyprophet:1]]
if (params.pyprophet_use_legacy)
    process pyprophet_legacy {
    publishDir "${params.outdir}/pyprophet/", pattern: "*.csv"
    publishDir "${params.outdir}/reports/pyprophet/", pattern: "*.pdf"
    input:
    file dia_tsv from openswath_tsv_ch
    output:
    file dscore_csv into pyprophet_legacy_ch
    // just for publishing
    file "${dia_tsv.baseName}_report.pdf" 
    script:
    seed="928418756933579397"
    
    dscore_csv="${dia_tsv.baseName}_with_dscore.csv"
    """
    pyprophet --random_seed=${seed} --delim=tab --export.mayu ${dia_tsv} --ignore.invalid_score_columns
    """
}
// Legacy Pyprophet:1 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:4]]
if (!params.pyprophet_use_legacy)
    {
// nonlegacy prypophet:4 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:5]]
process pyprophet_subsample {
    input:
    file dia_osw_file from openswath_osw_ch.pyprophet_subsample
    val subsample_ratio
    output:
    file subsampled_osw
    script:
    subsampled_osw="${dia_osw_file.baseName}.osws"
    pyprophet_seed_flag=(params.pyprophet_fixed_seed ? "--test" : "--no-test")
    """
    pyprophet subsample $pyprophet_seed_flag --in=$dia_osw_file --out=$subsampled_osw --subsample_ratio=$subsample_ratio
    """
}
// nonlegacy prypophet:5 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:6]]
process pyprophet_learn_classifier {
    input:
    file subsampled_osws from subsampled_osw.toSortedList()
    file openswath_transitions from openswath_transitions_ch_for_pyprophet.first()
    output:
    file osw_model
    script:
    pyprophet_seed_flag=(params.pyprophet_fixed_seed ? "--test" : "--no-test")
    osw_model="model.osw"
    """
    pyprophet merge --template=$openswath_transitions --out=$osw_model $subsampled_osws
    pyprophet score  $pyprophet_seed_flag --in=$osw_model --level=ms1ms2
    """
}
// nonlegacy prypophet:6 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:7]]
scored_osw_indirect_ch =Channel.create()
scored_osw_indirect_ch.multiMap{it ->
    reduce: backpropagate: it}.set{scored_osw_ch}

process pyprophet_apply_classifier {
    input:
    file osw_model from osw_model.first()
    file osw from openswath_osw_ch.pyprophet_score
    output:
    file scored_osw into scored_osw_indirect_ch
    script:
    pyprophet_seed_flag=(params.pyprophet_fixed_seed ? "--test" : "--no-test")
    scored_osw="${osw.baseName}.scored.${osw.Extension}"
    """
    pyprophet score $pyprophet_seed_flag --in=$osw --out=$scored_osw --apply_weights=$osw_model --level=ms1ms2
    """
}
// nonlegacy prypophet:7 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:8]]
process pyprophet_reduce {
    input:
    file scored_osw from scored_osw_ch.reduce
    output:
    file reduced_scored_osw 
    script:
    reduced_scored_osw="${file(scored_osw.baseName).baseName}.${scored_osw.Extension}r"
    """
    pyprophet reduce --in=$scored_osw --out=$reduced_scored_osw
    """
}
// nonlegacy prypophet:8 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:9]]
process pyprophet_control_error {
    input:
    file reduced_scored_osws from reduced_scored_osw.toSortedList()
    file osw_model from osw_model.first()
    output:
    file osw_global_model
    script:
    osw_global_model="model_global.osw"
    """
    pyprophet merge --template=$osw_model --out=$osw_global_model $reduced_scored_osws
    pyprophet peptide --context=global --in=$osw_global_model
    pyprophet protein --context=global --in=$osw_global_model
    """
}
// nonlegacy prypophet:9 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:10]]
process pyprophet_backpropagate {
    input:
    file osw_scored from scored_osw_ch.backpropagate
    file osw_global_model from osw_global_model.first()
    output:
    file dscore_tsv into pyprophet_nonlegacy_ch
    script:
    base="${file(osw_scored.baseName).baseName}"
    backproposw="${base}.backprop.osw"
    dscore_tsv="${base}.tsv"
    """
    pyprophet backpropagate --in="$osw_scored" --apply_scores="$osw_global_model" --out=$backproposw
    # we supply --format=legacy_merged so that pyprophet export respect the --out parameter
    pyprophet export --in=$backproposw --format=legacy_merged --out=$dscore_tsv
    """
}
// nonlegacy prypophet:10 ends here

// [[file:notes.org::*nonlegacy prypophet][nonlegacy prypophet:11]]
}
// nonlegacy prypophet:11 ends here

// [[file:notes.org::*Choosing between legacy and nonlegacy pyprophet][Choosing between legacy and nonlegacy pyprophet:1]]
if (params.pyprophet_use_legacy)
    pyprophet_legacy_ch.set{pyprophet_ch}
else
    pyprophet_nonlegacy_ch.set{pyprophet_ch}
// Choosing between legacy and nonlegacy pyprophet:1 ends here

// [[file:notes.org::*feature-alignment][feature-alignment:1]]
process feature_alignment
{
    publishDir "${params.outdir}/dia/"
    input:
    file dscore_csvs from pyprophet_ch.toSortedList()
    output:
    file outfile into feature_alignment_ch
    script:
    outfile = "DIA-analysis-results.csv"
    if (params.use_irt) {
        realign_method = "diRT" 
    } else {
        realign_method = "linear"
    }

    if(params.no_realignment)
    {
	realignment_string = ""
    } else
    {
       realignment_string = "--realign_method $realign_method "
    }
    
    "feature_alignment.py " +
        "--method best_overall " +
        "--max_rt_diff 90 " +
        "--target_fdr $params.tric_target_fdr " +
        "--max_fdr_quality $params.tric_max_fdr " +
        "--in $dscore_csvs " +         // will this break on filenames with spaces
        realignment_string +
	params.feature_alignment_args + " "
        "--out $outfile"
}
// feature-alignment:1 ends here

// [[file:notes.org::*Swath2stats][Swath2stats:2]]
process swath2stats {
    publishDir "${params.outdir}/dia/"
    input:
    file dia_score from feature_alignment_ch
    
    output:
    file peptide_matrix
    file protein_matrix
    
    script:
    strict_checking=params.swath2stats_strict_checking
    peptide_matrix="DIA-peptide-matrix.tsv"
    protein_matrix="DIA-protein-matrix.tsv"
    
    """
    #!/usr/bin/env Rscript
    """ +
        '''
suppressPackageStartupMessages(library(SWATH2stats))
suppressPackageStartupMessages(library(data.table))

remove_irt <- function(df)
  df[grep("iRT", df[["ProteinName"]], invert=TRUE, fixed=TRUE),, drop=FALSE]

## original gladiator decoy removing behaviour
remove_decoy_strict <- function(df,decoyprefix)
  df[grep(decoyprefix, df[["ProteinName"]], invert=TRUE, fixed=TRUE),, drop=FALSE]


remove_decoy_loose <- function(df)
  df[!df[["decoy"]],, drop = FALSE]


basename_sans_ext <- function(f)
  unlist(strsplit(basename(f), ".",fixed=TRUE))[[1]]


main <- function(diafile,
                 strict_checking=FALSE,
                 peptideoutputfile="",
                 proteinoutputfile="",
                 decoyprefix="DECOY_")
{
  remove_decoy <- `if`(strict_checking,
                       function(df) remove_decoy_strict(df,decoyprefix),
                       remove_decoy_loose)
  filtered_data <-
    data.table::fread(diafile,header=TRUE) |> 
    data.frame(stringsAsFactors = FALSE) |>
    within(run_id <- basename(filename)) |>
    SWATH2stats::reduce_OpenSWATH_output() |>
    remove_irt() |>
    remove_decoy()

  # Writing output
  filtered_data |>
    SWATH2stats::write_matrix_peptides(filename = basename_sans_ext(peptideoutputfile)) |>
    write.table(sep="\t",file=peptideoutputfile,row.names = FALSE)

  filtered_data |>
    SWATH2stats::write_matrix_proteins(filename = basename_sans_ext(proteinoutputfile)) |>
    write.table(sep="\t",file=proteinoutputfile,row.names = FALSE)
}
        ''' +
        """
    main("$dia_score", strict_checking = as.logical("$strict_checking"),
	peptideoutputfile="$peptide_matrix",
	proteinoutputfile="$protein_matrix",
	decoyprefix="DECOY_")
	
    """
}
// Swath2stats:2 ends here

// [[file:notes.org::*File local variables][File local variables:2]]
// Local Variables:
// compile-command: "module use /appl/user/modulefiles/ && module load nextflow && salloc nextflow run gladiator.nf"
// End:
// File local variables:2 ends here
