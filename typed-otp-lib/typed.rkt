#lang typed/racket/base

(require/typed/provide crypto
  [#:opaque Digest-Spec digest-spec?]
  [#:opaque Digest-Impl digest-impl?])

(define-type Digest-Spec-Or-Impl (U Digest-Spec Digest-Impl))
(define-type Otp-Digits (Refine [n : Integer] (< 4 n 10)))
(define-type Truncation-Offset (Refine [n : Integer] (< n 16)))

(provide Digest-Spec-Or-Impl
         Otp-Digits
         Truncation-Offset)

(require/typed/provide "private/error.rkt"
  [#:struct (exn:fail:otp:checksum exn:fail) ()])

(require/typed/provide "private/hotp.rkt"
  [generate-hotp (-> Bytes
                     Integer
                     [#:mode Digest-Spec-Or-Impl]
                     [#:digits Otp-Digits]
                     [#:checksum? Boolean]
                     ;; TODO: Refinement once possible
                     String)]
  [hotp-valid? (-> Bytes
                   Integer
                   String
                   [#:mode Digest-Spec-Or-Impl]
                   [#:checksum? Boolean]
                   [#:truncation-offset (U False Truncation-Offset)]
                   Boolean)])

(require/typed/provide "private/totp.rkt"
  [generate-totp (-> Bytes
                     [#:mode Digest-Spec-Or-Impl]
                     [#:time Integer]
                     [#:time-start Exact-Positive-Integer]
                     [#:time-step Exact-Positive-Integer]
                     [#:digits Otp-Digits]
                     [#:checksum? Boolean]
                     ;; TODO: Refinement once possible
                     String)]
  [totp-valid? (-> Bytes
                   String
                   [#:mode Digest-Spec-Or-Impl]
                   [#:time (U Integer (-> Integer))]
                   [#:time-start Exact-Nonnegative-Integer]
                   [#:checksum? Boolean]
                   [#:max-drift Exact-Nonnegative-Integer]
                   Boolean)])

(module+ test
  (require typed/rackunit)

  (define secret (integer->integer-bytes
                  (random (expt 2 8)) 8 #f))
  (define moving-factor 0)

  (check-true
   (hotp-valid? secret moving-factor
                (generate-hotp secret moving-factor)))

  (define time (current-seconds))
  (check-true
   (totp-valid? secret #:time time
                (generate-totp secret #:time time))))
