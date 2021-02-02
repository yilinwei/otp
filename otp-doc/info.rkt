#lang info

(define version "0.1")
(define collection "otp")
(define deps '("base"))
(define build-deps
  '("racket-doc"
    "scribble-lib"
    "otp-lib"
    "crypto-lib"
    "crypto-doc"))

(define name "otp")
(define scribblings '(("scribblings/otp.scribl")))
