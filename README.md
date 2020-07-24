# cl-protobufs ![Tests](https://github.com/qitab/cl-protobufs/workflows/Tests/badge.svg?branch=master)



cl-protobufs is an implementation of
[Google protocol buffers](https://developers.google.com/protocol-buffers/) for
Common Lisp.

## Installation

1.  Install `protoc`

    Common Lisp code for a given `.proto` file is generated by a plug-in for
    `protoc`, the protocol buffer compiler. The plug-in is written in C++ and
    requires the full version of Google's protocol buffer code to be installed
    in order to build it, not just the precompiled protoc binaries.

    Download and build Google protobuf. Rough instructions are included here for
    Unix systems. If you have any problems please see the
    [protobuf installation instructions](https://github.com/protocolbuffers/protobuf/tree/master/src).

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

2.  Build the Lisp `protoc` plugin

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

When a `.proto` file imports another `.proto` file, `protoc` needs to know how to
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

Build and run the tests with ASDF:

*   Install [Quicklisp](http://quicklisp.org) and make sure to add it to your
    Lisp implementation's init file.

*   Install ASDF if it isn't part of your Lisp implementation.

    

*   Create a link to cl-protobufs so that Quicklisp will use the local version:

    ```shell
    $ cd ~/quicklisp/local-projects
    $ ln -s .../path/to/cl-protobufs
    ```

*   Start Lisp and evaluate `(ql:quickload :cl-protobufs)`.

*   Load and run the tests:

    ```lisp
    cl-user> (asdf:test-system :cl-protobufs)
    ```

## Submitting changes to cl-protobufs



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
for the generated code. This is done to avoid conflicts with existing packages.

The full name of the Lisp type for the `AddNumbersRequest` message is
`cl-protobufs.math:add-numbers-request`.

## Generated Code Guide

This section explains the code generated from a `.proto` file by
`protoc-gen-lisp`, the Common Lisp plugin for `protoc`. See the "protoc"
directory in this distribution for the plugin code.

Note that `protoc-gen-lisp` transforms protobuf names like `MyMessage` or
`my_field` to names that are more Lisp-like, such as `my-message` and
`my-field`.

The code generated by `protoc-gen-lisp` uses macros to define the generated
API. Protocol buffer messages should be defined in `.proto` files instead of
invoking these macros directly. Internal details that are not in the API
documented below may change incompatibly in the future.

### Packages

The generated code for each `.proto` file lives in a package derived from the
`package` statement.

```protocol-buffer
package abc;
```

The generated Lisp package for the above is `cl-protobufs.abc`. The prefix
"cl-protobufs." is added in order to avoid conflicts with another Lisp package
named "abc". If you prefer to use a shorter package name we recommend using
[ace.core.package:defpackage\*](https://github.com/cybersurf/ace.core/blob/master/package.lisp)
to import the package with a local nickname. Example:

```lisp
(ace.core.package:defpackage* #:my.project
  (:use #:common-lisp)
  (:use-alias #:cl-protobufs.abc))  ; Referenced as abc:
```

You may have multiple `.proto` files use the same package if desired. The
package exports the symbols described in the sections below.

### Messages (and Groups)

This section uses the following protocol buffer messages as an example:

```protocol-buffer
package abc;

message DateRange {
    optional string min_date = 1;
    optional string max_date = 2;
}
```

```lisp
(make-date-range :min-date "2020-05-27" :max-date "2020-05-28")
```

Construct a `date-range` message.

```lisp
(date-range.min-date range)
```

Get the value of the `min-date` field from the `range` message.

If the field was explicitly set, that value is returned. Otherwise, a default
value is returned: the default value specified for this field in the `.proto`
file, if any, or a type-specific default value.  Type-specific default values
are as follows:

protobuf type    |  default value
-------------    |  -------------
numerics         |  zero of the appropriate type
strings          |  the empty string
messages         |  `nil`
enums            |  the minimum enum value (possibly negative)
booleans         |  `nil`
repeated fields  |  the empty list

Note that with nested messages and long message names, field accessor names can
get pretty long. If speed is not an issue it is also possible to access fields
via the `cl-protobufs:field` generic function.

```lisp
(cl-protobufs:field range 'min-date)
```

An alternative (slower, but often more concise) way to read a protobuf field's
value.

```lisp
(date-range.has-min-date range)
```

Check whether a field has been set. Returns `t` if the `min-date` field has been
set to a non-default value, otherwise `nil`.

```lisp
(date-range.clear-min-date range)
```

Clear the value of a field. After the above call `(date-range.has-min-date
range)` returns `nil` and `(date-range.min-date range)` returns the default
value.

### Enums

```proto
enum DayOfWeek {
  DAY_UNDEFINED = 0;
  MON = 1;
  TUE = 2;
  WED = 3;
  ...
}
```

The above enum defines the Lisp type `day-of-week`, like this:

```lisp
(deftype day-of-week '(member :day-undefined :mon :tue :wed ...))
```

Each enum value is represented by a keyword symbol which is mapped to/from its
numeric equivalent during serialization and deserialization.

```lisp
(defun day-of-week->numeral (name) ...)
```

Convert a keyword symbol to its numeric value. Example: `(day-of-week->numeral
:mon) => 1`

```lisp
(defun numeral->day-of-week (num) ...)
```

Convert a number to its symbolic name. Example: `(numeral->day-of-week 1) =>
:mon`

```lisp
(defconstant +mon+ 1)
```

Each numeric enum value is also bound to a constant by the same name but with
"+" on each side.

Note that most enums should have an "undefined" or "unset" field with value `0`
so that message fields using this enum type have a reasonable default value that
is distinguishable from valid values. (It probably wouldn't make sense for
Monday to be the default day.)

Name conflicts with other enum constants can easily happen if they all have a
field named "undefined", so in this case we named the "undefined" field with a
`DAY_` prefix. For this reason it is also common to nest an enum inside the
message that uses it.

When an enum is defined inside of a message instead of at top level in the
`.proto` file, the message name is prepended to the name. For example, if
`DayOfWeek` had been defined inside of a `Schedule` message it would result in
these definitions:

```lisp
(deftype schedule.day-of-week '(member :day-undefined :mon :tue :wed ...))
(schedule.day-of-week->numeral :mon) => 1
(numeral->schedule.day-of-week 1) => :MON
(defconstant +schedule.day-undefined+ 0)  ; may not need the DAY_ prefix now.
(defconstant +schedule.mon+ 1)
...

```

### Maps

This section uses the following protocol buffer message as an example:

```protocol-buffer
message Dictionary {
  map<int32,string> map_field = 1;
}
```
This creates an associative map with keys of type `int32` and values of
type `string`. In general, the key type can be any scalar type except
`float` and `double`. The value type can be any protobuf type. For a message
`dict` of type `Dictionary`, the following functions are created to
access the map:

```lisp
(dictionary.map-field-gethash 2 dict)
```
This returns the value associated with `2` in the `map-field` field in `dict`.
If there is no value explicitly set, this function returns the default value
of the value type. In this case, the empty string.

```lisp
(setf (dictionary.map-field-gethash 1 dict) "one")
```
This associates `1` with the value `"one"` in the `map-field` field in `dict`.

```lisp
(dictionary.map-field-remhash 1 dict)
```
This removes any entry with key `1` in the `map-field` field in `dict`.

Like the other fields, these functions are aliased by methods which are slower
but more concise. Examples of the methods are: `(map-field-gethash 2 dict)`,
`(setf (map-field-gethash 1 dict) "one")`, and `(map-field-remhash 1 dict)`.
These have the same functionality as the above 3 functions respectively.

These functions are type checked, and interfacing with the map with these
functions alone will guarantee that (de)serialization functions as well as the
`(dictionary.has-map-field dict)` function will work properly. The underlying
hash table may be accessed directly via `(dictionary.map-field dict)`, but doing
so may result in undefined behavior.

### Oneof
This section uses the following protobuf message as an example:
```protocol-buffer
message Person {
  optional string name = 1;
  oneof AgeOneof {
    optional int32 age = 2;
    optional string birthdate = 3;
  }
}
```
To access fields inside a oneof, just use the standard accessors outlined above. For example:

```lisp
(setf (person.age bob) 5)
```
will set the `age` field of a `Person` object `bob` to `5`. Defining a oneof also creates
two special functions:
`(person.age-oneof-case bob)`
This will return the lisp symbol corresponding to the field which is currently set. So, if
we set `age` to `5`, then this will return `age`. If no field is set, this function will
return `nil`.
`(person.clear-age-oneof bob)`
This will clear all fields inside of the oneof `age-oneof`.

### Options

TODO

### Services

This section describes the API for a protobuf service in a proto file. You must
have a corresponding RPC Lisp library as well; `cl-protobufs` just generates the
methods.

TODO: open source a Lisp RPC library

The following example service definition is used throughout this section.

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

```lisp
(defgeneric add-numbers-impl (channel (request add-numbers-request) rpc))
```

A generic function generated for each RPC in the service definition. The name is
the concatenation of the protobuf service name (in its Lisp form) and the string
"-impl".

To implement the service define a method for each generic function. The method
must return the type declared in the `.proto` file. Example:

```lisp
(defmethod add-numbers-impl (channel (request add-numbers-request) rpc)
  (make-add-numbers-response :sum (+ (add-numbers-request.number1 request)
                                     (add-numbers-request.number2 request))))
```

The `channel` argument is supplied by the underlying RPC code and differs
depending on which transport mechanism (HTTP, TCP, IPC, etc) is being used.
The `channel` and `rpc` arguments can usually be ignored.


## The cl-protobufs Package

This section documents the symbols exported from the `cl-protobufs` package.

```lisp
(defstruct base-message ...)
```

The base type from which every generated protobuf message inherits.

```lisp
(defun print-text-format (object &key (stream *standard-output*)
                                 (print-name t)
                                 (pretty-print t))
```

Prints a protocol buffer message to a stream. `object` is the protocol buffer
message, group, or extension to print. `stream` is the stream to print
to. `print-name` may be set to `nil` to prevent printing the name of the object
first. `pretty-print` may be set to `nil` to minimize textual output by omitting
most whitespace.

```lisp
(defun is-initialized (object))
```

Check if `object` has all required fields set, and recursively all of its
sub-objects have all of their required fields set. An error may be signaled if
an attempt is made to serialize a protobuf object that is not initialized.
Signals an error if `object` is not a protobuf message.

```lisp
(defun proto-equal (message-1 message-2 &key exact nil))
```

Check if two protobuf messages are equal. By default, two messages are equal if
calling the getter on each field would retrieve the same value. This means that
a message with a field explicitly set to the default value is considered equal
to a message with that field not set.

If `exact` is true, consider the messages to be equal only if the same fields
have been explicitly set.

`message-1` and `message-2` must both be protobuf messages.

```lisp
(defgeneric clear (object message))
```

Resets the protobuf message to its initial state.

```lisp
(defun has-field (object field))
```

Returns whether `field` has been explicitly set in `object`. `field` is the
symbol naming the field in the proto message.

### Serialization

```lisp
(deftype byte-vector)
```

A vector of unsigned-bytes. In serialization functions this is often referred to
as buffer.

```lisp
(defun make-byte-vector (size &key adjustable))
```

Constructor to make a byte vector. `size` is the size of the underlying
vector. `adjustable` is a boolean value determining whether the byte-vector can
change size.

```lisp
(defun serialize-object-to-bytes (object &optional (type (type-of object))))
```

Creates a byte-vector and serializes a protobuf message to that byte-vector. The
`object` is the protobuf message instance to serialize. Optionally use `type` to
specify the type of object to serialize.

```lisp
(serialize-object-to-file (filename object &optional (type (type-of object))))
```

Serialize a protobuf message to a file. Calls `with-open-file` using `:direction
:output` and `:element-type '(unsigned-byte 8)`. `filename` is the name of the
file to write to. `object` is the object to serialize. Optionally use `type` to
specify the type of object to serialize.

```lisp
(defun serialize-object-to-stream (stream object &optional (type (type-of object)))
```

Serialize `object`, a protobuf message, to `stream`.  Optionally use `type` to
specify the type of object to serialize.

```lisp
(defun deserialize-object (type buffer &optional (start 0) (end (length buffer))))
```

Deserialize a protobuf message returning the newly created structure. `type` is
the symbol naming the protobuf message to deserialize. `buffer` is the
byte-vector containing the data to deserialize. `start` (inclusive) and `end`
(exclusive) delimit the range of bytes to deserialize.


## Well Known Types

Several functions are exported from the `cl-protobufs.well-known-types` package.
A list of all well known types can be found in the [official Protocol Buffers
documentation](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf).

```lisp
(defun unpack-any (any-message))
```

Takes an `Any` protobuf message `any-message` and turns it into the stored
protobuf message as long as the qualified-name given in the type-url corresponds
to a loaded message type. The type-url must be of the form
base-url/qualified-name.

```lisp
(defun pack-any (message &key (base-url "type.googleapis.com"))
```

Creates an `Any` protobuf message given a protobuf `message` and a `base-url`.

TODO: examples
