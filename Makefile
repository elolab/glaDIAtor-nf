# This makefile automates container generation
# and file tangling.
# The following section (delimited by  (page breaks)
# are variables you can set as the user.
# 
# if you set SHELL=guix,
# this makefile will use guix time-machine & guix-shell to take care of dependencies
# To make e.g the docs, invoke as 
# $ make doc
# to _not_ use guix
# with guix invoke like so
# $ make SHELL=guix doc
# but even better
# $ guix time-machine -C ci/guix/channels.scm -- shell --container --share=/var/guix/daemon-socket/socket  make guix nss-certs --network -- make SHELL=guix doc
# or as 
# $ guix time-machine -C ci/guix/channels.scm -- shell --pure --preseve'^SSL_'  make guix -- make SHELL=guix doc


# one of docker , podman, or something else with a docker compatible interface
# can be prefixed by sudo and followed by common flags
# on guix system passing on the CLI DOCKER_EXECUTABLE="$(which sudo) docker" seems to work the best
# (you cannot pass sudo on as guix package, because that one will not be owned by root)
DOCKER_EXECUTABLE=podman


# Continuous integration variables for developers
# You can ignore these if you are not planning on doing a "docker push"
# Flags to pass to the docker login call,
# set to e.g. "-u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY"
DOCKER_LOGIN_FLAGS=
# whereunder the image should be placed
# e.g registry.example.com/project
DOCKER_REGISTRY_DIR=

# These flags are passed to guix pack
GUIX_PACK_FLAGS=

# The variables in this section are used to control guix time-machine
# and guix shell behaviour
# These variables are passed to guix time-machine and guix shell
MANIFESTS=
CHANNELS=ci/guix/channels.scm 
PACKAGES=

ifeq ($(SHELL),guix)
.SHELLFLAGS=time-machine $(patsubst %,--channels=%,$(CHANNELS)) -- shell $(PACKAGES) --pure --preserve='^SSL_' -v0 $(patsubst %,--manifest=%,$(MANIFESTS))  bash-minimal -- sh -c
endif


################# TARGETS ###############################
# This section defines the pseudo-targets that you might want to request

.PHONY: doc tangle all singularity-containers docker-containers docker-containers-push

CONTAINER_NAMES:=pyprophet-legacy gladiator
singularity-containers: $(patsubst %,containers/%.simg,$(CONTAINER_NAMES))
docker-containers: $(patsubst %,containers/%.tar,$(CONTAINER_NAMES))

all: tangle doc 
doc: notes.html notes.pdf

EMACSCMD=emacs --batch --eval "(setq enable-local-variables :all user-full-name \"\")" --eval "(require 'ob-dot)"

# temporarily set manifests to use to emacs.scm so that we can find what files the org-file tangles out to
MANIFESTS=ci/guix/manifests/emacs.scm
tangled-files :=$(shell $(EMACSCMD)  --file=notes.org --eval  "(princ (mapconcat 'car (org-babel-tangle-collect-blocks) \"\n\"))")
MANIFESTS=
tangle: $(tangled-files)



%.html: MANIFESTS = ci/guix/manifests/emacs.scm ci/guix/manifests/html-doc.scm
%.html: %.org .dir-locals.el 
	$(EMACSCMD) --file $< -f org-html-export-to-html


%.pdf: MANIFESTS = ci/guix/manifests/emacs.scm ci/guix/manifests/pdf-doc.scm
%.pdf: %.org .dir-locals.el
	$(EMACSCMD) --file $< -f org-latex-export-to-pdf


# the & indicate that a single invocation generates all
# see (info "(make) Multiple Targets") section _Grouped Targets"
$(tangled-files) &: MANIFESTS=ci/guix/manifests/emacs.scm
$(tangled-files) &: notes.org
	$(EMACSCMD) --file $< -f org-babel-tangle

containers/pyprophet-legacy.simg: MANIFESTS=
containers/pyprophet-legacy.simg: PACKAGES=guix coreutils bash-minimal
containers/pyprophet-legacy.simg: ci/guix/pyprophet-legacy-channels.scm ci/guix/manifests/pyprophet-legacy.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) --format=squashfs $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@
containers/pyprophet-legacy.tar: MANIFESTS=
containers/pyprophet-legacy.tar: PACKAGES=guix coreutils bash-minimal 
containers/pyprophet-legacy.tar: ci/guix/pyprophet-legacy-channels.scm ci/guix/manifests/pyprophet-legacy.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) --format=docker $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@


# If we are using docker as the docker execatuble,
# set the pacakges for docker tars to docker packages
# and some coreutils for cleaning up after us
# the %.tar files are 'docker-archives'
# the %-fs.tar files are filesystem archives
ifneq ($(findstring docker,$(DOCKER_EXECUTABLE)),)
containers/%.tar: PACKAGES=containerd docker docker-cli coreutils
containers/%-fs.tar:PACKAGES=containerd docker docker-cli coreutils sed
docker-containers-push: PACKAGES=containerd docker docker-cli coreutils sed
endif
ifneq ($(findstring podman,$(DOCKER_EXECUTABLE)),)
containers/%.tar: PACKAGES=podman coreutils
containers/%-fs.tar: PACKAGES=podman coreutils sed
docker-containers-push: PACKAGES=podman coreutils sed
endif

# we launch the docker daemon and clean it up later
# see https://stackoverflow.com/questions/31024268/starting-and-closing-applications-in-makefile
# $(filter %sudo sudo,$(DOCKER_EXECUTABLE)) returns:
# - `/bin/sudo` if DOCKER_EXECUTABLE="/bin/sudo docker"  ...
# - `sudo` if DOCKER_EXECUTABLE="sudo docker"
# - `` (i.e empty string) if DOCKER_EXECUTABLE="docker"
containers/%.tar: MANIFESTS=
containers/%.tar: %.dockerfile $(tangled-files)
	$(if $(findstring docker,$(DOCKER_EXECUTABLE)),\
		$(filter %sudo sudo,$(DOCKER_EXECUTABLE)) dockerd & echo $$! > dockerd.pid,\
		:)
# the above is not a smiley `:)`, but rather a "no-op" for the shell
	$(DOCKER_EXECUTABLE) build --tag $(*F) --file=$< .
	mkdir -p $(@D)
	$(DOCKER_EXECUTABLE) save $(*F) -o $@
	test -e dockerd.pid && $(filter %sudo sudo,$(DOCKER_EXECUTABLE)) kill `cat dockerd.pid` || true; 
	rm -f dockerd.pid

# The following turns a docker image tarball into a filesystem tarball
# so that they can be converted into a squashfs container
containers/%-fs.tar: containers/%.tar
	# we "export" the file system of a (in Docker-sepak) "container" rather than 
	# "save" the "image" so that we can tar2sqfs it (from squashfs-tools-ng) 
	# so that we dont need a singularity version that can "singularity build  docker-archive://file.tar"
	# (as the version of singularity in guix at commit 05e4efe0c83c09929d15a0f5faa23a9afc0079e4 is quite outdated)
	$(if $(findstring docker,$(DOCKER_EXECUTABLE)),\
		$(filter %sudo sudo,$(DOCKER_EXECUTABLE)) dockerd & echo $$! > dockerd.pid,\
		:)
	TAG=`$(DOCKER_EXECUTABLE) load --quiet --input $< | sed 's/^Loaded image: //g'`; $(DOCKER_EXECUTABLE) export `$(DOCKER_EXECUTABLE) create $$TAG` -o $@
	test -e dockerd.pid && $(filter %sudo sudo,$(DOCKER_EXECUTABLE)) kill `cat dockerd.pid` || true; 
	rm -f dockerd.pid

# gzip is the only compressor one that works for the singularity on the cluster
containers/%.simg: MANIFESTS=
containers/%.simg: PACKAGES=squashfs-tools-ng coreutils
containers/%.simg: containers/%-fs.tar
	cat $< | tar2sqfs --quiet --compressor=gzip $@

# Continuous integration stuff
docker-containers-push: docker-containers
	$(if $(findstring docker,$(DOCKER_EXECUTABLE)),\
		$(filter %sudo sudo,$(DOCKER_EXECUTABLE)) dockerd & echo $$! > dockerd.pid,\
		:)
	$(DOCKER_EXECUTABLE) login $(DOCKER_LOGIN_FLAGS) 
	$(patsubst %,\
	BASENAME=% && \
	TAG=`$(DOCKER_EXECUTABLE) load --quiet --input containers/$$BASENAME.tar|sed 's/^Loaded image: //g'` && \
	$(DOCKER_EXECUTABLE) tag $$TAG $(DOCKER_REGISTRY_DIR)/$$BASENAME &&  \
	$(DOCKER_EXECUTABLE) push $(DOCKER_REGISTRY_DIR)/$$BASENAME && ,\
	$(CONTAINER_NAMES)) :
	test -e dockerd.pid && $(filter %sudo sudo,$(DOCKER_EXECUTABLE)) kill `cat dockerd.pid` || true; 
	rm -f dockerd.pid
