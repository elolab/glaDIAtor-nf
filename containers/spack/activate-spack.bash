# Features
# * Can be sourced from any location

# Optional tool https://gitlab.com/w8jcik/tiamat

if [ -e "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" ]; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.venv/bin/activate"
fi

export TIAMAT_EXTRA_SPACK_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/spack_repo/gladiator_nf"

# Spack

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/spack/share/spack/setup-env.sh"
