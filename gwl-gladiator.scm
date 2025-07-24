(define-module (workflow)
  #:use-module (gwl workflows)
  #:use-module (gwl processes)
  #:use-module (gwl utils)
  #:use-module (gwl sugar))

(define fasta-files
  '("Q7M135.fasta" "trypsin.fasta"))

(define (join-fasta-files fasta-files)
  (make-process
   (name "join-fasta-files")
   (synopsis "Join fasta files into one file")
   (packages
    (cdr (quote
      ("join-fasta-files"
       "python"
       "biopython"))))
   (inputs (files fasta-files))
   (outputs "joined-fasta.fasta")
   # python
{
from Bio import SeqIO
def join_fasta_files(input_files, output_file):
    IDs = set()
    seqRecords = []
    for filename in input_files:
        records = SeqIO.index(filename, "fasta")
        for ID in records:
            if ID not in IDs:
                seqRecords.append(records[ID])
                IDs.add(ID)
            else:
                print("Found duplicated sequence ID " + str(ID) + ", skipping this sequence from file " + filename)

    SeqIO.write(seqRecords, output_file, "fasta")
join_fasta_files({{inputs}}.split(" "),{{outputs}})
}))

(define create-database-with-decoys
  (make-process
   (name "create-database-with-database")
   (synopsis "Add decoys to fasta database")
   (inputs "joined-fasta.fasta")
   (outputs "DB-with-decoys.fasta")
   (packages )
   # sh
     {
      DecoyDatabase -in $inputs -out $outputs
		    })))

(make-workflow
 (name "my-workflow")
 (processes
  (auto-connect
   (list
    (join-fasta-files fasta-files)
    create-database-with-decoys
    ))))

;; Local Variables;
;; compile-command: "guix shell guix guile gwl --with-git-url=gwl=git://git.savannah.gnu.org/gwl.git --with-commit=gwl=e233be5cf0e2f9cb37e3daa299f5031bea56ba71 -- guix workflow run -v10 gwl-gladiator.scm
;; End:

(map
 (lambda (x)
   (cons (car x)
   (list
    'specifications->manifest
    (cdr x))))
   
 '(
  ("join-fasta-files"
   "python"
   "biopython")
  ("generate-pseudo-spectra"
   "dia-umpire" 
   "pwiz") ;; the free one 
  ("swath2stats"
   "r-minimal"
   "r-swath2stats")
  ("trace"
   "procps"
   "grep"
   ;; core-utils are needed for touch, kill, test,head, tr ...
   ;; see the nxf_trace_linux() function in a nextflow jobs .command.run file
   "coreutils"
   "gawk"
   "sed")
))

(("join-fasta-files" specifications->manifest ("python" "biopython")) ("generate-pseudo-spectra" specifications->manifest ("dia-umpire" "pwiz")) ("swath2stats" specifications->manifest ("r-minimal" "r-swath2stats" "r-peca" "r-tidyr" "r-argparse" "r-corrplot")) ("trace" specifications->manifest ("procps" "grep" "bash-minimal" "gawk" "sed")))
