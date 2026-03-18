# Configuration

The main configuration file needs to be created by the user. An example is available below. Alternatively all the switches can be passed from the command line.

(configuration-main-configuration-file)=
## Main configuration file

### Template

Example configuration that can be saved as `gladiator-config.nf`

:::{include} ./example-gladiator-config.md
:::

The configuration file is passed to `nextflow` explicitly

```sh
nextflow -c gladiator-config.nf ...
```

### Options

`fragment_mass_tolerance`
: passed to Comet as `fragment_bin_tol`  
  passed to Xtandem as `spectrum, fragment monoisotopic mass error`  
  **default:** `0.02`

`precursor_mass_tolerance`
: passed to Comet as `peptide_mass_tolerance`  
  passed to Xtandem as `spectrum, parent monoisotopic mass error {plus,minus}`  
  **default:** `10`

`protFDR`
: passed to Mayu as `cutoffrate`  
  **default:** `0.01`

`irt_traml_file` (optional)
: a URL to a `.TraML` file containing retention times (`ftp://...`, `https://...`)

`use_irt`
: enables use of `irt_traml_file`  
  **default:** `false`

`max_missed_cleavages`
: passed to Comet as `allowed_missed_cleavage`  
  passed to Xtandem as `scoring, maximum missed cleavage sites`  
  **default:** `1`

`libgen_method`
: selects software package used for generation of peptide library  
  **enum:** `diaumpire`, `dda`, `custom`  
  **default:** `diaumpire`

`pyprophet_use_legacy`
: enables older PyProphet 0.24.1, otherwise PyProphet 2.2.5 is used  
  **default:** `false`

`pyprophet_fixed_seed`
: passed to `pyprophet score`, for more reproductible results  
  **default:** `false`

`pyprophet_subsample_ratio`
: subsample ratio, a number or `null`  
  `null` is a special value that translates to 1 / number of samples  
  **default:** `null`

`fastafiles`
: path to the input files containing protein sequences  
  **default:** `fasta/*.fasta`

`sdrf`
: path to a `.sdrf` metadata file  

  Following configuration parameters of glaDIAtor-nf might be overriden by what is found in `.sdrf`
  * `fragment_mass_tolerance` based on `comment[fragment mass tolerance]`  
    Fragment mass tolerance needs to be given in Da and consistent across samples. Missing unit is interpreted as Da.
  * `precursor_mass_tolerance` based on `comment[precursor mass tolerance]`  
    Precursor mass tolerance needs to be given in ppm and consistent across samples. Missing unit is interpreted as ppm.
  * `diafiles` based on `comment[file uri]`  
    DIA files collected from `.sdrf` are added to the list of `diafiles`.  

  **default:** `null`

## Fine-tuning

Make a copy of `config/diaumpire.params`, `config/comet.params` or `config/xtandem.xml` to customize the configuration of related components.

It is necessary to also pass their locations when calling `nextflow` with `--diaumpireconfig="./diaumpire.params"`, `--comet_template="./comet.params"` and `--xtandem_template="./xtandem.params"` parameters.

### DIA-Umpire

::::{dropdown} Our default configuration file
`config/diaumpire.params`
:::{literalinclude} ../../../config/diaumpire.params
:language: text
:::
::::

Comparing to an example found at <https://github.com/Nesvilab/DIA-Umpire/blob/master/DIA_Umpire_SE/src/dia_umpire_se/diaumpire_se.params>, following modifications are present

```diff
-Thread = 6
+Thread = 4

 ExportPrecursorPeak = false
-ExportFragmentPeak = false

-SE.MS1PPM = 30
-SE.MS2PPM = 40
-SE.SN = 2
-SE.MS2SN = 2
-SE.MinMSIntensity = 10
-SE.MinMSMSIntensity = 10
-SE.MaxCurveRTRange = 1
-SE.Resolution = 17000
-SE.StartCharge = 2
-SE.EndCharge = 4
+SE.MS1PPM = 15
+SE.MS2PPM = 25
+SE.SN = 1.1
+SE.MS2SN = 1.1
+SE.MinMSIntensity = 1
+SE.MinMSMSIntensity = 1
+SE.MaxCurveRTRange = 2
+SE.Resolution = 60000
+SE.StartCharge = 1
+SE.EndCharge = 5

-SE.MS2EndCharge = 4
-SE.NoMissedScan = 1
+SE.MS2EndCharge = 5
+SE.NoMissedScan = 2
+SE.RemoveGroupedPeaks = true
+SE.RemoveGroupedPeaksRTOverlap = 0.3
+SE.RemoveGroupedPeaksCorr = 0.3

-SE.EstimateBG = true
+SE.EstimateBG = false

-SE.MinPrecursorMass = 700
+SE.MinPrecursorMass = 600

-WindowSize=25
+#WindowSize=15
```

* {bdg-warning}`pending` Above changes require further explanation and justification.
* {bdg-warning}`pending` We could provide some practical hints to the users.
* {bdg-warning}`pending` The configuration file could use cleanup of comments and reordering of entries to match example from DIA-Umpire.

### Comet

glaDIAtor-nf is using Comet 2022.01

::::{dropdown} Our default configuration file
`config/comet.params`

:::{literalinclude} ../../../config/comet.params
:language: ini
:::
::::

Three example configuration files can be found in Comet 2022.01 documentation

> * [comet.params.low-low](https://uwpr.github.io/Comet/parameters/parameters_202201/comet.params.low-low)
> for low res MS1 and low res MS2 e.g. ion trap   
> * [comet.params.high-low](https://uwpr.github.io/Comet/parameters/parameters_202201/comet.params.high-low)
> high res MS1 and low res MS2 e.g. Velos-Orbitrap  
> * [comet.params.high-high](https://uwpr.github.io/Comet/parameters/parameters_202201/comet.params.high-high)
> high res MS1 and high res MS2 e.g. Q Exactive or Q-Tof  

The difference is in following parameters

|  | `comet.params.low-low` | `comet.params.high-low` | `comet.params.high-high` |
|---|---|---|---|
| `peptide_mass_tolerance` | `3.0` amu | `20` ppm | `20` ppm |
| `precursor_tolerance_type` | `0` $\rightarrow$ _MH+_ | `1` $\rightarrow$ _precursor m/z_ | `1` $\rightarrow$ _precursor m/z_ |
| `isotope_error` | `0` $\rightarrow$ off | `3` $\rightarrow$ `0/1/2/3` | `3` $\rightarrow$ `0/1/2/3` |
| `fragment_bin_tol` | `1.0005` | `1.0005` | `0.02` |
| `fragment_bin_offset` | `0.4` | `0.4` | `0.0` |
| `theoretical_fragment_ions` | `1` $\rightarrow$ _M peak only_ | `1` $\rightarrow$ _M peak only_ | `0` $\rightarrow$ _use flanking peaks_ |

Our configuration file is based on `high-high` variant, with following changes

```diff
- database_name = /some/path/db.fasta
+ database_name = @DDA_DB_FILE@

- peptide_mass_tolerance = 20.00
+ peptide_mass_tolerance = @PRECURSOR_MASS_TOLERANCE@
  # 0=amu, 1=mmu, 2=ppm                
  peptide_mass_units = 2

  # maximum value is 5; for enzyme search
- allowed_missed_cleavage = 2
+ allowed_missed_cleavage = @MAX_MISSED_CLEAVAGES@

  # binning to use on fragment ions
- fragment_bin_tol = 1.0005
+ fragment_bin_tol = @FRAGMENT_MASS_TOLERANCE@

  # 0=no, 1=yes  write Percolator pin file
- output_percolatorfile = 0
+ output_percolatorfile = 1

  # activation method; used if activation method set; allowed ALL, CID, ECD, ETD, ETD+SA, PQD, HCD, IRMPD, SID
- activation_method = ALL
+ activation_method = HCD
```

`@PRECURSOR_MASS_TOLERANCE@`, `@MAX_MISSED_CLEAVAGES@`, `@FRAGMENT_MASS_TOLERANCE@` come from the [main configuration file](#configuration-main-configuration-file)

```nextflow
  ...
  fragment_mass_tolerance=0.02
  precursor_mass_tolerance=10
  max_missed_cleavages=1
  ...
```

Based on the example configurations of Comet, one might wish to manually adjust following parameters in `comet.params`
* `isotope_error = 0` for low resolution MS1
* `fragment_bin_offset = 0.4` and `theoretical_fragment_ions = 1` for low resolution MS2

All parameters offered by Comet 2022.01 are described at [uwpr.github.io/Comet](https://uwpr.github.io/Comet/parameters/parameters_202201).

<!--
:::{dropdown} Unanswered questions
:color: secondary

* Comment on `precursor_tolerance_type` `1=precursor m/z; only valid for amu/mmu tolerances` seems self-contradictory as the configuration sets it to `1` with `ppm`. We assume that the example is fine and the comment is wrong.
* 
:::
-->

### X! Tandem

glaDIAtor-nf is using X! Tandem 2017.02.01.4

::::{dropdown} Our default configuration file
`config/xtandem.xml`
:::{literalinclude} ../../../config/xtandem.xml
:language: xml
:::
::::

It is based on an example `default_input.xml` found in <ftp://ftp.thegpm.org/projects/tandem/source/tandem-linux-17-02-01-4.zip>.

Following changes were applied

```diff
-	<note type="input" label="list path, default parameters">default_input.xml</note>
-		<note>This value is ignored when it is present in the default parameter
-		list path.</note>
-	<note type="input" label="list path, taxonomy information">taxonomy.xml</note>

-	<note type="input" label="spectrum, fragment monoisotopic mass error">0.4</note>
-	<note type="input" label="spectrum, parent monoisotopic mass error plus">100</note>
-	<note type="input" label="spectrum, parent monoisotopic mass error minus">100</note>
+	<note type="input" label="spectrum, fragment monoisotopic mass error">@FRAGMENT_MASS_TOLERANCE@</note>
+	<note type="input" label="spectrum, parent monoisotopic mass error plus">@PRECURSOR_MASS_TOLERANCE@</note>
+	<note type="input" label="spectrum, parent monoisotopic mass error minus">@PRECURSOR_MASS_TOLERANCE@</note>

-	<note type="input" label="spectrum, threads">1</note>
+	<note type="input" label="spectrum, threads">40</note>

-	<note type="input" label="residue, potential modification mass"></note>
+	<note type="input" label="residue, potential modification mass">16@M</note>

+	<note type="input" label="protein, quick acetyl">no</note>
+	<note type="input" label="protein, quick pyrolidone">no</note>

-	<note type="input" label="refine, potential N-terminus modifications"></note>
+	<note type="input" label="refine, potential N-terminus modifications">+42.010565@[</note>

-	<note type="input" label="scoring, maximum missed cleavage sites">1</note>
+	<note type="input" label="scoring, maximum missed cleavage sites">@MAX_MISSED_CLEAVAGES@</note>

-	<note type="input" label="output, path hashing">yes</note>
+	<note type="input" label="output, path hashing">no</note>
```

 `@FRAGMENT_MASS_TOLERANCE@`, `@PRECURSOR_MASS_TOLERANCE@` and `@MAX_MISSED_CLEAVAGES@` come from the [main configuration file](#configuration-main-configuration-file)

```nextflow
  ...
  fragment_mass_tolerance=0.02
  precursor_mass_tolerance=10
  max_missed_cleavages=1
  ...
```

All configuration options of X! Tandem are described at <https://www.thegpm.org/TANDEM/api/index.html>. 
