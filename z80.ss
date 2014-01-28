;; z80.ss - an emulator for the Zilog Z80
;;
;; Author: slowpoke <mail+git@slowpoke.io>
;;
;; This programm is Free Software under the non-terms
;; of the Anti-License. Do whatever the fuck you want.

(load "z80-memory.ss")
(load "z80-registers.ss")

;; We define our emulator as a record which holds the entire internal state of
;; the Z80. For now, this only includes the registers, but there is more
;; internal state which will be added later (TODO).

(define-record z80 registers )

;; We need a way to reset the Z80 to its initial state. On the actual hardware,
;; this is done by the RESET pin, which does the following things:
;;  - set the PC register to 0000h.
;;  - enable interrupt mode 0.
;;  - disable interrupts.
;;  - set register I to 00h.
;;  - set register R to 00h.
;;
;; It would then execute the instruction at 0000h.

(define (z80:reset cpu)
  (let ((reg (z80-registers cpu)))
    (register-PC-set! reg 0)
    ;; TODO: interrupts
    (register-I-set! reg 0)
    (register-R-set! reg 0)))

;; The actual emulation is a loop (implemented as a infinite tail-recursive
;; function) which reads an opcode from memory, then dispatches it to the
;; appropriate handler function. It expects to be handed a Z80 CPU as well as a
;; chunk of memory.
;;
;; Right now, this emulation does not count cycles, neither machine nor clock
;; ones. This is obviously not correct, but will be added later (TODO).

(define (z80:begin-emulation CPU RAM)
  (define (loop)
    (let ((reg (z80-registers CPU)))
      (let ((instruction-addr (register-PC reg)))
        (register-PC-set! reg (+ instruction-addr 1))
        (let ((opcode (char->integer
                        (memory-read RAM
                                     instruction-addr))))
          (print "opcode: " opcode)
          (print "pc: " instruction-addr)
          (loop)))))
  (loop))
