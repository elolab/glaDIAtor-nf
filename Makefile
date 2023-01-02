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
containers/pyprophet-legacy.simg: ci/guix/pyrophet-channels.scm ci/guix/manifests/pyprophet.scm
	mkdir -p $(@D)
	cp `guix time-machine -C $< -- pack $(GUIX_PACK_FLAGS) --format=squashfs $(patsubst %,--manifest=%,$(wordlist 2,$(words $^),$^))` $@
