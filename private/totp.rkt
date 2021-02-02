#lang racket/base

(require "hotp.rkt")

;; Implementation taken from RFC 6238
(define (generate-totp secret
              #:mode [mode sha1]
              #:time [time (current-seconds)]
              #:time-start [time-start 0]
              #:time-step [time-step 30]
              #:digits [digits 8])
  (define t (floor (/ (- time time-start)
                      time-step)))

  (generate-hotp secret
       t
       #:mode mode
       #:digits digits))

(provide generate-totp)
