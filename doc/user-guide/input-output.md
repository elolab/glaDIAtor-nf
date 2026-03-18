# Input and output

**glaDIAtor-nf** consumes:

* `.mzML` or `.mzXML` files with spectra from DIA mass spectrometry
* `.mzML` or `.mzXML` files with spectra from DDA mass spectrometry (optional)
* `.fasta` files with corresponding protein aminoacid sequences
* [configuration files](./configuration/index.md)

<!-- If the dataset has Biognosys irt-peptides, pass `--use_irt=true` to the NextFlow invocation. -->

produces:

* sample × peptide abundance matrices in `.tsv`
* sample × protein abundance matrices in `.tsv`

## Input data from DIA and DDA

DIA and DDA input files need to be either in mzML or mzXML format, with the data simplified through pick picking.

In case the DIA or DDA data is in a proprietary raw format, a conversion is necessary. Both pick picking and convertion can be often performed with ProteoWizard `msconvert` and `qtofpeakpicker` tools.

Raw DDA files can be peak picked and converted to mzML with `qtofpeakpeaker`

```bash
for f in dda-spectra/*.wiff; do
  wine qtofpeakpicker --resolution=2000 --area=1 --threshold=1 --smoothwidth=1.1 --in $f --out dda-spectra/$(basename --suffix=.wiff $f).mzML
done
```

Raw DIA files can be peak picked and converted to mzML with `msconvert`

```bash
find . -iname 'dia-spectra/*.wiff' -print0 | xargs -P5 -0 -i wine msconvert {} --filter "peakPicking true 1-" --filter 'titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"<SourcePath>", NativeID:"<Id>"' -o dia-spectra/
```

Some raw data found in databases was already pick picked. In such case omit `--filter "peakPicking true 1-"` switch to perform only the conversion to mzML.

ProteoWizard is available as a Docker image at <https://hub.docker.com/r/chambm/pwiz-skyline-i-agree-to-the-vendor-licenses>. Use of this image is demonstrated in [getting started](#convertion-to-mzml-and-peak-picking).

:::{dropdown} mzML vs mzXML
:color: primary
:icon: light-bulb

mzXML format is a predecessor of mzML format. We recommend converting raw data directly to mzML and avoiding the use of the older mzXML format whenever possible.
:::
