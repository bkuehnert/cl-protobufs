;;; Copyright 2012-2020 Google LLC
;;;
;;; Use of this source code is governed by an MIT-style
;;; license that can be found in the LICENSE file or at
;;; https://opensource.org/licenses/MIT.

(in-package :asdf)

(asdf:defsystem :cl-protobufs
  :name "CL Protobufs"
  :author "Scott McKay"
  :version "2.0"
  :licence "MIT-style"
  :maintainer '("Jon Godbout" "Carl Gay")
  :description      "Protobufs for Common Lisp"
  :long-description "Protobufs for Common Lisp"
  ;; For SBCL we'll use its builtin UTF8 encoder/decoder.
  :depends-on (:closer-mop #-sbcl :babel :trivial-garbage)
  :serial t
  :in-order-to ((asdf:test-op (asdf:test-op :cl-protobufs-tests)))
  :components
  ((:module "packages"
    :serial t
    :pathname ""
    :components
    ((:file "pkgdcl")))
   (:module "models"
    :serial t
    :pathname ""
    :depends-on ("packages")
    :components
    ((:file "utilities")
     #-sbcl (:file "float-bits")
     (:file "model-classes")
     (:file "conditions")))
   (:module "parsing"
    :serial t
    :pathname ""
    :depends-on ("models")
    :components
    ((:file "parser")))
   (:module "schema"
    :serial t
    :pathname ""
    :depends-on ("models")
    :components
    ((:file "define-proto")
     (:file "clos-transform")))
   (:module "serialization"
    :serial t
    :pathname ""
    :depends-on ("models")
    :components
    ((:file "buffers")
     (:file "text-format")
     (:file "wire-format")
     (:file "serialize")))
   (:module "misc"
    :serial t
    :pathname ""
    :depends-on ("models" "parsing" "schema" "serialization")
    :components
    ((:file "api")
     (:file "asdf-support")
     (:file "process-imports")))
   (:module "well-known-types"
    :serial t
    :pathname ""
    :depends-on ("misc" "models")
    :components
    ((:protobuf-source-file "any"
      :proto-pathname "google/protobuf/any.proto")
     (:protobuf-source-file "source_context"
      :proto-pathname "google/protobuf/source_context.proto")
     (:protobuf-source-file "type"
      :proto-pathname "google/protobuf/type.proto"
      :proto-search-path ("google/protobuf/"))
     (:protobuf-source-file "api"
      :proto-pathname "google/protobuf/api.proto"
      :proto-search-path ("google/protobuf/"))
     (:protobuf-source-file "duration"
      :proto-pathname "google/protobuf/duration.proto")
     (:protobuf-source-file "empty"
      :proto-pathname "google/protobuf/empty.proto")
     (:protobuf-source-file "field_mask"
      :proto-pathname "google/protobuf/field_mask.proto")
     (:protobuf-source-file "timestamp"
      :proto-pathname "google/protobuf/timestamp.proto")
     (:protobuf-source-file "wrappers"
      :proto-pathname "google/protobuf/wrappers.proto")
     (:file "well-known-types")))))

(pushnew :cl-protobufs *features*)
