;; z80.ss - an emulator for the Zilog Z80
;;
;; Author: slowpoke <mail+git@slowpoke.io>
;;
;; This programm is Free Software under the non-terms
;; of the Anti-License. Do whatever the fuck you want.

;; The 8-bit Load Group contains operations for manipulating the 8-bit
;; general-purpose registers.

(define 8-bit-load (make-hash-table))

(let ((add (make-add-function 8-bit-load))
      (register-values (hash-table-values register-codes))
      (register-names (hash-table-keys register-codes)))

  ;; First, we generate all combinations for »LD r,r«.
  (for-each
    (lambda (first-register)
      (map (lambda (second-register)
             (let ((first-code
                     (arithmetic-shift (hash-table-ref register-codes
                                                       first-register)
                                       3))
                   (second-code (hash-table-ref register-codes
                                                second-register)))
               (add (+ #b01000000 first-code second-code)
                    1
                    4
                    (string-concatenate
                      (list "LD "
                            (symbol->string first-register)
                            ","
                            (symbol->string second-register))))))
           register-names))
    register-names)

  ;; Next is »LD r,n«.
  (for-each
    (lambda (register)
      (let ((code (arithmetic-shift (hash-table-ref register-codes register) 3)))
        (add (+ #b00000000 code #b110)
             2
             7
             (string-concatenate (list "LD " (symbol->string register) ",n")))))
    register-names))





