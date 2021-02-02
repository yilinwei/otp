#lang racket/base

(require racket/contract
         crypto)

(require "private/hotp.rkt"
         "private/totp.rkt"
         "private/error.rkt")

(define digest-spec-or-impl?
  (or/c digest-spec?
        digest-impl?))

(define otp-digits/c (between/c 4 10))

(define (default/c value default)
  (if (unsupplied-arg? value)
      default
      value))

(define (string-len=/c n)
  (flat-named-contract
   `(string-len=/c ,n)
   (λ (%)
     (and (string? %)
          (eq?
           (string-length %)
           n)))))

(provide
 (struct-out exn:fail:otp:checksum)
 (contract-out
  [hotp-valid?
   (->*
    (bytes?
     exact-integer?
     string?)
    (#:mode digest-spec-or-impl?
     #:digits otp-digits/c
     #:checksum? boolean?
     #:truncation-offset (or/c #f (</c 16)))
    boolean?)]
  [generate-totp
   (->i
    ([secret bytes?])
    (#:mode [mode digest-spec-or-impl?]
     #:time [t exact-integer?]
     #:time-start [t₀ exact-positive-integer?]
     #:time-step [Δt exact-positive-integer?]
     #:digits [digits otp-digits/c])
    [otp (digits)
         (string-len=/c
          (default/c digits 8))])]
  [generate-hotp
   (->i
    ([secret bytes?]
     [moving-factor exact-integer?])
    (#:mode [mode digest-spec-or-impl?]
     #:digits [digits otp-digits/c]
     #:checksum? [checksum? boolean?]
     #:truncation-offset [truncation-offset (or/c #f (</c 16))])
    [otp (digits checksum?)
         (let
             ([digits* (default/c digits 6)]
              [checksum?* (default/c checksum? #f)])
           (string-len=/c
            (if checksum?* (add1 digits*) digits*)))])]))
