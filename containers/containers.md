# Containers

## Building locally

Required containers are available from Docker Hub, but they can be also built locally.

### Guix

::::{tab-set}
:::{tab-item} Ubuntu 24.04 LTS
sudo apt install guix -y
:::
::::

```bash
make SHELL=guix
```

or more specific

```bash
make SHELL=guix singularity-containers
make SHELL=guix docker-containers
```

### Spack

```bash
containers/spack/build.sh
```

Spack packages and containers are used for profiling and testing of new features.  
They are currently not used by the production workflow.

:::{hint}
Packages that go to containers can be also installed on host system, which is convenient for profiling

```sh
containers/spack/setup-spack.sh
```

```sh
source containers/spack/activate-spack.bash
spack install dia-umpire-se@2.3.4
```

```sh
source containers/spack/activate-spack.bash
spack load dia-umpire-se
psrecord --include-children 'DIA_Umpire_SE example.mzML dia-umpire.params' --log activity.csv --plot plot.png
```
:::
