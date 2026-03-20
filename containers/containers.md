# Containers

## Building locally

Required containers are available from Docker Hub, but they can be also built locally.

### Spack

```bash
containers/spack/build.sh
```

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
