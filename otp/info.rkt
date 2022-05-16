#lang info

(define version "0.1")
(define collection "otp")
(define deps '("crypto-lib"
               "rackunit-lib"
               "base" "otp-lib" "typed-otp-lib" "otp-doc"))
(define implies '("otp-lib" "typed-otp-lib" "otp-doc"))
(define name "otp")
