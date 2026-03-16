process {
    beforeScript="source <(guix time-machine -C $projectDir/ci/guix/gladiator-guix-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/gladiator.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"

    withName: "pyprophet_.*" {
        beforeScript="source <(guix time-machine -C $projectDir/ci/guix/gladiator-guix-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/pyprophet.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
    }

    withName: pyprophet_legacy {
        beforeScript="source <(guix time-machine -C $projectDir/ci/guix/pyprophet-legacy-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/pyprophet-legacy.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
    }

    withName: "DIAtracer" {
        beforeScript="source <(guix time-machine -C $projectDir/ci/guix/diatracer-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/diatracer.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
    }
}
