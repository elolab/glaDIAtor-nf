//
// Configuration of glaDIAtor-nf based on SDRF metadata
//
// SDRF parsing procedures had to be changed during update of NextFlow and they were not tested afterwards.
//
// The SDRF standard is described here https://github.com/bigbio/proteomics-metadata-standard.  
// See the `annoted-projects` directory for examples, try `PXD003977`.
//
// One should be able to run the parser by calling:
//   print(readSDRF("annotated-projects/PXD003977/PXD003977.sdrf.tsv", params))
//
// Notes:
// * NextFlow extension shows some warnings in the code below. One of them asks for 'for' loops to be removed.
// * `params = readSDRF(params.sdrf, ...` is a bad pattern. It should be split into two steps of parameter retrieval and merge.
// * Unit tests should be added.

def isallnull(value) {
    value == null || value.every({ x -> x == null })
}

def issomenull(value) {
    value == null || value.any({ x -> x == null })
}

def parseSDRFFileUri(sdrf_fields, params) {
    def raise_error_on_non_mzml = true
    def retval = [values:[:], warnings:[], errors:[]]

    def field_name = 'comment[file uri]'
    def flag_name = '--diafiles'

    def files = sdrf_fields*.get(field_name)

    if (params.diafiles == true) {
        retval.values += [ diafiles: params.diafiles ]
    }

    if (files == null) {
        retval.errors += ["No column named '$field_name' in .sdrf. Correct .sdrf or pass --$flag_name."];

        return retval
    }

    if (isallnull(files) || !files) {
        retval.errors += ["All values of '$field_name' are missing in .sdrf. Correct .sdrf or pass --$flag_name."]

        return retval
    }

    if (!isallnull(files) && issomenull(files)) {
        retval.errors += ["Some values of '$field_name' are missing in .sdrf. Correct .sdrf or pass --$flag_name."];
    }

    if (!isallnull(files) && raise_error_on_non_mzml && files.any({x -> x  && file(x).getExtension() != "mzML"})) {
        retval.errors += ["Some values '$field_name' are not mzML files."]
    }

    if (!retval.errors) {
        retval.values += [ diafiles: files ]
    } else {
        retval.values += [ diafiles: null ]
    }

    return retval
}

def parseSDRFTolerance(sdrf_fields, params, field_name = "comment[precursor mass tolerance]", flag_name = "precursor_mass_tolerance", supported_units = ["ppm"]) {
    def retval = [values:[:], warnings:[], errors:[]]
    def tolerances = sdrf_fields*.get(field_name)

    if (params.get(flag_name) != null) {
        retval.values[flag_name] = params.get(field_name)
    }

    if (tolerances == null) {
        retval.errors += ["No column named '$field_name' in .sdrf. Correct .sdrf or pass --$flag_name."]

        return retval
    }

    if (isallnull(tolerances) || !tolerances) {
        retval.errors += ["All values of '$field_name' are missing in .sdrf. Correct .sdrf or pass --$flag_name."]

        return retval
    }

    if (!isallnull(tolerances) && !tolerances.every()) {
        retval.errors += ["Some values of '$field_name' are missing in .sdrf. Correct .sdrf or pass --$flag_name."];
    }

    if (tolerances.any({ it -> it && it.split().size() > 1 && !(supported_units.contains(it.split()[1])) })) {
        retval.errors += ["Some values of '$field_name' in .sdrf are given in unsupported unit (supported units $supported_units). Correct .sdrf or pass --$flag_name."];
    }

    if (tolerances.any({ it -> it && it.split().size() < 2 })) {
        retval.warnings += ["Some values of '$field_name' in .sdrf are given without a unit, assuming " + supported_units[0] + "."]
    }

    if (tolerances.unique().size() != 1) {
        retval.errors += ["All values of '$field_name' need to be the same for all the samples. Correct .sdrf or pass --$flag_name."];
    }

    if (!retval.errors) {
        retval.values[flag_name] = tolerances.unique()[0].split()[0]
    }

    return retval
}

def readSDRF(filename, params) {
    def sdrf_file = file(filename)
    def options = [:]
    def errors = []
    def warnings = []

    def handlers = [
        // comment[file uri]
        this.&parseSDRFFileUri,

        // comment[fragment mass tolerance]
        { _sdrf_fields, _params -> parseSDRFTolerance(
            _sdrf_fields, _params, "comment[fragment mass tolerance]", "fragment_mass_tolerance", ["Da"]
        ) },

        // comment[precursor mass tolerance]
        { _sdrf_fields, _params -> parseSDRFTolerance(
            _sdrf_fields, _params, "comment[precursor mass tolerance]", "precursor_mass_tolerance", ["ppm"]
        ) }
    ]

    def sdrf_fields = sdrf_file.splitCsv(header: true, sep: '    ')

    sdrf_fields = sdrf_fields.collect({ entry -> entry.collectEntries(
        {key, row -> [key, (row =="not available" || row == "not applicable") ? null : row]}
    )})

    for (handler in handlers) {
        def val = handler(sdrf_fields, params)

        errors += val.errors
        warnings += val.warnings
        options += val.values
    }

    for (warning in warnings) {
        print("WARNING: " + warnings)
    }

    for (error in errors) {
        print("ERROR: " + error)
    }

    if (errors) {
        throw new Exception("Errors in SDRF file, see above messages")
    }

    return options
}
