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
# $ guix time-machine -C ci/guix/channels.scm -- shell --pure --preserve='^SSL_'  make guix -- make SHELL=guix doc


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
.SHELLFLAGS=time-machine $(patsubst %,--channels=%,$(CHANNELS)) -- shell $(PACKAGES) --pure --preserve='^SSH_' --preserve='GUIX_BUILD_OPTIONS' --preserve='^SSL_' -v0 $(patsubst %,--manifest=%,$(MANIFESTS))  bash-minimal -- sh -c
endif


# what  tag to give the images when pushing, e.g.
# pass CONTAINER_TAG=`git rev-parse --short HEAD` to make the tag the current commit ref,
# e.g will push gladiator as gladiator:deadbeef to the registry
# (no colon needed).
# if this is empty; then dont use any tag (so will default to "latest")
CONTAINER_TAG=



################# TARGETS ###############################
# This section defines the pseudo-targets that you might want to request

.PHONY: doc tangle all singularity-containers docker-containers docker-containers-push environment html info
# If you want to push only some of the containers to the registry
# set CONTAINER_NAMES on the command line to that subset.
CONTAINER_NAMES:=pyprophet-legacy gladiator-guix pyprophet deepdia diams2pep
singularity-containers: $(patsubst %,containers/%.simg,$(CONTAINER_NAMES))
docker-containers: $(patsubst %,containers/%.tar,$(CONTAINER_NAMES))

all: tangle doc
html: ci/doc/notes.html
doc: ci/doc/notes.html ci/doc/notes.pdf
info: ci/doc/notes.info

EMACSCMD=emacs --batch --eval "(setq enable-local-variables :all user-full-name \"\")" --eval "(require 'ob-dot)" 

# temporarily set manifests to use to emacs.scm so that we can find what files the org-file tangles out to
MANIFESTS=ci/guix/manifests/emacs.scm
tangled-files:=$(shell $(EMACSCMD)  --file=notes.org --eval  "(princ (mapconcat (lambda (x) (file-relative-name (car x))) (with-output-to-temp-buffer \"ignored-messages\" (let ((inhibit-message t)) (org-babel-tangle-collect-blocks))) \"\n\"))")
MANIFESTS=
tangle: $(tangled-files)

.INTERMEDIATE: dockerd.pid

%.html: MANIFESTS = ci/guix/manifests/emacs.scm ci/guix/manifests/html-doc.scm
%.html: %.org .dir-locals.el 
	$(EMACSCMD) --file $< -f org-html-export-to-html
ci/doc/%.html:  %.org .dir-locals.el ci/doc/make-doc.el
	$(EMACSCMD) --load ./ci/doc/make-doc.el  $< $@

%.info: MANIFESTS= ci/guix/manifests/emacs.scm ci/guix/manifests/texinfo-doc.scm
ci/doc/%.info:  %.org .dir-locals.el ci/doc/make-doc.el
	$(EMACSCMD) --load ./ci/doc/make-doc.el  $< $@

%.pdf: MANIFESTS = ci/guix/manifests/emacs.scm ci/guix/manifests/pdf-doc.scm

%.pdf: %.org .dir-locals.el
	$(EMACSCMD) --file $< -f org-latex-export-to-pdf

ci/doc/%.pdf:  %.org .dir-locals.el ci/doc/make-doc.el
	$(EMACSCMD) --load ./ci/doc/make-doc.el  $< $@


# the & indicate that a single invocation generates all
# see (info "(make) Multiple Targets") section _Grouped Targets"
$(tangled-files) &: MANIFESTS=ci/guix/manifests/emacs.scm
$(tangled-files) &: notes.org
	$(EMACSCMD) --file $< -f org-babel-tangle

containers/pyprophet-legacy.simg containers/pyprophet-legacy.tar: MANIFESTS=
containers/pyprophet-legacy.simg containers/pyprophet-legacy.tar: PACKAGES=guix coreutils bash-minimal
containers/pyprophet-legacy.simg containers/pyprophet-legacy.tar: ci/guix/pyprophet-legacy-channels.scm ci/guix/manifests/pyprophet-legacy.scm ci/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S/bin/bash=bin/bash --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@

containers/pyprophet.simg containers/pyprophet.tar: MANIFESTS=
containers/pyprophet.simg containers/pyprophet.tar: PACKAGES=guix coreutils bash-minimal
containers/pyprophet.simg containers/pyprophet.tar: ci/guix/channels.scm ci/guix/manifests/pyprophet.scm ci/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S/bin/bash=bin/bash --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@
containers/deepdia.simg containers/deepdia.tar: MANIFESTS=
containers/deepdia.simg containers/deepdia.tar: PACKAGES=guix coreutils bash-minimal
containers/deepdia.simg containers/deepdia.tar: ci/guix/deepdia-channels.scm ci/guix/manifests/deepdia.scm ci/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S/bin/bash=bin/bash --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@

containers/diams2pep.simg containers/diams2pep.tar: MANIFESTS=
containers/diams2pep.simg containers/diams2pep.tar: PACKAGES=guix coreutils bash-minimal
containers/diams2pep.simg containers/diams2pep.tar: ci/guix/diams2pep-channels.scm ci/guix/manifests/diams2pep.scm ci/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S/bin/bash=bin/bash --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@

# For some reason, -S /usr/bin/env=bin/env doesnt work for squashfs,
# but linking -S /usr=. (so to the profile dir) does work, so /usr/bin/env  exist this way.
containers/gladiator-guix.simg containers/gladiator-guix.tar: PACKAGES=guix coreutils bash-minimal
containers/gladiator-guix.simg containers/gladiator-guix.tar: ci/guix/gladiator-guix-channels.scm ci/guix/manifests/gladiator.scm ci/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S /bin/bash=bin/bash -S /usr=. --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@
# If we are using docker as the docker execatuble,
# set the pacakges for docker tars to docker packages
# and some coreutils for cleaning up after us
# the %.tar files are 'docker-archives'
# the %-fs.tar files are filesystem archives
ifneq ($(findstring docker,$(DOCKER_EXECUTABLE)),)
containers/%.tar: PACKAGES=containerd docker docker-cli coreutils
containers/%-fs.tar:PACKAGES=containerd docker docker-cli coreutils
docker-containers-push: PACKAGES=containerd docker docker-cli coreutils
endif
ifneq ($(findstring podman,$(DOCKER_EXECUTABLE)),)
containers/%.tar: PACKAGES=podman coreutils
containers/%-fs.tar: PACKAGES=podman coreutils
docker-containers-push: PACKAGES=podman coreutils
endif

# we launch the docker daemon and clean it up later
# see https://stackoverflow.com/questions/31024268/starting-and-closing-applications-in-makefile
# $(filter %sudo sudo,$(DOCKER_EXECUTABLE)) returns:
# - `/bin/sudo` if DOCKER_EXECUTABLE="/bin/sudo docker"  ...
# - `sudo` if DOCKER_EXECUTABLE="sudo docker"
# - `` (i.e empty string) if DOCKER_EXECUTABLE="docker"
containers/%.tar: MANIFESTS=
containers/%.tar: %.dockerfile $(tangled-files) | $(if $(findstring docker,$(DOCKER_EXECUTABLE)),dockerd.pid)
	$(DOCKER_EXECUTABLE) build --tag $(*F) --file=$< .
	mkdir -p $(@D)
	$(DOCKER_EXECUTABLE) save $(*F) -o $@

# The following turns a docker image tarball into a filesystem tarball
# so that they can be converted into a squashfs container.
# 
# the pipe in this recipe works around that docker outputs 'Loaded image: IMAGENAME',
# podman outputs Loaded image(s): IMAGENAME
# and maybe other stuff outputs in different formats
# now we just get the last white-space seperated word
# so we dont have to think about this.
containers/%-fs.tar: containers/%.tar | $(if $(findstring docker,$(DOCKER_EXECUTABLE)),dockerd.pid)
	# we "export" the file system of a (in Docker-sepak) "container" rather than 
	# "save" the "image" so that we can tar2sqfs it (from squashfs-tools-ng) 
	# so that we dont need a singularity version that can "singularity build  docker-archive://file.tar"
	# (as the version of singularity in guix at commit 05e4efe0c83c09929d15a0f5faa23a9afc0079e4 is quite outdated)
	LOADED_IMAGENAME=`$(DOCKER_EXECUTABLE) load --quiet --input $< | tr -s  '[:space:]' ' ' | tac -s' '| cut -d' ' -f1`; $(DOCKER_EXECUTABLE) export `$(DOCKER_EXECUTABLE) create $$LOADED_IMAGENAME sh` -o $@
	# the permissions on $@ can 700, and thus if the DOCKER_EXECUTABLE has sudo
	# it wont be readable by normal level processes.
	# so we chmod hit here
	$(filter %sudo sudo,$(DOCKER_EXECUTABLE)) chmod 755 $@


# gzip is the only compressor one that works for the singularity on the cluster
containers/%.simg: MANIFESTS=
containers/%.simg: PACKAGES=squashfs-tools-ng coreutils
containers/%.simg: containers/%-fs.tar
	cat $< | tar2sqfs --quiet --compressor=gzip $@

# Continuous integration stuff
# See containers/%-fs.tar for explanation of the pipe with 'tr' and 'cut'.
docker-containers-push: docker-containers | $(if $(findstring docker,$(DOCKER_EXECUTABLE)),dockerd.pid)
	$(DOCKER_EXECUTABLE) login $(DOCKER_LOGIN_FLAGS) 
	$(patsubst %,\
	BASENAME=% && \
	LOADED_IMAGENAME=`$(DOCKER_EXECUTABLE) load --quiet --input containers/$$BASENAME.tar| tr -s  '[:space:]' ' ' | tac -s' '| cut -d' ' -f1` && \
	TARGET_IMAGENAME=$(DOCKER_REGISTRY_DIR)/$$BASENAME$(and $(CONTAINER_TAG),:)$(CONTAINER_TAG)  && \
	$(DOCKER_EXECUTABLE) tag $$LOADED_IMAGENAME $$TARGET_IMAGENAME &&  \
	$(DOCKER_EXECUTABLE) push $$TARGET_IMAGENAME && ,\
	$(CONTAINER_NAMES)) :


environment: PACKAGES=coreutils
environment:
	env

TAGS: MANIFESTS=ci/guix/manifests/emacs.scm
TAGS: nextflow.tags $(wildcard *.org)
	etags --regex=@$< $(wordlist 2,$(words $^),$^) --output=$@

dockerd.pid: MANIFESTS=
dockerd.pid: PACKAGES=docker containerd coreutils
dockerd.pid:
	test -e /var/run/docker.sock && touch dockerd.pid || $(filter %sudo sudo,$(DOCKER_EXECUTABLE)) dockerd --iptables=false -G `id -gn` & echo $$! > dockerd.pid
	# waiting for docker to come live
	for ((i=0;i<300;i++)); do sleep 1; test -e /var/run/docker.pid && break || test -e /var/run/docker.sock && break; done
