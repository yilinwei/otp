#lang racket/base

(struct exn:fail:otp:checksum exn:fail ()
  #:transparent)

(provide
 (struct-out exn:fail:otp:checksum))
