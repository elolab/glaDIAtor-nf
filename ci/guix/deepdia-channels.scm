(list 
 (channel
  (name 'guix)
  (url "https://git.savannah.gnu.org/git/guix.git")
  (branch "master")
  (commit
   ;; last revisision where keras built;
   ;; see https://issues.guix.gnu.org/60545
   "2387adf60022799a8af144ed8dd2b7a46c155374")
  (introduction
   (make-channel-introduction
    "9edb3f66fd807b096b48283debdcddccfea34bad"
    (openpgp-fingerprint
     "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
 ;; our branch of deepdia that makes it a proper python package.
 (channel
  (name 'deepdia-packages)
  (url "git@gitlab.utu.fi:elixirdianf/deepdia.git")
  (branch "guix-channel")
  (commit "dd3a726b03be9b4838c50fa745e2aa937b02ca37")))
