#lang racket/base

(require scribble/manual
         racket/string
         racket/format)

(define IETF-URL
  "https://tools.ietf.org/html")

(define (ietf-rfc num)
  (link (~a IETF-URL "/rfc" num)
        (~a "RFC " num)))

(define (expand-acronym lst)
  (for/fold
      ([acronym '()]
       [lst '()]
       #:result
       (append
        `(,(bold
            (apply string (reverse acronym)))
          " (") (reverse lst) '(")")))
      ([str (in-list lst)])
    (define first-letter (string-ref str 0))
    (values
     (cons first-letter acronym)
     (append
      (list
       (substring str 1)
       (bold
        (string-upcase
         (string first-letter))))
      lst))))

(provide ietf-rfc expand-acronym)
