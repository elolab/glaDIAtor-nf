podman.enabled=true
process {
    container='docker://docker.io/elolabfi/gladiator-guix:0.1.4-0-f7abd8'

    withName: 'pyprophet_.*' {
       container='docker://docker.io/elolabfi/pyprophet:0.1.4-0-f7abd8'
    }

    withName: pyprophet_legacy {
        container='docker://docker.io/elolabfi/pyprophet-legacy:0.1.4-0-f7abd8'
    }
}

process {
    withName: 'pyprophet_.*' {
        containerOptions= '--env HOME="$PWD"'
    }
}
