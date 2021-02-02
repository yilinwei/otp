#lang racket/base

(require "checksum.rkt"
         "error.rkt"
         racket/format)

(define (checked-code code checksum?)
  (cond
    [checksum?
     (define len* (sub1 (string-length code)))
     (define checksum (- (char->integer (string-ref code len*))
                         (char->integer #\0)))
     (define code* (substring code 0 len*))
     (unless (luhn-checksum-valid? checksum
                                   (string->number code*)
                                   (add1 len*))
       (raise
        (exn:fail:otp:checksum
         (~a code " has incorrect checksum")
         (current-continuation-marks))))
     code*]
    [else code]))

(provide checked-code)
