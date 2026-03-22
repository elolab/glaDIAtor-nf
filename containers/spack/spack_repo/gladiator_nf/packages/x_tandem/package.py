# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems import makefile
from spack_repo.builtin.build_systems.makefile import MakefilePackage

from spack.package import *


class XTandem(MakefilePackage):
    """Protein identification tool that matches tandem mass spectra to peptide sequences."""

    homepage = "https://www.thegpm.org/TANDEM"
    url = "ftp://ftp.thegpm.org/projects/tandem/source/tandem-linux-17-02-01-4.zip"

    maintainers("w8jcik")

    license("Artistic-1.0")

    version(
        "2017.02.01-4",
        sha256="012f928465d8b6f08ceca879872afc740f1cc806d9cfcf537ac4463de9757629",
        url="ftp://ftp.thegpm.org/projects/tandem/source/tandem-linux-17-02-01-4.zip"
    )

    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on("expat")

    def edit(self, spec, prefix):
        extra_cxxflags = "-std=c++03 -fpermissive"

        makefile = FileFilter("src/Makefile")
        makefile.filter(r"^CXXFLAGS = -O2 -DGCC4_3\s*", f"CXXFLAGS = -O2 -DGCC4_3 {extra_cxxflags}")
        makefile.filter(
            r"^LDFLAGS = -lpthread -L/usr/lib -lm /usr/lib64/libexpat.a\s*",
            f"LDFLAGS = -lpthread -L/usr/lib -lm {spec['expat'].libs[0]}"
        )

    def build(self, spec, prefix):
        with working_dir('src'):
            make()

    def install(self, spec, prefix):
        mkdirp(prefix.bin)
        install("bin/tandem.exe", join_path(prefix.bin, "tandem"))
