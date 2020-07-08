# cl-protobufs ![Tests](https://github.com/qitab/cl-protobufs/workflows/Tests/badge.svg?branch=master)



cl-protobufs is an implementation of [Google protocol
buffers](https://developers.google.com/protocol-buffers/) for Common Lisp.

## Installation

1.  Install `protoc`

    Common Lisp code for a given .proto file is generated by a plug-in for
    `protoc`, the protocol buffer compiler. The plug-in is written in C++ and
    requires the full version of Google's protocol buffer code to be installed
    in order to build it, not just the precompiled protoc binaries.

    Download and build Google protobuf. Rough instructions are included here for
    Unix systems. If you have any problems please see the [protobuf installation
    instructions](https://github.com/protocolbuffers/protobuf/tree/master/src).

    ```shell
    $ git clone --recursive https://github.com/google/protobuf
    $ cd protobuf
    $ ./autogen.sh
    $ ./configure --prefix=/usr/local
    $ make
    $ make check
    $ sudo make install
    $ sudo ldconfig
    ```

    Make sure the `protoc` binary is on your `PATH`.

2.  Build the Lisp `protoc` plug-in

    ```shell
    $ cd cl-protobufs/protoc
    $ PROTOC_ROOT=/usr/local make     # value of --prefix, above
    $ sudo cp protoc-gen-lisp /usr/local/bin/
    ```

    Make sure the installation directory is on your `PATH`.

## Using `protoc` to Generate Lisp Code

To test your build, try generating Lisp code from the
`cl-protobufs/tests/case-preservation.proto` file with the following command.
Note that the command may differ slightly depending on what directory you're in
and where you installed `protoc-gen-lisp`. In this case we assume you're in the
directory **containing** the `cl-protobufs` directory. The reason will become
clear in a moment.

```shell
$ protoc --plugin=protoc-gen-lisp=/usr/local/bin/protoc-gen-lisp \
  --lisp_out=output-file=case-preservation.lisp:/tmp \
  cl-protobufs/tests/case-preservation.proto
```

This command should generate a file named `case-preservation.lisp` in the
`/tmp/` directory.

When a .proto file imports another .proto file, `protoc` needs to know how to
find the imported file. It does this by looking for the file relative to the
values passed to it with the `--proto_path` option (or the `-I` short option).

To see an example of this, you can try generating Lisp code for
`cl-protobufs/tests/extend-test.proto`.  Still in the same directory, run the
following command:

```shell
protoc --plugin=protoc-gen-lisp=/usr/local/bin/protoc-gen-lisp \
  --lisp_out=output-file=extend-test.lisp:/tmp --proto_path=. \
  cl-protobufs/tests/extend-test.proto
```

The file `/tmp/extend-test.lisp` should be generated. Note that the .lisp file
for each imported file also needs to be generated separately.

### ASDF

It's currently possible to build cl-protobufs and cl-protobufs-tests with ASDF,
but only the wire-tests target is included in the tests because the
:protobuf-file build action no longer works. We hope to fix this in a future
release.

* Install [Quicklisp](http://quicklisp.org) and make sure to add it to your
  Lisp implementation's init file.

* Install ASDF if it isn't part of your Lisp implementation.

  

* Create a link to cl-protobufs so that Quicklisp will use the local version:

  ```shell
  $ cd ~/quicklisp/local-projects
  $ ln -s .../path/to/cl-protobufs
  ```

* Start Lisp and evaluate `(ql:quickload :cl-protobufs)`.
* Load and run the tests:

  ```lisp
  cl-user> (asdf:test-system :cl-protobufs)
  ```

## Submitting changes to cl-protobufs

### Submitting a change through GitHub.

1. Create a pull request like usual through GitHub.
2. Sign the [Google CLA agreement](https://cla.developers.google.com/clas).
This must be done only once for all Google projects.
This must be done for your pull request to be approved.
3. Add someone in the [Googlers team](https://github.com/orgs/qitab/teams/googlers) as a reviewer.
4. When the reviewer is satisfied they will add the `Ready for Google` label.
5. The pull request will later be merged.

## Examples

The files `example/math.lisp` and `example/math-test.lisp` give a simple example
of creating a proto structure, populating its fields, serializing, and then
deserializing. Looking over these files is a good way to get a quick feel for
the protobuf API, which is described in detail below.

The file `math.proto` has two messages: `AddNumbersRequest` and
`AddNumbersResponse`.



The prefix `cl-protobufs.` is automatically added to the package name specified
by `package math;`, resulting in `cl-protobufs.math` as the full package name
for the generated code. This is done to avoid conflicts with existing
packages. The `lisp_package` option may be used to override the default package
name. For example:

```proto
package math;
option (lisp_package) = "com.example.math"
```

The full name of the Lisp type for the `AddNumbersRequest` message is
`cl-protobufs.math:add-numbers-request`.


## API

All of the following interfaces are generated by `protoc-gen-lisp`, the Common
Lisp plug-in for the `protoc` tool.

### cl-protobufs

```lisp
(defstruct base-message)
```
The base type every protobuf message inherits.

```lisp
(defun print-text-format (object &key (stream *standard-output*) (print-name t)
                                 (suppress-line-breaks *suppress-line-breaks*))
```
Prints a protocol buffer message to a stream.
The object is the protocol buffer message to print.
The stream is the stream to print to.
Can specify whether to print the top level proto message name with print-name.
Can specify whether to suppress-line-breaks.

```lisp
(defun is-initialized (object))
```
Check if OBJECT has every required field set, and recursively
all of its sub-objects have all of their required fields set.
A protobuf object that is not initialized may not be correctly
serialized/deserialized and may signal an error on
serialization/deserialization.
Object is the protobuf message to check.
Will signal an error if object is not a protobuf message.

```lisp
(defun proto-equal (message-1 message-2 &key exact nil))
```
Check if two protobuf messages are equal. By default
two messages are equal if calling the getter on each
field would retrieve the same value. This means that a
message with a field explicitly set to the default value
is considered the same as a message with that field not
set.

If EXACT is true, consider the messages to be equal
only if the same fields have been explicitly set.

MESSAGE-1 and MESSAGE-2 should both be protobuf
message objects.

```lisp
(defgeneric clear (object message))
```
Resets the protobuf message to its init state.

```lisp
(defun has-field (object field))
```
Returns a bool describing whether the object has the field set.
Object is the object which may have field defined.
Field is the symbol package::field-name of the field in the proto message.

```lisp
(defun proto-slot-value (object slot))
```
Returns the value of SLOT in OBJECT.
Object is the lisp proto object.
Slot is the symbol package::field-name of the field in the proto message.
Deprecated, instead use the accessors specified below.

```lisp
(defun (setf proto-slot-value) (value object slot))
```
The setf function for proto-slot-value.
Deprecated, do not use.

```lisp
(defun proto-slot-is-set (object slot))
```
Deprecated, instead use the accessors setter specified below.

### Proto package

We assume that the protobuf assigned lisp package package, and a message:

```protocol-buffer
lisp_package = "math";

message msg {
  optional int32 field = 1;
}
```

This will put the protobufs in the lisp package ```cl-protobufs.math``` package.

```lisp
(defun make-msg ($key field-names))
```
Construct the proto object for MSG setting the fields in FIELD-NAMES.

```lisp
(defun msg.field (object))
```
Get the value of FIELD in protobuf MSG from OBJECT.
If the field has a default and the field is unset it returns that default,
otherwise return a type specific default value of field bar.
For example, for an int32 field it should return 0 if unset.

```lisp
(defmethod field (object 'msg))
```
Same as msg.field.
Deprecated.

```lisp
(defun msg.has-field (object))
```
Returns a bool describing whether the OBJECT has FIELD set.
Object is the object which may have field defined.

```lisp
(defun msg.clear-field (object))
```
Clear the value of FIELD in OBJECT, setting it to the fields init state.
Object is the lisp proto object.

### Well Known Types

In well-known-type.lisp we implement the handling for several
protobuf well known types.

A list of all well known types can be found:
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf


```lisp
(defun unpack-any (any-message))
```
Takes an Any protobuf message ANY-MESSAGE and turns it into the stored protobuf
message as long as the qualified-name given in the type-url corresponds to a
loaded message type.
The type-url must be of the form base-url/qualified-name.

```lisp
(defun pack-any (message &key (base-url "type.googleapis.com"))
```
Creates an any message protobuf message given a protobuf MESSAGE
and a BASE-URL.

### Map Types

This library supports map types. Defining a proto MSG with map field FIELD
will generate the following functions:

```lisp
(defun msg.field-gethash (key object))
```
Return the value mapped from KEY in OBJECT. If there is no value set, this
function returns the default value of the map's value type.

```lisp
(defun (setf (msg.field-gethash) (value key object)))
```
Set the hash of KEY to VALUE in OBJECT. An example of using this function
would be:
```lisp
(setf (msg.field-gethash key object) value)
```
Which is in line with Common Lisp's `hash-table`.

```lisp
(defun msg.field-remhash (key object))
```
Remove the hash of KEY in OBJECT.

These three functions are type checked, and interfacing with the map with
these three functions alone will guarantee that (de)serialization functions
as well as the `msg.has-field` function will work properly. However, if
the user wants access to the underlying hash-table then they may use the
generic accessor `(msg.field (object))` defined above (where `field` is a
map field). Warning: this accessor is not type checked, so undefined behaviour
may occur.

### Proto package-rpc2

We will now discuss the api for  a protobuf service in a proto file.
You must have a gRPC lisp library as well, cl-protobufs just generates
the methods.

We will use this example protocol buffer:


```protocol-buffer
lisp_package = "math";

message AddNumbersRequest {
  optional int32 number1 = 1;
  optional int32 number2 = 1;
}

message AddNumbersResponse {
  optional int32 AddNumbersResponse = 1;
}

Service MyService
  rpc AddNumbers(AddNumbersRequest) returns (AddNumbersResponse) {}
}
```

This will put the service forms in the lisp package ```cl-protobufs.math-rpc``` package.
For brevity we will alias ```cl-protobufs.math``` as ```math```.

```lisp
(defgeneric add-numbers-request-impl (channel (request math:add-numbers-request) rpc))
```
The implementation of the RPC call, "-impl" is prepended to the RPC name.
The REQUEST will be the proto defined by the AddNumbersRequest message.
The user should have the function return a AddNumbersResponse message proto.
The CHANNEL is the channel that is being used and the user can usually ignore it.
The RPC is the RPC object being used, and the user can usually ignore it.

The user must override this with a method, for example

```lisp
(defmethod add-numbers-impl (service (request math:add-numbers-request) rpc)
  (make-add-numbers-response :sum (+ (math:add-numbers-request.number1 request)
                                     (math:add-numbers-request.number2 request))))
```

```lisp
(defgeneric call-add-numbers (channel (request math:add-numbers-request) &key callback response))
```
Your proto library should implement an override for this function.
The CHANNEL should be the RPC to use.
The REQUEST is the AddNumbersRequest proto message use in the call.
The CALLBACK is a function to call when the call is over.
The RESPONSE is a proto to set for the response.

### Serialization

```lisp
(deftype byte-vector)
```
A vector of unsigned-bytes.
In serialization functions this is often referred to as buffer.

```lisp
(defun make-byte-vector (size &key adjustable))
```
Constructor to make a byte vector.
The SIZE is the size of the underlying vector.
ADJUSTABLE is a boolean value determining whether the byte-vector can change size.

```lisp
(defun serialize-object-to-bytes (object &optional (type (type-of object))))
```
Creates a byte-vector and serializes a protobuf message to that byte-vector.
The OBJECT is the protobuf message instance to serialize.
Optionally use TYPE to specify the type of object to serialize.

```lisp
(serialize-object-to-file (filename object &optional (type (type-of object))))
```
Serialize an protobuf message to a file.
Calls with-open-file using :direction :output and :element-type '(unsigned-byte 8).
The FILENAME is the name of the file to save the object to.
The OBJECT is the object instance to serialize.
Optionally use TYPE to specify the type of object to serialize.

```lisp
(defun serialize-object-to-stream (stream object &optional (type (type-of object)))
```
Serialize a protobuf message to a stream.
The STREAM is the stream instance to serialize the protobuf message to.
The OBJECT is the object to serialize.
Optionally use TYPE to specify the type of object to serialize.

```lisp
(defun deserialize-object (type buffer &optional (start 0) (end (length buffer))))
```
Deserialize a protobuf message returning the newly created structure.
The TYPE is the symbol of the protobuf message to deserialize.
The BUFFER is the byte-vector containing the object to deserialize.
START is the index in byte-vector at which the serialized object originates.
END is the last index in byte-vector of the serialized object.
