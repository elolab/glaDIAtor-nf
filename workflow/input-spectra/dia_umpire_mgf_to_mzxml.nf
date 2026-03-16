process DiaUmpireMgfToMzxml {
    input:
    file mgf
    
    output:
    file "*.mzXML" 
    
    when:
    mgf.size() > 0

    script:
    """
    msconvert $mgf --mzXML 
    """
}

// Though this might also be done with openms's FileConverter? which is more conventionally build 
// https://abibuilder.informatik.uni-tuebingen.de/archive/openms/Documentation/release/latest/html/TOPP_FileConverter.html
// mstools
