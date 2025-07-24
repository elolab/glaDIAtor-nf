process {
   beforeScript="source <(guix time-machine -C $projectDir/ci/guix/gladiator-guix-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/gladiator.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
   withName: "DeepDIA.*" {
      beforeScript="source <(guix time-machine -C $projectDir/ci/guix/deepdia-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/deepdia.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
   }
   
   // for nonlegacy pyprophet processes
   withName: "pyprophet_.*" {
      beforeScript="source <(guix time-machine -C $projectDir/ci/guix/gladiator-guix-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/pyprophet.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
   }

   // because this is the more specific rule
   // we apply it last, so that it overrides the "pyprophet_.*" rule if
   // this rule also applies
    withName: pyprophet_legacy {
	beforeScript="source <(guix time-machine -C $projectDir/ci/guix/pyprophet-legacy-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/pyprophet-legacy.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
   }
   // for perl-diamspep
   withName: "DIAMS2PEP_.*"{
   // there is really no good single letter here
   	beforeScript="source <(guix time-machine -C $projectDir/ci/guix/diams2pep-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/diams2pep.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
   }

   withName: "DIAtracer" {
     beforeScript="source <(guix time-machine -C $projectDir/ci/guix/diatracer-channels.scm -- shell --search-paths -m $projectDir/ci/guix/manifests/diatracer.scm -m $projectDir/ci/guix/manifests/nextflow-trace.scm)"
   }
}
