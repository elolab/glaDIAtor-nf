# Containers

## Building locally

Containers are available from the public registry, but you can also build them yourself. The containers are defined by Guix manifests, and guix is needed to build them

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
