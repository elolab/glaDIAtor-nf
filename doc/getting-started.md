# Getting started

## Setup

Required software dependencies

* NextFlow 25.10.4, together with Java >= 17, <= 25
* Apptainer, Podman, Docker, Singularity or Guix

::::{tab-set}
:::{tab-item} Ubuntu 24.04 LTS
```sh
sudo apt install openjdk-25-jre-headless

# change the default Java if currently selected one is older than version 17
sudo update-alternatives --config java

curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
```

```sh
sudo apt update -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:apptainer/ppa -y
sudo apt update
sudo apt install apptainer -y
```
:::

:::{tab-item} CSC
* Puhti and Mahti offer Apptainer and LUMI offers Singularity out of the box.
* `nextflow` executable can be downloaded with `curl -s https://get.nextflow.io | bash` and placed somewhere in the `PATH`. Java is available as a module eg. `module add Java/17.0.7`.
:::
::::

Get the <https://github.com/elolab/glaDIAtor-nf>

```sh
git clone https://github.com/elolab/glaDIAtor-nf.git
```

## Tutorial

The workflow can be run at any location. The main entrypoint for the NextFlow is `gladiator-nf/workflow/gladiator.nf`.

Let's run this tutorial in a `tutorial` directory next to `gladiator-nf`

```sh
mkdir tutorial
cd tutorial
```

Download example input files

```sh
mkdir raw-dia-spectra
wget --no-directories --directory-prefix=raw-dia-spectra 'ftp://massive-ftp.ucsd.edu/v05/MSV000090837/raw/Exp03_repeat_90minGradient_from_Exp02_same_Mastermix/210820_Grad090_LFQ_'{A,B}'_01.raw'
```

```sh
mkdir protein-sequences
wget --directory-prefix=protein-sequences 'ftp://massive-ftp.ucsd.edu:/v05/MSV000090837/sequence/fasta/*.fasta'
```

Only one pair of technical replicates (`10820_Grad090_LFQ_A_01.raw` and `210820_Grad090_LFQ_B_01.raw`) is selected from [`MSV000090837`](https://massive.ucsd.edu/ProteoSAFe/dataset.jsp?task=07dff4c92f134519af9ed8a5f1d7b6c0) dataset to lower the storage and processing requirements. .mzML format is also available but .raw is used to demontstrate the conversion.

(convertion-to-mzml-and-peak-picking)=
### Conversion to mzML and peak picking

::::{tab-set}
:::{tab-item} Docker
```sh
MSCONVERT_CMD='find . -iname '"'"'raw-dia-spectra/*.raw'"'"' -print0 | xargs -P5 -0 -i wine msconvert {} --filter '"'"'titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"<SourcePath>", NativeID:"<Id>"'"'"' -o dia-spectra/'
echo "${MSCONVERT_CMD}" > ./msconvert.sh
chmod +x msconvert.sh

PWIZ_IMAGE_ID="$(docker pull chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.21354-9ee14c7)"
docker run -it  -v $PWD:$PWD -w $PWD $PWIZ_IMAGE_ID /bin/bash ./msconvert.sh
```
:::

:::{tab-item} Podman
```sh
MSCONVERT_CMD='find . -iname '"'"'raw-dia-spectra/*.raw'"'"' -print0 | xargs -P5 -0 -i wine msconvert {} --filter '"'"'titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"<SourcePath>", NativeID:"<Id>"'"'"' -o dia-spectra/'
echo "${MSCONVERT_CMD}" > ./msconvert.sh
chmod +x msconvert.sh

PWIZ_IMAGE_ID="$(podman pull docker://chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.21354-9ee14c7)"
podman run -it  -v $PWD:$PWD -w $PWD $PWIZ_IMAGE_ID /bin/bash ./msconvert.sh
```
:::

:::{tab-item} Apptainer
```sh
MSCONVERT_CMD='find . -iname '"'"'raw-dia-spectra/*.raw'"'"' -print0 | xargs -P5 -0 -i wine msconvert {} --filter '"'"'titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"<SourcePath>", NativeID:"<Id>"'"'"' -o dia-spectra/'
echo "${MSCONVERT_CMD}" > ./msconvert.sh
chmod +x msconvert.sh

apptainer pull pwiz.sif docker://chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.21354-9ee14c7
apptainer exec --bind $PWD pwiz.sif bash msconvert.sh
```
:::
::::

:::::{dropdown} Native ProteoWizard builds
:color: secondary
:icon: light-bulb

Many proprietary mass spectrometry formats can only be read using Windows-only converter blobs. These don’t run on Linux, and the Linux build of ProteoWizard doesn’t ship with them. Because of that, people are often forced to run the Windows build using Wine, inside a container to get full format support.

Otherwise convertion command would look like this

::::{tab-set}
:::{tab-item} Ubuntu 24.04
```sh
sudo apt install libpwiz-tools

find . -iname 'raw-dia-spectra/*.raw' -print0 | xargs -P5 -0 -i msconvert {} --filter 'titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"<SourcePath>", NativeID:"<Id>"' -o dia-spectra/
```
:::
::::
:::::

GlaDIAtor-nf requires input data to be peak picked before further processing. _Material and Methods_ document attached to the example files mention that centroid pick picking was already performed. Otherwise prepend additional `--filter` parameter to the `msconvert` command, typically `--filter "peakPicking true 1-"`.

(getting-started-configuration)=
### Configuration

Paste following to a new file, it can be called `gladiator-config.nf`

```{include} ./user-guide/configuration/example-gladiator-config.md
```

### Run glaDIAtor-nf

::::{tab-set}
:::{tab-item} Docker
```sh
gladiator_location="../gladiator-nf"

NXF_VER="22.10.1" nextflow -c gladiator-config.nf -c "${gladiator_location}/config/containers/docker.config" \
    run "${gladiator_location}/workflow/gladiator.nf" --diafiles='dia-spectra/*.mzML' --fastafiles='protein-sequences/*.fasta'
```
:::

:::{tab-item} Podman
```sh
gladiator_location="../gladiator-nf"

NXF_VER="22.10.1" nextflow -c gladiator-config.nf -c "${gladiator_location}/config/containers/podman.config" \
    run "${gladiator_location}/workflow/gladiator.nf" --diafiles='dia-spectra/*.mzML' --fastafiles='protein-sequences/*.fasta'
```
:::

:::{tab-item} Apptainer and Singularity
```sh
gladiator_location="../gladiator-nf"

NXF_VER="22.10.1" nextflow -c gladiator-config.nf -c "${gladiator_location}/config/containers/singularity.config" \
    run "${gladiator_location}/workflow/gladiator.nf" --diafiles='dia-spectra/*.mzML' --fastafiles='protein-sequences/*.fasta'
```
:::
::::

### Results

Two files should be available in the `./results` directory

- `dia/DIA-peptide-matrix.tsv` contains the intensitities on the peptide level

  ```
  | ProteinName_FullPeptideName                       | 210820_Grad090_LFQ_A_01.mzML   | 210820_Grad090_LFQ_B_01.mzML   |
  |---------------------------------------------------|--------------------------------|--------------------------------|
  | 1/A2I7N3_LAVSHVIHK                                | 624895                         | 723064                         |
  | 3/sp|P08729|K2C7_HUMAN/Q3KNV1/P08729_VDALNDEINFLR | 2037142                        | 1283280                        |
    ...
  ```

- `dia/DIA-protein-matrix.tsv` contains intensities are on the protein group level

  ```
  | ProteinName                                   | 210820_Grad090_LFQ_A_01.mzML | 210820_Grad090_LFQ_B_01.mzML |
  |-----------------------------------------------|------------------------------|------------------------------|
  | 1/sp|O14561|ACPM_HUMAN                        | 1410100                      | 1359820                      |
  | 2/sp|P0CX49|RL18A_YEAST/sp|P0CX50|RL18B_YEAST | 99249410                     | 44970930                     |
    ...
  ```

A different output directory can be selected with `--outdir` parameter.
