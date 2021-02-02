#lang racket/base

(define double-digits-table
  (vector-immutable
   0 2 4 6 8 1 3 5 7 9))

(define (double-digits->value digit)
  (vector-ref double-digits-table digit))

(define (digits n)
  (add1 (ceiling (log n 10))))

(define (modulo/10 num)
  (modulo num 10))

(define (luhn-sum num digits)
  (for/fold
      ([num num]
       [total 0]
       [even-digit? #t]
       #:result total)
      ([_ (in-range 0 digits)])
    (define digit (modulo/10 num))
    (values
     (floor (/ num 10))
     (+ total
        (if even-digit?
            (double-digits->value digit)
            digit))
     (not even-digit?))))

;; Credit card checksum algorithm from RFC 4226
(define (luhn-checksum num
                       [digits
                        (digits num)])
  (define sum
    (modulo
     (luhn-sum num digits) 10))
  (if (< 0 sum)
      (- 10 sum)
      sum))

(define (luhn-checksum-valid? num
                              checksum
                              [digits
                               (digits num)])
  (define sum (+
               (luhn-sum num digits)
               checksum))
  (zero? (modulo/10 sum)))

(provide luhn-checksum
         luhn-checksum-valid?)

(module+ test
  
  (require rackunit
           racket/match)

  (for
      ([test (in-list '([7992739871 3]))])
    (match-define (list num checksum) test)
    (check-equal? (luhn-checksum num) checksum)
    (check-true (luhn-checksum-valid? num checksum))
    (check-false (luhn-checksum-valid? num
                                       (modulo/10 (add1 checksum))))))
