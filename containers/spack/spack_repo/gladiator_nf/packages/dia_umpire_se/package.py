# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from glob import glob

from spack_repo.builtin.build_systems.generic import Package

from spack.package import *


class DiaUmpireSe(Package):
    """Computational analysis for mass spectrometry-based proteomics data."""

    homepage = "https://diaumpire.nesvilab.org/"
    url = "https://github.com/Nesvilab/DIA-Umpire/archive/refs/tags/v2.2.8.tar.gz"
    git = "https://github.com/Nesvilab/DIA-Umpire.git"

    maintainers("w8jcik")

    license("GPL-3.0")

    version("2.3.4", commit="68b73feeec6b4ef4812b5b3a7c410270e609b1ad")
    version("2.3.2", commit="793fe1005e91cbdf1d18b1acf970f152b84d57a5")
    version("2.3.0", commit="e932bdaf81caa61c1579392732fe5671ef4401b0")
    version("2.2.9", commit="255e0fec1d3775fd9616c2e4c40e137ca1766476")
    version("2.2.8", sha256="94113ea5c088189a28afc88ccfd1e0e4435755a3f499beb1dab10df0fb927282")

    depends_on("java@11:15", type=("build", "run"))

    def install(self, spec, prefix):
        with working_dir("DIA_Umpire_SE"):
            gradlew = Executable("./gradlew")
            gradlew("clean", "build", "--no-daemon")

        mkdirp(prefix.lib)

        with working_dir("DIA_Umpire_SE/build/libs"):
            for jar in glob('*'):
                install(jar, prefix.lib)

        mkdirp(prefix.bin)
        install('DIA_Umpire_SE/build/scripts/DIA_Umpire_SE', prefix.bin)
