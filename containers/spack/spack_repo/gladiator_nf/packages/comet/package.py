# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems import makefile
from spack_repo.builtin.build_systems.makefile import MakefilePackage

from spack.package import *


class Comet(MakefilePackage):
    """An tandem mass spectrometry (MS/MS) sequence database search tool."""

    homepage = "https://uwpr.github.io/Comet"
    url = "https://github.com/UWPR/Comet/archive/refs/tags/v2026.01.1.tar.gz"
    git = "https://github.com/UWPR/Comet.git"

    maintainers("w8jcik")

    license("Apache-2.0")

    version("master", branch="master")
    version("2026.01.1", sha256="277e3a3de8e087b3b5c40c1ed792c845f7d33b53d2073841372664067b62a650")
    version("2025.03.0", sha256="7e1b1d9cf19a4af6c9fc3d2a635cb5066775904c7f3b486b7038a947cd6f3ead")
    version("2024.02.0", sha256="57ac30bc2d1a8b53c4eb3ccf7f282bbb36fa96691dacea7a41efa2205c288340")
    version("2023.01.2", sha256="4316230dab89e4cc16776e4c2bb1141b413fd1a347764abf5ce9e9bff522a4ca")

    depends_on("c", type="build")
    depends_on("cxx", type="build")

    parallel = False

    def edit(self, spec, prefix):
        mstoolkit_makefile = FileFilter("MSToolkit/Makefile")
        mstoolkit_makefile.filter(r"C = gcc", "")
        mstoolkit_makefile.filter(r"CC = g\+\+", "")
        mstoolkit_makefile.filter(r"$(CC)", '"$(CXX)"')

    def install(self, spec, prefix):
        mkdirp(prefix.bin)
        install("comet.exe", join_path(prefix.bin, "comet"))
