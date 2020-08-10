;;; Copyright 2012-2020 Google LLC
;;;
;;; Use of this source code is governed by an MIT-style
;;; license that can be found in the LICENSE file or at
;;; https://opensource.org/licenses/MIT.

(defpackage #:cl-protobufs.test.zigzag
  (:use #:cl
        #:clunit
        #:cl-protobufs
        #:alexandria
        #:cl-protobufs.zigzag-test)
  (:export :run))

(in-package #:cl-protobufs.test.zigzag)

(defsuite zigzag-suite (cl-protobufs.test:root-suite))

(defun run ()
  "Run all tests in the test suite."
  (cl-protobufs.test:run-suite 'zigzag-suite))

(defun expect-bytes (list array)
  (assert-true (equal (coerce list 'list) (coerce array 'list))))

(defconstant +TAG-S+ (proto-impl::make-tag 'proto:int32 1))
(defconstant +TAG-U+ (proto-impl::make-tag 'proto:int32 2))
(defconstant +TAG-I+ (proto-impl::make-tag 'proto:int32 3))


(define-constant +equal-loop-list+ '(cl-protobufs.zigzag-test::%s
                                     cl-protobufs.zigzag-test::%u
                                     cl-protobufs.zigzag-test::%i)
  :test #'equal
  :documentation "Fields to iterate over.")

(defun msg-equalp (x y)
  (loop for slot in +equal-loop-list+
        always (eql (slot-value x slot)
                    (slot-value y slot))))

(defun expect-same (msg)
  (assert-true (msg-equalp msg (proto:deserialize-object-from-bytes
                                'msg (proto:serialize-object-to-bytes msg)))))

(deftest unsigned-positive (zigzag-suite)
  ;; Small encoding for positive numbers
  (let ((msg (make-msg :u 10)))
    (expect-bytes (list +TAG-U+ 10) (proto:serialize-object-to-bytes msg))
    (expect-same msg)))

;; There is no applicable method for the generic function
;; #<STANDARD-GENERIC-FUNCTION SB-MOP:SLOT-DEFINITION-TYPE (1)>
;; with defstruct protobufs.
(deftest unsigned-negative (zigzag-suite)
  ;; Verify that the generated class has the correct type declaration
  (let ((class (find-class 'msg)))
    (unless (closer-mop:class-finalized-p class)
      (closer-mop:finalize-inheritance class))
    (let* ((slot
             (find 'cl-protobufs.zigzag-test::%u (closer-mop:class-slots class)
                   :key 'closer-mop:slot-definition-name))
           (type (closer-mop:slot-definition-type slot)))
      #+sbcl ;; In non sbcl the int-name may differ
      (assert-true (eq type 'uint64))
      (assert-true (not (typep -10 type)))
      (assert-true (typep 10 type)))))

(deftest signed-positive (zigzag-suite)
  ;; Small encoding for positive numbers
  (let ((msg (make-msg :s 10)))
    (expect-bytes (list +TAG-S+ (ash 10 1)) (proto:serialize-object-to-bytes msg))
    (expect-same msg)))

(deftest signed-negative (zigzag-suite)
  (let ((msg (make-msg :s -10)))
    ;; Small encoding for negative numbers
    (expect-bytes (list +TAG-S+ (1- (ash 10 1)))
                  (proto:serialize-object-to-bytes msg))
    (expect-same msg)))

(deftest unspecified-positive (zigzag-suite)
  ;; Small encoding for positive numbers
  (let ((msg (make-msg :i 10)))
    (expect-bytes (list +TAG-I+ 10) (proto:serialize-object-to-bytes msg))
    (expect-same msg)))

(deftest unspecified-negative (zigzag-suite)
  (let ((msg (make-msg :i -10)))
    ;; Large encoding for negative numbers
    (expect-bytes (list +TAG-I+ 246 255 255 255 255 255 255 255 255 1)
                  (proto:serialize-object-to-bytes msg))
    (expect-same msg)))
