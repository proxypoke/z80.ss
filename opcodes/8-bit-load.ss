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
  (let ((make-ld
          (lambda (prefix r1 r2 m t command #!optional op1 op2)
            (let ((opcode-list (opcode-format-8-bit prefix r1 r2))
                  (mnemonic-list (mnemonics-format command op1 op2)))
              (let ((len (length opcode-list)))
                (for-each add
                          opcode-list
                          (make-list len m)
                          (make-list len t)
                          mnemonic-list))))))

    ;; LD r,r'

    (make-ld #b01 register-values register-values
             1 4 "LD" register-names register-names)

    ;; LD r,n

    (make-ld #b00 register-values #b110
             2 7 "LD" register-names "n")

    ;; LD r,(HL)

    (make-ld #b01 register-values #b110
             2 7 "LD" register-names "(HL)")

    ;; LD r,(IX+d)
    ;; TODO (16-bit opcode)

    ;; LD r,(IY+d)
    ;; TODO (16-bit opcode)

    ;; LD (HL),r

    (make-ld #b01 #b110 register-values
             2 7 "LD" "(HL)" register-names)

    ;; LD (IX+d),r
    ;; TODO (16-bit opcode)

    ;; LD (IY+d),r
    ;; TODO (16-bit opcode)

    ;; LD (HL),n
    (make-ld #b00 #b110 #b110
             3 10 "LD" "(HL)" "n")

    ;; LD (IX+d),n
    ;; TODO (16-bit opcode)

    ;; LD (IY+d),n
    ;; TODO (16-bit opcode)

    ;; LD A,(BC)
    (make-ld #b00 #b001 #b010
             2 7 "LD" "A" "(BC)")

    ;; LD A,(DE)
    (make-ld #b00 #b011 #b010
             2 7 "LD" "A" "(DE)")

    ;; LD A,(nn)
    (make-ld #b00 #b111 #b010
             4 13 "LD" "A" "(nn)")

    ;; LD (BC),A
    (make-ld #b00 #b000 #b010
             2 7 "LD" "(BC)" "A")

    ;; LD (DE),A
    (make-ld #b00 #b010 #b010
             2 7 "LD" "(DE)" "A")

    ;; LD (nn),A

    (make-ld #b00 #b110 #b010
             4 13 "LD" "(nn)" "A")))

    ;; LD A,I
    ;; TODO (16-bit opcode)

    ;; LD A,R
    ;; TODO (16-bit opcode)

    ;; LD I,A
    ;; TODO (16-bit opcode)

    ;; LD R,A
    ;; TODO (16-bit opcode)
