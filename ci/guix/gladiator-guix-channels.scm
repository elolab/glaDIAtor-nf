(list (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (branch "master")
        (commit
          "05e4efe0c83c09929d15a0f5faa23a9afc0079e4")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
             "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
       (name 'unelo-guix)
       (url "git@gitlab.utu.fi:elixirdianf/unelo-proteomics.git")
       (branch "master")
       (commit
	"314db86988a01ae9d0290d437965ee1760b9a055"))
      (channel
       (name 'unelo-guix-nonfree)
       (url "git@gitlab.utu.fi:elixirdianf/unelo-proteomics-nonfree.git")
       (branch "master")
       (commit "bea649c886a4fc09cb28005f5924a78309b9ec39")))
