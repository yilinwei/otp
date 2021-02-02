#lang racket/base

(require rackunit
         racket/match
         crypto
         crypto/libcrypto
         otp)

(define sha1 (get-digest 'sha1 libcrypto-factory))
(define sha256 (get-digest 'sha256 libcrypto-factory))
(define sha512 (get-digest 'sha512 libcrypto-factory))
(define sha1-secret (string->bytes/utf-8 "12345678901234567890"))

(define-check (check-totp mode secret lst)
  (for
      ([test (in-list lst)])
    (match-define (list time otp) test)
    (define code
      (generate-totp secret #:time time #:mode mode))
    (check-equal? code otp)
    (check-true (totp-valid? secret
                             code
                             #:time time
                             #:mode mode
                             #:max-drift 0))))

(define-check (check-hotp mode lst)
  (define secret
    (string->bytes/utf-8 "12345678901234567890"))
  (for
      ([expected (in-list lst)]
       [count (in-naturals)])
    (define code
      (generate-hotp secret count #:mode mode))
    (check-equal? code expected)
    (check-true (hotp-valid? secret count code #:mode mode))))

(test-begin
  (define count 0)
  (define code
    (generate-hotp
     sha1-secret
     count
     #:checksum? #t))
  (check-true (hotp-valid? sha1-secret count code #:checksum? #t))
  (check-exn exn:fail:otp:checksum?
             (λ () (hotp-valid? sha1-secret count "01231904" #:checksum? #t))))

(test-begin
  (define code (generate-totp sha1-secret #:time 119))
  (check-true (totp-valid? sha1-secret code #:time 59 #:max-drift 2))
  (check-false (totp-valid? sha1-secret code #:time 59 #:max-drift 1)))

(test-begin
  (define time 119)
  (check-true
   (totp-valid?
    sha1-secret
    (generate-totp sha1-secret
                   #:time time #:checksum? #t)
    #:time time
    #:checksum? #t)))

(check-totp
 sha1
 sha1-secret
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
