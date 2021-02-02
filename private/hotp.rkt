#lang racket/base

(require crypto
         crypto/libcrypto
         racket/format)

(define sha1
  (get-digest 'sha1 libcrypto-factory))

(define double-digits-table
  (vector-immutable
   0 2 4 6 8 1 3 5 7 9))

(define (double-digits->value digit)
  (vector-ref double-digits-table digit))

;; Credit card checksum algorithm from RFC 4226
(define (luhn-checksum num
                       [digits
                        (add1 (ceiling (log num 10)))])
  (define result
    (for/fold
        ([num num]
         [total 0]
         [even-digit? #t]
         #:result
         (modulo total 10))
        ([_ (in-range 0 digits)])
      (define digit (modulo num 10))
      (values
       (floor (/ num 10))
       (+ total
          (if even-digit?
              (double-digits->value digit)
              digit))
       (not even-digit?))))
  (if (< 0 result)
      (- 10 result)
      result))

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
       (* 10 code (luhn-checksum generate-hotp digits))
       code)
   #:width (if checksum? (add1 digits) digits)
   #:align 'right
   #:left-pad-string "0"))

(provide generate-hotp sha1)

(module+ test

  (require rackunit)


  (define sha256 (get-digest 'sha256 libcrypto-factory))
  (define sha512 (get-digest 'sha512 libcrypto-factory))

  (check-equal?
   (luhn-checksum 7992739871) 3)

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
