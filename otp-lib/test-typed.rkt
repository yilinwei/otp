#lang typed/racket

(require rackunit
         "typed.rkt")


(define secret (integer->integer-bytes
                  (random (expt 2 20)) 8 #t))
(define moving-factor 0)
(check-true
 (hotp-valid?
  secret
  moving-factor
  (generate-hotp secret moving-factor)))
