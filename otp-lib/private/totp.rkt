#lang racket/base

(require "hotp.rkt"
         "utils.rkt")

(define (clamp t t₀ Δt)
  (floor (/ (- t t₀) Δt)))

;; Implementation taken from RFC 6238
(define (generate-totp secret
                       #:mode [mode sha1]
                       #:time [t (current-seconds)]
                       #:time-start [t₀ 0]
                       #:time-step [Δt 30]
                       #:digits [digits 8]
                       #:checksum? [checksum? #f])
  (define moving-factor (clamp t t₀ Δt))
  (generate-hotp secret
                 moving-factor
                 #:mode mode
                 #:digits digits
                 #:checksum? checksum?))

(define (totp-valid? secret
                     code
                     #:time [time current-seconds] ; Lazy, because it’s quite expensive
                     #:mode [mode sha1]
                     #:time-start [t₀ 0]
                     #:time-step [δt 30]
                     #:digits [digits 8]
                     #:checksum? [checksum? #f]
                     #:max-drift [max-drift 1]) ; Measured in units of Δt
  (define code* (checked-code code checksum?))
  (define t (if (exact-integer? time)
                time
                (time)))
  (define (valid? t)
    (hotp-valid? secret
                 (clamp t t₀ δt)
                 code*
                 #:mode mode
                 #:digits digits
                 ;; Checked earlier, no need to do it again
                 #:checksum? #f))
  (for/or
      ([i (in-range 0 (add1 max-drift))])
    (cond
      [(zero? i) (valid? t)]
      [else
       (define Δt (* i δt))
       (or
        (valid? (+ t Δt))
        (valid? (- t Δt)))])))

(provide generate-totp totp-valid?)
