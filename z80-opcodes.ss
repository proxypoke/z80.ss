;; z80.ss - an emulator for the Zilog Z80
;;
;; Author: slowpoke <mail+git@slowpoke.io>
;;
;; This programm is Free Software under the non-terms
;; of the Anti-License. Do whatever the fuck you want.

(use srfi-69)  ;; hash tables
(use srfi-1)   ;; handy list procedures
(use format)   ;; better format strings

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
  (format out "~8,'0B: ~A (MC: ~A | TC: ~A)"
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

;; Since many opcodes can be defined as bit patterns with some variable parts,
;; it makes sense to define groups of them as templates. For example, the group
;; of opcodes for »LD r,r'« can be written as the bit pattern 01[r][r'] (both r
;; and r' being 3 bit long).
;; We can use the format egg to do this easily.
;;
;; All opcodes operating on 8-bit registers can be defined by the following
;; pattern:
;;  - a two bit "prefix"
;;  - two three bit groups which are either fixed or encode a register name.
;;
;; We can therefore define a format function which can easily create opcodes
;; given these three arguments. The first must always be an integer between zero
;; and three (#b00 to #b11). The second and third argument can be either an
;; integer between zero and seven (#b000 to #b111), or a list of these.
;;
;; In the latter case, all cases will be generated. The function will return a
;; list of one or more formatted opcodes.

(define (opcode-format-8-bit prefix group1 group2)
  (let ((fmt-string "~2,'0B~3,'0B~3,'0B")
        (dec (lambda (x) (string->number x 2))))
    (cond
      ;; The first case is the trivial one: we have a fixed opcode. We return a
      ;; list with a single opcode.
      ((and (integer? group1) (integer? group2))
       (list (dec (format fmt-string prefix group1 group2))))
      ;; The next case is the most complicated one, with two variables. We do
      ;; this one first because the other two are simpler cases of this one.
      ((and (list? group1) (list? group2))
       (flatten
         (map
           (lambda (first-code)
             (map
               (lambda (second-code)
                 (dec (format fmt-string prefix first-code second-code)))
               group2))
           group1)))
      ;; As stated above, the next two conditions are merely corner cases of the
      ;; more general one, and we can easily transform them into the general
      ;; case by changing the argument which is a number into a list with a
      ;; single member, and calling the function again.
      ((and (list? group1) (integer? group2))
       (opcode-format-8-bit prefix group1 (list group2)))
      ((and (integer? group1) (list? group2))
       (opcode-format-8-bit prefix (list group1) group2)))))
      ;; All other cases basically mean something went wrong. We do not handle
      ;; any errors right now. (TODO)

;; We also want a way to format mnemonics, analogous to opcodes. Most opcodes
;; follow a similar format:
;;  - the name of the command (eg. NOP, INC, or LD)
;;  - a space character
;;  - if applicable, the first operand
;;  - if applicable, a comma, immediately followed by the second operand
;;
;;  For simplicity's sake, we just take any number of operands and join them
;;  with a comma. This works for all cases we need and more.

(define (mnemonics-format command #!optional operand1 operand2)
  (cond
    ;; If we only have a command without operands, we can simply return it in a
    ;; list.
    ((and (not operand1) (not operand2)) (list command))
    ;; The two single operand cases are pretty simple, as well.
    ((and (or (string? operand1) (symbol? operand1)) (not operand2))
     (list (format "~A ~A" command operand1)))
    ((and (list? operand1) (not operand2))
     (map (lambda (op) (mnemonics-format command op)) operand1))
    ;; In the simplest case for two operands, we simply return a single-member
    ;; list containing the formatted mnemonic.
    ((and (or (string? operand1) (symbol? operand1))
          (or (string? operand2) (symbol? operand2)))
     (list (format "~A ~A,~A" command operand1 operand2)))
    ;; As with opcode-format, we will now construct the general case, onto which
    ;; the remaining cases will fall back.
    ((and (list? operand1) (list? operand2))
     (flatten
       (map
         (lambda (first-arg)
           (map
             (lambda (second-arg)
               ;; We can just generate a single-member list here because we
               ;; flatten the final result anyways.
               (mnemonics-format command first-arg second-arg))
             operand2))
         operand1)))
    ((and (list? operand1) (or (string? operand2) (symbol? operand2)))
     (mnemonics-format command operand1 (list operand2)))
    ((and (or (string? operand1) (symbol? operand1)) (list? operand2))
     (mnemonics-format command (list operand1) operand2))
    (else (error "Could not format mnemonics." command operand1 operand2))))

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
