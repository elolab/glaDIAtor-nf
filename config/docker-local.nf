docker.enabled=true
process {
   container='localhost/gladiator-guix'
   withName: 'DeepDIA.*' {
      container='localhost/deepdia'
   }
   
   // for nonlegacy pyprophet processes
   withName: 'pyprophet_.*' {
      container='localhost/pyprophet'
   }

   // because this is the more specific rule
   // we apply it last, so that it overrides the 'pyprophet_.*' rule if
   // this rule also applies
    withName: pyprophet_legacy {
	container='localhost/pyprophet-legacy'
   }
   // for perl-diamspep
   withName: 'DIAMS2PEP_.*'{
   // there is really no good single letter here
   	container='localhost/diams2pep'
   }
}

process {
    withName: 'pyprophet_.*' {
	containerOptions= '--env HOME="$PWD"'
    }
}
