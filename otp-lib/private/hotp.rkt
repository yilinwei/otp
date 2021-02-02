#lang racket/base

(require crypto
         crypto/libcrypto
         racket/format
         "utils.rkt"
         "checksum.rkt")

(define sha1
  (get-digest 'sha1 libcrypto-factory))

(define (otp/hash secret moving-factor mode)
  (define bstr
    (integer->integer-bytes
     moving-factor 8 #f #t))
  (hmac mode secret bstr))

(define digits-table
  (for/vector
      ([i (in-range 4 11)])
    (expt 10 i)))

(define (digits->modulus digits)
  (vector-ref digits-table (- digits 4)))

;; Implementation directly taken from RFC 4226
(define (generate-hotp secret
                       moving-factor
                       #:mode [mode sha1]
                       #:digits [digits 6]
                       #:checksum? [checksum? #f]
                       #:truncation-offset [truncation-offset #f])
  (define hash (otp/hash secret moving-factor mode))
  (define offset
    (or truncation-offset
        (bitwise-and
         (bytes-ref hash
                    (sub1 (bytes-length hash)))
         #xf)))
  (make-bytes 4)
  (define bstr (subbytes hash offset (+ 4 offset)))
  (bytes-set! bstr
              0
              (bitwise-and
               (bytes-ref bstr 0)
               #x7f))
  (define i
    (integer-bytes->integer bstr #t #t))
  (define code (modulo i (digits->modulus digits)))
  (~a
   (if checksum?
       (+ (* 10 code) (luhn-checksum code digits))
       code)
   #:width (if checksum? (add1 digits) digits)
   #:align 'right
   #:left-pad-string "0"))

(define (hotp-valid? secret
                     moving-factor
                     code
                     #:mode [mode sha1]
                     #:digits [digits 6]
                     #:checksum? [checksum? #f]
                     #:truncation-offset [truncation-offset #f])
  (define expected (checked-code code checksum?))
  (equal?
   (generate-hotp secret
                  moving-factor
                  #:mode mode
                  #:digits digits
                  #:checksum? #f
                  #:truncation-offset truncation-offset)
   expected))

(provide generate-hotp hotp-valid? sha1)

(module+ test

  (require rackunit)

  (define secret
    (string->bytes/utf-8 "12345678901234567890"))

  ;; Test-vectors taken directly from RFC 4225
  (for
      ([expected-hash (in-list
                       '("cc93cf18508d94934c64b65d8ba7667fb7cde4b0"
                         "75a48a19d4cbe100644e8ac1397eea747a2d33ab"
                         "0bacb7fa082fef30782211938bc1c5e70416ff44"
                         "66c28227d03a2d5529262ff016a1e6ef76557ece"
                         "a904c900a64b35909874b33e61c5938a8e15ed1c"
                         "a37e783d7b7233c083d4f62926c7a25f238d0316"
                         "bc9cd28561042c83f219324d3c607256c03272ae"
                         "a4fb960c0bc06e1eabb804e5b397cdc4b45596fa"
                         "1b3c89f65e6c9e883012052823443f048b4332db"
                         "1637409809a679dc698207310c8c7fc07290d9e5"))]
       [count (in-naturals)])
    (check-equal? expected-hash
                  (bytes->hex-string
                   (otp/hash secret
                             count
                             sha1)))))
