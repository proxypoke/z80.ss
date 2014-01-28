;; z80.ss - an emulator for the Zilog Z80
;;
;; Author: slowpoke <mail+git@slowpoke.io>
;;
;; This programm is Free Software under the non-terms
;; of the Anti-License. Do whatever the fuck you want.

(load "constants.ss")

;; The Z80 can address a maximum of 64 KiB of memory (2^16).

(define max-memory-size (* 64 KiB))

;; First of all, we need a way to create a chunk of random access memory. This
;; will return a vector of the given size (if it's not larger than the maximum
;; memory size), initialized to null bytes.

(define (make-memory size)
  (if (> size max-memory-size)
    (error "Memory size too large." size)
    (make-vector size #\nul)))

;; We must be able to read from our RAM, obviously.

(define (memory-read mem addr) (vector-ref mem addr))

;; And, equally as important, write to it.

(define (memory-write! mem addr val) (set! (vector-ref mem addr) val))

;; It might also be of interest to know how large a chunk of memory is.

(define (memory-size mem) (vector-length mem))

;; We also need a convenient way to load files into memory at specific
;; locations. For this, we define a procedure that reads a given file, and
;; writes it into the provided memory at the specified address. It will return
;; the number of bytes written.

(define (memory-load! mem filename addr)
  (let ((file (open-input-file filename)))
    (define (loop current-addr)
      (let ((char (read-char file)))
        (if (eof-object? char)
            (- current-addr addr)
          (begin
            (memory-write! mem current-addr char)
            (loop (+ current-addr 1))))))
      (loop addr)))
