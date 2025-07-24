singularity.enabled=true
process {
   container='file://containers/gladiator-guix.simg'
   withName: 'DeepDIA.*' {
      container='file://containers/deepdia.simg'
   }
   
   // for nonlegacy pyprophet processes
   withName: 'pyprophet_.*' {
      container='file://containers/pyprophet.simg'
   }

   // because this is the more specific rule
   // we apply it last, so that it overrides the 'pyprophet_.*' rule if
   // this rule also applies
    withName: pyprophet_legacy {
	container='file://containers/pyprophet-legacy.simg'
   }
   // for perl-diamspep
   withName: 'DIAMS2PEP_.*'{
   // there is really no good single letter here
   	container='file://containers/diams2pep.simg'
   }
}

singularity.runOptions = '-B $TMPDIR:/tmp'
singularity.autoMounts=true
