;; z80.ss - an emulator for the Zilog Z80
;;
;; Author: slowpoke <mail+git@slowpoke.io>
;;
;; This programm is Free Software under the non-terms
;; of the Anti-License. Do whatever the fuck you want.

;; REGISTERS
;; The Z80 has twenty-two registers, eighteen of them 8-bit, the remaining four
;; 16-bit. There are two sets of six 8-bit general-purpose registers, which can
;; be used in pairs as 16-bit registers, two sets of accumulator and flag
;; registers, and six special purpose registers.

(define-record register
;;
;; Special-purpose
;; Of the six special purpose registers, four are 16-bit, the rest is 8-bit.
;;
;; Program Counter (PC)
;; This register stores the 16-bit address of the next instruction. It
;; auto-increments after the execution of every instruction. In case of a jump,
;; the PC is set to the new address, and the autoincrement is skipped.

PC

;; Stack Pointer (SP)
;; The 16-bit address stored by in this register points to the current top of
;; the stack, which can be located anywhere in external RAM. The PUSH and POP
;; instructions manipulate this register.

SP

;; Index Registers (IX, IY)
;; Used for indexed instruction. Each of these registers can hold a 16-bit
;; address which is used as a base memory address. Indexed instructions will
;; supply an 8-bit two's compliment offset to this base.

IX IY

;; Interrupt Page Address Register (I)
;; Another indirect address register. The Z80 can be put into a mode where
;; interrupts can indirectly call any location in memory. This register stores
;; the high order byte of the address, the interrupt device the lower byte.

I

;; Memory Refresh Register (R)
;; This register allows dynamic memory to be used. Seven of the bits in this
;; register are autoincremented with every memory refresh. The eigth is set with
;; the LD R,A instruction.
;;
R

;; Accumulator/Flag Registers (A, F & A', F')
;; These registers hold the results for arithmetic operations and the conditions
;; of those operations. They can be used independently as 8-bit registers or as
;; one 16-bit register.
;; NOTE: Due to variable naming constraints in Scheme, the second pair is called
;; A- and F-, respectively.

A F A- F-

;; General Purpose Registers (BC, DE, HL & BC', DE', HL')
;; There are two sets of six 8-bit registers, whose registers may be used
;; individually as 8-bit registers, or combined as 16-bit registers. The
;; currently used set can be switched with a single instruction.
;; NOTE: As with the Accumulator and Flag registers, the naming constraints of
;; Scheme require us to name these variables with a - instead of a '.

B  C  D  E  H  L
B- C- D- E- H- L-)

;; We also want a function that creates a register object without having to
;; supply twenty-two arguments to the constructor.

(define (make-register*)
  (make-register 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
