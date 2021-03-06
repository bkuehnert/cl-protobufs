;;; Copyright 2012-2020 Google LLC
;;;
;;; Use of this source code is governed by an MIT-style
;;; license that can be found in the LICENSE file or at
;;; https://opensource.org/licenses/MIT.

(in-package #:cl-protobufs.implementation)

(defun object-initialized-p (object message)
  "Check if OBJECT with proto-message MESSAGE is initialized.
The definition of initialized is all required-fields are set."
  (loop for field in (proto-fields message)
        when (eq (proto-label field) :required)
          do (when (= (bit (slot-value object '%%is-set)
                           (proto-field-offset field))
                      0)
               (return-from object-initialized-p nil))
        when (and (member (proto-kind field) '(:message :group :extends))
                  (or (eq (proto-label field) :repeated)
                      (= (bit (slot-value object '%%is-set)
                              (proto-field-offset field))
                         1)))
          do (let ((lisp-type (proto-class field))
                   (field-value (slot-value object (proto-internal-field-name field))))
               (when (and (not (keywordp lisp-type))
                          (find-message-descriptor lisp-type))
                 (doseq (msg (if (eq (proto-label field) :repeated)
                                 field-value
                                 (list field-value)))
                   (unless (object-initialized-p msg (find-message-descriptor lisp-type))
                     (return-from object-initialized-p nil))))))
  t)

(defun is-initialized (object)
  "Returns true if all of the fields of OBJECT are initialized."
  (let* ((class   (type-of object))
         (message (find-message-descriptor class :error-p t)))
    (object-initialized-p object message)))

(defun scalar-field-equal (object-1 object-2)
  "Check if two objects with scalar type are equal.
Parameters:
  OBJECT-1: The first scalar object.
  OBJECT-2: The second scalar object."
  (typecase object-1
    (string (string= object-1 object-2))
    (t (equalp object-1 object-2))))

(defun proto-equal (message-1 message-2 &key (exact nil))
  "Check if two protobuf messages are equal. By default
two messages are equal if calling the getter on each
field would retrieve the same value. This means that a
message with a field explicitly set to the default value
is considered the same as a message with that field not
set.

Parameters:
  MESSAGE-1: The first protobuf message.
  MESSAGE-2: The second protobuf message.
  EXACT: If true Consider the messages to be equal
only if the same fields have been explicitly set."
  (let* ((class-1 (type-of message-1))
         (message (find-message-descriptor class-1)))
    (unless (and message (eq (type-of message-2) class-1))
      (return-from proto-equal nil))

    (when (and exact
               (not (equalp (slot-value message-1 '%%is-set)
                            (slot-value message-2 '%%is-set))))
      (return-from proto-equal nil))

    ;; Bool values are stored in a vector.
    (when (and (slot-exists-p message-1 '%%bool-values)
               (not (equalp (slot-value message-1 '%%bool-values)
                            (slot-value message-2 '%%bool-values))))
      (return-from proto-equal nil))

    (loop for oneof in (proto-oneofs message)
          for slot-value-1
            = (slot-value message-1 (oneof-descriptor-internal-name oneof))
          for slot-value-2
            = (slot-value message-2 (oneof-descriptor-internal-name oneof))
          for set-field-1
            = (oneof-set-field slot-value-1)
          for set-field-2
            = (oneof-set-field slot-value-2)
          for lisp-type
            = (when set-field-1 (proto-class
                                 (aref (oneof-descriptor-fields oneof)
                                       set-field-1)))
          unless (and set-field-1 set-field-2)
            do (when (or set-field-1 set-field-2)
                 (return-from proto-equal nil))
          unless (equal (oneof-set-field slot-value-1)
                        (oneof-set-field slot-value-2))
            do (return-from proto-equal nil)
          when (or (scalarp lisp-type) (find-enum-descriptor lisp-type))
            do (unless (scalar-field-equal (oneof-value slot-value-1)
                                           (oneof-value slot-value-2))
                 (return-from proto-equal nil))
          when (find-message-descriptor lisp-type)
            do (unless (proto-equal (oneof-value slot-value-1)
                                    (oneof-value slot-value-2)
                                    :exact exact)
                 (return-from proto-equal nil)))

    (loop for field in (proto-fields message)
          for lisp-type = (proto-class field)
          for slot-value-1
            = (unless (eq lisp-type 'boolean)
                (slot-value message-1 (proto-internal-field-name field)))
          for slot-value-2
            = (when slot-value-1
                (slot-value message-2 (proto-internal-field-name field)))
          when (and (not (eq lisp-type 'boolean))
                    (or (scalarp lisp-type) (find-enum-descriptor lisp-type)))
            do (unless (scalar-field-equal slot-value-1 slot-value-2)
                 (return-from proto-equal nil))
          unless (and slot-value-1 slot-value-2)
            do (when (or slot-value-1 slot-value-2)
                 (return-from proto-equal nil))
          when (and slot-value-1 (eq (proto-label field) :repeated))
            do (unless (= (length slot-value-1) (length slot-value-2))
                 (return-from proto-equal nil))
          when (and slot-value-1 (find-message-descriptor lisp-type))
            do (loop for x in
                           (if (eq (proto-label field) :repeated)
                               slot-value-1
                               (list slot-value-1))
                     for y in
                           (if (eq (proto-label field) :repeated)
                               slot-value-2
                               (list slot-value-2))
                     do (unless (and x y (proto-equal x y :exact exact))
                          (return-from proto-equal nil))))
    t))

(defgeneric clear (object)
  (:documentation
   "Initialize all of the fields of 'object' to their default values."))

(defun-inline has-field (object field)
  "Check if OBJECT has FIELD set."
  (funcall (field-accessors-has (get field (type-of object)))
           object))

(defun-inline clear-field (object field)
  "Check if OBJECT has FIELD set."
  (funcall (field-accessors-clear (get field (type-of object)))
           object))

(defun-inline proto-slot-value (object slot)
  "Get the value of a field in a protobuf object.
Parameters:
  OBJECT: The protobuf object.
  SLOT: The slot in object to retrieve the value from."
  (funcall (field-accessors-get (get slot (type-of object)))
           object))

(defun-inline (setf proto-slot-value) (value object slot)
    "Set the value of a field in a protobuf object.
Parameters:
  VALUE: The new value for the field.
  OBJECT: The protobuf object.
  SLOT: The slot in object to retrieve the value from."
  (funcall (fdefinition (field-accessors-set (get slot (type-of object))))
           value
           object))

(defgeneric encoded-field (object slot)
  (:documentation
   "Returns the encoded value of the field 'slot', or NIL if does not exist.
For repeated fields, returns a list of the encoded values, which may be NILs.")
  (:method ((object structure-object) slot)
    (let* ((class (type-of object))
           (message (find-message-descriptor class :error-p t))
           (field (find slot (proto-fields message) :key #'proto-external-field-name)))
      (unless field
        (let* ((lisp-package (or (symbol-package class)
                                 (protobuf-error "Lisp package not found for message ~A"
                                                 (proto-name message))))
               (lazy-slot (intern (nstring-upcase (format nil "%~A" slot))
                                  lisp-package)))
          (setf field (find-field-descriptor message lazy-slot))
          (when field
            (setf slot lazy-slot))))
      (unless field
        (protobuf-error "There is no protobuf field with the name ~S" slot))
      (let ((value (slot-value object (proto-internal-field-name field))))
        (if (eq (proto-label field) :repeated)
            (map 'list #'proto-%bytes value)
            (proto-%bytes value))))))
