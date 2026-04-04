# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.cmake import CMakePackage

from spack.package import *


class Openms(CMakePackage):
    homepage = "https://www.openms.de"
    url = "https://github.com/OpenMS/OpenMS/archive/refs/tags/release/3.5.0.tar.gz"
    git = "https://github.com/OpenMS/OpenMS.git"

    maintainers("w8jcik")

    version("3.6.0-15943b8-dev", commit="15943b8f1ce37e934cec00bbf64d0e875404a29c")
    version("3.5.0", sha256="550edea8ec9e468e0cdb3dc45677a193cb4b425e52d4ed84547addacd0445c2e")
    version("3.4.1", sha256="fa878fc4efb27151f475dbf59bb3d6a301891bf8c8eb7968934c92e3f2157909")

    variant("gui", default=False, description="Build OpenMS GUI (TOPPView and TOPP utilities)")
    variant("pyopenms", default=False, description="Build pyOpenMS Python package")
    variant("hdf5", default=False, description="Enable HDF5 I/O")
    variant("coinor", default=True, description="Use COIN-OR CoinMP solver (otherwise GLPK)")

    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on("cmake@3.21:", type="build")

    depends_on("boost+regex+iostreams+date_time+math+pic")
    depends_on("boost@1.80:", when="@3.6:")
    depends_on("boost@1.74:", when="@3.5")
    depends_on("boost@1.74:1.88", when="@3.4")
    depends_on("libsvm@2.91:")
    depends_on("xerces-c")

    depends_on("coinmp", when="+coinor")
    depends_on("clp", when="+coinor")
    depends_on("osi", when="+coinor")
    depends_on("coinutils", when="+coinor")
    depends_on("glpk", when="~coinor")

    depends_on("eigen@3.4:5", when="@3.6:")
    depends_on("eigen@3.3.4:5", when="@3.5")
    depends_on("eigen@3.3.4:4", when="@:3.4")
    depends_on("libzip", when="@3.6.0:")
    depends_on("zlib", when="@3.5.0:")
    depends_on("bzip2")
    depends_on("arrow@23:+parquet", when="@3.5:")
    depends_on("hdf5+cxx", when="+hdf5")

    depends_on("python", type=("build", "run"), when="+pyopenms")
    depends_on("py-uv", type=("build", "run"), when="@3.6:+pyopenms")
    depends_on("py-numpy@2:", type=("run"), when="@3.6:+pyopenms")
    depends_on("py-matplotlib@3.5:", type=("run"), when="@3.6:+pyopenms")

    # Although these dependencies are correct, one would need to package 'autowrap' as well
    # depends_on("py-cython@:3.1", type="build", when="@3.5+pyopenms")
    # depends_on("py-cython@:3", type="build", when="@:3.4+pyopenms")
    # depends_on("py-packaging", type="build", when="@:3.5+pyopenms")
    # depends_on("py-pip", type="build", when="@:3.5")
    conflicts("@:3.5+pyopenms", msg="Building of pyOpenMS from older OpenMS would require packaging of https://github.com/OpenMS/autowrap")

    depends_on("qt-base+gui+network", when="@3.4:3.5")
    depends_on("qt-base+gui+opengl", when="+gui")
    depends_on("qt-svg", when="^qt-base+gui")
    depends_on("qt-base@6.5:", when="@3.4:")
    conflicts("@:3.3", msg="Older versions of OpenMS based on Qt5 are not covered by this recipe")

    def cmake_args(self):
        args = [
            self.define_from_variant("WITH_GUI", "gui"),
            self.define_from_variant("WITH_HDF5", "hdf5"),
            self.define_from_variant("PYOPENMS", "pyopenms"),
            self.define("MT_ENABLE_OPENMP", True),
            self.define("ENABLE_DOCS", False),
            self.define("HAS_XSERVER", False)
        ]

        if "+coinor" in self.spec:
            cxx_flags = {
                f"-I{self.spec['clp'].prefix.include}/coin",
                f"-I{self.spec['osi'].prefix.include}/coin",
                f"-I{self.spec['coinutils'].prefix.include}/coin"
            }

            args.append(self.define("CMAKE_CXX_FLAGS", " ".join(cxx_flags)))

        if self.spec.satisfies("~coinor"):
            # tests/class_tests/../LPWrapper_test fails with GLPK
            args.append(self.define("ENABLE_CLASS_TESTING", False))

        return args

    def setup_run_environment(self, env):
        if self.spec.satisfies("+pyopenms"):
            env.prepend_path("PYTHONPATH", self.prefix)
