def libgen_methods_get_existing () {
    return [ "dda", "custom", "diaumpire" ]
}

def libgen_methods_validate_params(params) {
    if (params.libgen_method != null) {
        def invalid_methods = params.libgen_method.split(",").findAll({	!libgen_methods_get_existing().contains(it) })

        if (invalid_methods) {
            raise RunTimeError("Invalid libgen methods specified: " + invalid_methods.join(","))
        }
    }
}

def libgen_method_is_enabled(method, params) {
    // method to use if the user didnt specify anything
    def fallback_method = "diaumpire";

    if (params.libgen_method){
        return params.libgen_method.split(",").contains(method)
    }

    switch (method) {
        case "dda": {
            return !!params.ddafiles;
        }
        case "custom": {
            return !!params.speclib;
        }
        default: {
            return (method == fallback_method) && !params.ddafiles && !params.speclib;
        }
    }
}
