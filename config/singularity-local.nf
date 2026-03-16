singularity.enabled=true
process {
    container='file://containers/gladiator-guix.simg'

    withName: 'pyprophet_.*' {
       container='file://containers/pyprophet.simg'
    }

    withName: pyprophet_legacy {
        container='file://containers/pyprophet-legacy.simg'
    }
}

singularity.runOptions = '-B $TMPDIR:/tmp'
singularity.autoMounts=true
