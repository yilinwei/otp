#lang racket/base

(require racket/contract
         crypto)

(require "private/hotp.rkt"
         "private/totp.rkt")

(define digest-spec-or-impl?
  (or/c digest-spec?
        digest-impl?))

(define otp-digits/c (between/c 4 10))

(provide
 (contract-out
  [generate-totp
   (->i
    ([secret bytes?])
    (#:mode [mode digest-spec-or-impl?]
     #:time [t exact-integer?]
     #:time-start [t₀ exact-positive-integer?]
     #:time-step [Δt exact-positive-integer?]
     #:digits [digits otp-digits/c])
    [otp (digits) (string-len/c digits)])]
  [generate-hotp
   (->i
    ([secret bytes?]
     [moving-factor exact-integer?])
    (#:mode [mode digest-spec-or-impl?]
     #:digits [digits otp-digits/c]
     #:checksum? [checksum? boolean?]
     #:truncation-offset [truncation-offset (or/c #f (</c 16))])
    [otp (digits checksum?) (string-len/c
                             (if checksum?
                                 (add1 digits)
                                 digits))])]))

(module+ test

  (require rackunit
           racket/match
           crypto
           crypto/libcrypto)

  (define sha256 (get-digest 'sha256 libcrypto-factory))
  (define sha512 (get-digest 'sha512 libcrypto-factory))

  (define-check (check-totp mode secret lst)
    (for
        ([test (in-list lst)])
      (match-define (list time otp) test)
      (check-equal?
       (generate-totp secret #:time time #:mode mode)
       otp)))

  (define-check (check-hotp mode lst)
    (define secret
      (string->bytes/utf-8 "12345678901234567890"))
    (for
        ([expected (in-list lst)]
         [count (in-naturals)])
      (check-equal?
       (generate-hotp secret count #:mode mode)
       expected)))

  (check-totp
   sha1
   (string->bytes/utf-8 "12345678901234567890")
   '((59 "94287082")
     (1111111109 "07081804")
     (1111111111 "14050471")
     (1234567890 "89005924")
     (2000000000 "69279037")
     (20000000000 "65353130")))

  (check-totp
   sha256
   (string->bytes/utf-8
    "12345678901234567890123456789012")
   '((59 "46119246")
     (1111111109 "68084774")
     (1111111111 "67062674")
     (1234567890 "91819424")
     (2000000000 "90698825")
     (20000000000 "77737706")))

  (check-totp
   sha512
   (string->bytes/utf-8
    "1234567890123456789012345678901234567890123456789012345678901234")
   '((59 "90693936")
     (1111111109 "25091201")
     (1111111111 "99943326")
     (1234567890 "93441116")
     (2000000000 "38618901")
     (20000000000 "47863826")))

  (check-hotp
   sha1
   '("755224"
     "287082"
     "359152"
     "969429"
     "338314"
     "254676"
     "287922"
     "162583"
     "399871"
     "520489"))

  (check-hotp
   sha256
   '("875740"
     "247374"
     "254785"
     "496144"
     "480556"
     "697997"
     "191609"
     "579288"
     "895912"
     "184989"))

  (check-hotp
   sha512
   '("125165"
     "342147"
     "730102"
     "778726"
     "937510"
     "848329"
     "266680"
     "588359"
     "039399"
     "643409"))
  )
