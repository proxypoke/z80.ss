;; z80.ss - an emulator for the Zilog Z80
;;
;; Author: slowpoke <mail+git@slowpoke.io>
;;
;; This programm is Free Software under the non-terms
;; of the Anti-License. Do whatever the fuck you want.

(use srfi-69)  ;; hash tables

;; Our emulator requires a listing of all op codes, the amount of machine and
;; time cycles they require, as well as the mnemonic of that opcode. The latter
;; is more for debugging than for practial usage. For this, we define a record
;; structure for convenient storage and access to this information.
;;
;; NOTE: It might be possible to also store the function to execute in this
;; structure.

(define-record opcode code m-cycles t-cycles mnemonic)

;; To make debugging simpler, we also define a printer for the above record.

(define-record-printer (opcode x out)
  (fprintf out "~B: ~S (MC: ~S | TC: ~S)"
           (opcode-code x)
           (opcode-mnemonic x)
           (opcode-m-cycles x)
           (opcode-t-cycles x)))

;; Further, we store all our opcodes in a large hash table for fast access. We
;; will build this hash table from several smaller ones, each located within its
;; own file. This is mostly done for a clearer structure.
;;
;; For our convenience, we create a way to generate a function which builds the
;; record above and adds it to a captured hash table.

(define (make-add-function hash-table)
  (lambda (opcode m-cycles t-cycles mnemonic)
    (hash-table-set! hash-table
                     opcode
                     (make-opcode opcode m-cycles t-cycles mnemonic))))

;; It appears that wherever the names of the seven 8-bit registers are encoded
;; into an opcode, they use the same bit pattern. This is true at least for the
;; 8-bit Load Group. For now, we assume that this holds true everywhere, and
;; define them as constants.
;;
;; NOTE: Since there are only seven of these registers, one bit pattern - 110 -
;; is left unused.

(define register-codes (make-hash-table))

(hash-table-set! register-codes 'A #b111)
(hash-table-set! register-codes 'B #b000)
(hash-table-set! register-codes 'C #b001)
(hash-table-set! register-codes 'D #b010)
(hash-table-set! register-codes 'E #b011)
(hash-table-set! register-codes 'H #b100)
(hash-table-set! register-codes 'L #b101)

;; We now load all our opcode tables, by way of a function that will load all
;; the files, merge the hash-tables in them, and return the resulting opcode
;; table.
;;
;; XXX: The code in these files depends on definitions from this file. This
;; works because they are loaded into a scope where these definitions exist, but
;; it will likely make it impossible to compile them.

(define (load-opcodes)
  ;; For simplicity, we decree that all specific opcode tables are named the
  ;; same as the file that contains them, minus the extension. This makes it
  ;; possible to load them dynamically by just adding the extension to the table
  ;; name.
  (define opcode-table-list '(8-bit-load))

  ;; First, we load all the files.
  (for-each (lambda (table-name)
              (load (string-concatenate `("opcodes/"
                                          ,(symbol->string table-name)
                                          ".ss"))))
            opcode-table-list)

  ;; Now, we merge all the hash tables into one and return it.
  (foldl hash-table-merge
         (make-hash-table)
         (map eval opcode-table-list)))
