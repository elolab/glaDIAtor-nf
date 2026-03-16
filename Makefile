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
# $ guix time-machine -C containers/guix/channels.scm -- shell --container --share=/var/guix/daemon-socket/socket  make guix nss-certs --network -- make SHELL=guix doc
# or as 
# $ guix time-machine -C containers/guix/channels.scm -- shell --pure --preserve='^SSL_'  make guix -- make SHELL=guix doc

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
CHANNELS=containers/guix/channels.scm
PACKAGES=

ifeq ($(SHELL),guix)
.SHELLFLAGS=time-machine $(patsubst %,--channels=%,$(CHANNELS)) -- shell $(PACKAGES) --pure --preserve='^SSH_' --preserve='GUIX_BUILD_OPTIONS' --preserve='^SSL_' -v0 $(patsubst %,--manifest=%,$(MANIFESTS))  bash-minimal -- sh -c
endif

# Pass CONTAINER_TAG=`git rev-parse --short HEAD` to make the tag the current commit ref,
CONTAINER_TAG=

.PHONY: doc tangle all singularity-containers docker-containers docker-containers-push environment html info dist

# If you want to push only some of the containers to the registry
# set CONTAINER_NAMES on the command line to that subset.
CONTAINER_NAMES:=pyprophet-legacy gladiator-guix pyprophet
singularity-containers: $(patsubst %,containers/dist/%.simg,$(CONTAINER_NAMES))
docker-containers: $(patsubst %,containers/dist/%.tar,$(CONTAINER_NAMES))

all: singularity-containers docker-containers

html: ci/doc/notes.html
doc: ci/doc/notes.html ci/doc/notes.pdf
info: ci/doc/notes.info

EMACSCMD=emacs --batch --eval "(setq enable-local-variables :all user-full-name \"\")" --eval "(require 'ob-dot)" 

# temporarily set manifests to use to emacs.scm so that we can find what files the org-file tangles out to
MANIFESTS=containers/guix/manifests/emacs.scm
tangled-files:=$(shell $(EMACSCMD)  --file=notes.org --eval  "(princ (mapconcat (lambda (x) (file-relative-name (car x))) (with-output-to-temp-buffer \"ignored-messages\" (let ((inhibit-message t)) (org-babel-tangle-collect-blocks))) \"\n\"))")
MANIFESTS=
tangle: $(tangled-files)

.INTERMEDIATE: dockerd.pid

%.html: MANIFESTS = containers/guix/manifests/emacs.scm containers/guix/manifests/html-doc.scm
%.html: %.org .dir-locals.el 
	$(EMACSCMD) --file $< -f org-html-export-to-html

dist: gladiator-nf.tar

gladiator-nf.tar: MANIFESTS=containers/guix/manifests/make-dist.scm
gladiator-nf.tar: $(tangled-files) ci/doc/notes.html ci/doc/notes.info ci/doc/notes.pdf
	git archive -o $@ HEAD
	tar -f $@ --delete ci/doc/notes.html ci/doc/notes.info ci/doc/notes.pdf
	tar -f $@ --append $^

ci/doc/%.html:  %.org .dir-locals.el ci/doc/make-doc.el
	$(EMACSCMD) --load ./ci/doc/make-doc.el  $< $@

%.info: MANIFESTS= containers/guix/manifests/emacs.scm containers/guix/manifests/texinfo-doc.scm
ci/doc/%.info:  %.org .dir-locals.el ci/doc/make-doc.el
	$(EMACSCMD) --load ./ci/doc/make-doc.el  $< $@

%.pdf: MANIFESTS = containers/guix/manifests/emacs.scm containers/guix/manifests/pdf-doc.scm

%.pdf: %.org .dir-locals.el
	$(EMACSCMD) --file $< -f org-latex-export-to-pdf

ci/doc/%.pdf:  %.org .dir-locals.el ci/doc/make-doc.el
	$(EMACSCMD) --load ./ci/doc/make-doc.el  $< $@


# the & indicate that a single invocation generates all
# see (info "(make) Multiple Targets") section _Grouped Targets"
$(tangled-files) &: MANIFESTS=containers/guix/manifests/emacs.scm
$(tangled-files) &: notes.org
	$(EMACSCMD) --file $< -f org-babel-tangle

containers/dist/pyprophet-legacy.simg containers/dist/pyprophet-legacy.tar: MANIFESTS=
containers/dist/pyprophet-legacy.simg containers/dist/pyprophet-legacy.tar: PACKAGES=guix coreutils bash-minimal
containers/dist/pyprophet-legacy.simg containers/dist/pyprophet-legacy.tar: containers/guix/pyprophet-legacy-channels.scm containers/guix/manifests/pyprophet-legacy.scm containers/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S/bin/bash=bin/bash --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@

containers/dist/pyprophet.simg containers/dist/pyprophet.tar: MANIFESTS=
containers/dist/pyprophet.simg containers/dist/pyprophet.tar: PACKAGES=guix coreutils bash-minimal
containers/dist/pyprophet.simg containers/dist/pyprophet.tar: containers/guix/channels.scm containers/guix/manifests/pyprophet.scm containers/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S/bin/bash=bin/bash --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@

# For some reason, -S /usr/bin/env=bin/env doesnt work for squashfs,
# but linking -S /usr=. (so to the profile dir) does work, so /usr/bin/env  exist this way.
containers/dist/gladiator-guix.simg containers/dist/gladiator-guix.tar: PACKAGES=guix coreutils bash-minimal
containers/dist/gladiator-guix.simg containers/dist/gladiator-guix.tar: containers/guix/gladiator-guix-channels.scm containers/guix/manifests/gladiator.scm containers/guix/manifests/nextflow-trace.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) -S /bin/bash=bin/bash -S /usr=. --format=$(if $(filter %.tar,$@),docker,squashfs) $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@

# the %.tar files are 'docker-archives'
# the %-fs.tar files are filesystem archives
ifneq ($(findstring docker,$(DOCKER_EXECUTABLE)),)
containers/dist/%.tar: PACKAGES=containerd docker docker-cli coreutils
containers/dist/%-fs.tar:PACKAGES=containerd docker docker-cli coreutils
docker-containers-push: PACKAGES=containerd docker docker-cli coreutils
endif
ifneq ($(findstring podman,$(DOCKER_EXECUTABLE)),)
containers/dist/%.tar: PACKAGES=podman coreutils
containers/dist/%-fs.tar: PACKAGES=podman coreutils
docker-containers-push: PACKAGES=podman coreutils
endif

# The following turns a docker image tarball into a filesystem tarball
# so that they can be converted into a squashfs container.
# 
# the pipe in this recipe works around that docker outputs 'Loaded image: IMAGENAME',
# podman outputs Loaded image(s): IMAGENAME
# and maybe other stuff outputs in different formats
# now we just get the last white-space seperated word
# so we dont have to think about this.
containers/dist/%-fs.tar: containers/dist/%.tar | $(if $(findstring docker,$(DOCKER_EXECUTABLE)),dockerd.pid)
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
containers/dist/%.simg: MANIFESTS=
containers/dist/%.simg: PACKAGES=squashfs-tools-ng coreutils
containers/dist/%.simg: containers/dist/%-fs.tar
	cat $< | tar2sqfs --quiet --compressor=gzip $@

# Continuous integration stuff
# See containers/dist/%-fs.tar for explanation of the pipe with 'tr' and 'cut'.
docker-containers-push: docker-containers | $(if $(findstring docker,$(DOCKER_EXECUTABLE)),dockerd.pid)
	$(DOCKER_EXECUTABLE) login $(DOCKER_LOGIN_FLAGS) 
	$(patsubst %,\
	BASENAME=% && \
	LOADED_IMAGENAME=`$(DOCKER_EXECUTABLE) load --quiet --input containers/dist/$$BASENAME.tar| tr -s  '[:space:]' ' ' | tac -s' '| cut -d' ' -f1` && \
	TARGET_IMAGENAME=$(DOCKER_REGISTRY_DIR)/$$BASENAME$(and $(CONTAINER_TAG),:)$(CONTAINER_TAG)  && \
	$(DOCKER_EXECUTABLE) tag $$LOADED_IMAGENAME $$TARGET_IMAGENAME &&  \
	$(DOCKER_EXECUTABLE) push $$TARGET_IMAGENAME && ,\
	$(CONTAINER_NAMES)) :

environment: PACKAGES=coreutils
environment:
	env

TAGS: MANIFESTS=containers/guix/manifests/emacs.scm
TAGS: nextflow.tags $(wildcard *.org)
	etags --regex=@$< $(wordlist 2,$(words $^),$^) --output=$@
