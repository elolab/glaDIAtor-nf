docker.enabled=true
process {
    container='localhost/gladiator-guix'

    withName: 'pyprophet_.*' {
       container='localhost/pyprophet'
    }

    withName: pyprophet_legacy {
        container='localhost/pyprophet-legacy'
    }
}

process {
    withName: 'pyprophet_.*' {
        containerOptions= '--env HOME="$PWD"'
    }
}
