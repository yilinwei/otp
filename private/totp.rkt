#lang racket/base

(require "hotp.rkt")

;; Implementation taken from RFC 6238
(define (generate-totp secret
              #:mode [mode sha1]
              #:time [t (current-seconds)]
              #:time-start [t₀ 0]
              #:time-step [Δt 30]
              #:digits [digits 8])
  (define moving-factor
    (floor (/ (- t t₀)
              Δt)))

  (generate-hotp secret
       moving-factor
       #:mode mode
       #:digits digits))

(provide generate-totp)
