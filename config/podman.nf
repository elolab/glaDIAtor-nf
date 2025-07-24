podman.enabled=true
process {
   container='docker://docker.io/elolabfi/gladiator-guix:0.1.4-0-f7abd8'
   withName: 'DeepDIA.*' {
      container='docker://docker.io/elolabfi/deepdia:0.1.4-0-f7abd8'
   }
   
   // for nonlegacy pyprophet processes
   withName: 'pyprophet_.*' {
      container='docker://docker.io/elolabfi/pyprophet:0.1.4-0-f7abd8'
   }

   // because this is the more specific rule
   // we apply it last, so that it overrides the 'pyprophet_.*' rule if
   // this rule also applies
    withName: pyprophet_legacy {
	container='docker://docker.io/elolabfi/pyprophet-legacy:0.1.4-0-f7abd8'
   }
   // for perl-diamspep
   withName: 'DIAMS2PEP_.*'{
   // there is really no good single letter here
   	container='docker://docker.io/elolabfi/diams2pep:0.1.4-0-f7abd8'
   }
}

process {
    withName: 'pyprophet_.*' {
	containerOptions= '--env HOME="$PWD"'
    }
}
