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
# $ guix time-machine -C ci/guix/channels.scm -- shell --pure  make guix -- make SHELL=guix doc


# These variables are passed to guix time-machine and guix shell
MANIFESTS=ci/guix/manifests/emacs.scm
CHANNELS=ci/guix/channels.scm 
PACKAGES=
GUIX_PACK_FLAGS=

# one of docker , podman, or something else with a docker compatible interface
# can be prefixed by sudo and followed by common flags
# on guix system passin on the CLI DOCKER_EXECUTABLE="$(which sudo) docker" seems to work the best
# (you cannot pass sudo on as package,
# because that one will not be owned by root)
DOCKER_EXECUTABLE=podman

ifeq ($(SHELL),guix)
.SHELLFLAGS=time-machine $(patsubst %,--channels=%,$(CHANNELS)) -- shell $(PACKAGES) --pure -v0 $(patsubst %,--manifest=%,$(MANIFESTS))  bash-minimal -- sh -c
endif

.PHONY: doc tangle
doc: notes.html notes.pdf
EMACSCMD=emacs --batch --eval "(setq enable-local-variables :all user-full-name \"\")" --eval "(require 'ob-dot)"

# determine what files notes.org tangles out into
tangled-files :=$(shell $(EMACSCMD)  --file=notes.org --eval  "(princ (mapconcat 'car (org-babel-tangle-collect-blocks) \"\n\"))")
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
containers/pyprophet-legacy.simg: ci/guix/pyprophet-channels.scm ci/guix/manifests/pyprophet.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) --format=squashfs $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@

# If we are using docker as the docker execatuble,
# set the pacakges for docker tars to docker packages
# and some coreutils for cleaning up after us
ifneq ($(findstring docker,$(DOCKER_EXECUTABLE)),)
containers/%.tar: PACKAGES=containerd docker docker-cli coreutils
endif
ifneq ($(findstring podman,$(DOCKER_EXECUTABLE)),)
containers/%.tar: PACKAGES=podman coreutils
endif
containers/%.tar: MANIFESTS=
containers/%.tar: Dockerfile $(tangled-files)
# we launch the docker daemon and clean it up later
# see https://stackoverflow.com/questions/31024268/starting-and-closing-applications-in-makefile
ifneq ($(findstring docker,$(DOCKER_EXECUTABLE)),)
	$(filter %sudo sudo,$(DOCKER_EXECUTABLE)) dockerd & echo $$! > dockerd.pid
	$(DOCKER_EXECUTABLE) build --tag $(*F) --file=$< .
	# we "export" the file system of a (in Docker-sepak) "container" rather than 
	# "save" the "image" so that we can tar2sqfs it (from squashfs-tools-ng) 
	# so that we dont need a singularity version that can deal
	mkdir -p $(@D)
	$(DOCKER_EXECUTABLE) export `$(DOCKER_EXECUTABLE) create $(*F)`  -o $@
	if test -e dockerd.pid; then \
	   $(filter %sudo sudo,$(DOCKER_EXECUTABLE)) kill `cat dockerd.pid` || true; \
	   rm -f dockerd.pid \
	fi;
else
	mkdir -p $(@D)
	$(DOCKER_EXECUTABLE) build --tag $(*F) --file=$< .
	# we "export" the file system of a (in Docker-sepak) "container" rather than 
	# "save" the "image" so that we can tar2sqfs it (from squashfs-tools-ng) 
	# so that we dont need a singularity version that can deal  
	$(DOCKER_EXECUTABLE)pexport `$(DOCKER_EXECUTABLE) create $(*F)`  -o $@
endif
# gzip is the only compressor one that works for the singularity on the c
# cat alpine-fs.tar | tar2sqfs --compressor=gzip  alpine-fs-gzip.sqfs
containers/%.simg: MANIFEST=
containers/%.simg: PACKAGES=squashfs-tools-ng coreutils
containers/%.simg: containers/%.tar
	cat $< | tar2sqfs --compressor=gzip $@
