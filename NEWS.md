# Release notes

## Pending

### Breaking changes

* A parameter have been changed in the default configuration of DIA-Umpire SE
  ```diff
  - SE.EstimateBG = false
  + SE.EstimateBG = true
  ```
  This will affect your results. You can restore the previous behavior by making a copy of `config/diaumpire.params` file with `SE.EstimateBG = false` set and passing the it to NextFlow with `nextflow ... --diaumpireconfig=custom-diaumpire.params`.

## 0.2.0

### Features

* Workflow can be started from any location  
  The previous approach was to place the input files inside of cloned repository. It is no longer encouraged or necessary.

### Fixes

* Workflow no longer produces NextFlow warnings when running (side effect of rewrite to DSL2)

### Maintenance

* Port from DSL1 to DSL2, support latest NextFlow (25.10.4), previously NextFlow <= 22.10
* E2E test based on subset of tutorial input files
* Sphinx-based documentation system
* Cleanup of documentation articles
* Removed EMACS as dependency 

## 0.1.7

The last DSL1-based release.
