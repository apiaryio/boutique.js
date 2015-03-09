# Boutique

[![Circle CI Status](https://img.shields.io/circleci/project/apiaryio/boutique.js.svg)](https://circleci.com/gh/apiaryio/boutique.js/tree/master)

Looking for the best fashion for your [MSON AST](https://github.com/apiaryio/mson-ast)? Boutique offers the finest quality, luxury representations to emphasize natural beauty of your AST.

![illustration](https://github.com/apiaryio/boutique.js/blob/master/assets/boutique.png?raw=true)

## Introduction

Imagine you have some [MSON](https://github.com/apiaryio/mson) to describe body attributes in your [API Blueprint](https://github.com/apiaryio/api-blueprint/). Drafter should be able to not only to parse it, but also to provide representations of those body attributes in formats you specified, e.g. in `application/json`. Boutique is a simple tool to do exactly that.

Boutique takes an [MSON AST](https://github.com/apiaryio/mson-ast) and provides a representation of it in JSON, JSON Schema or other formats.

![diagram](https://github.com/apiaryio/boutique.js/blob/master/assets/boutique-diagram.png?raw=true)

> **NOTE:** Boutique knows nothing about hypermedia. For example, it understands that `application/hal+json` means it should generate JSON, but it generates *plain* JSON. To generate [HAL](http://stateless.co/hal_specification.html) document properly, the AST has to explicitly contain all HAL structures already on input to this tool.

## Usage

Using the MSON AST from [this example](https://github.com/apiaryio/mson-ast#example) as the `ast` variable, we can convert it by Boutique to a representation:

```coffeescript
boutique = require 'boutique'
boutique.represent
    ast: ast,
    contentType: 'application/json'
  , (err, body) ->
    # body contains following string:
    # '{"id":"1","name":"A green door","price":12.50,"tags":["home","green"],"vector":["1","2","3"]}'

boutique.represent
    ast: ast,
    contentType: 'application/schema+json'
  , (err, body) ->
    # body contains following string:
    # '{"type":"object","properties":"id":{"type":"string"},"name":{"type":"string"},"price":{"type":"number"},"tags":{"type":"array"},"vector":{"type":"array"}}'
```

## API

> **NOTE:** Refer to the [MSON Specification](https://github.com/apiaryio/mson/blob/master/MSON%20Specification.md) for the explanation of terms used throughout this documentation.

### Represent (function)
Generate representation for given content type from given MSON AST.

#### Signature

```coffeescript
boutique.represent({ast, contentType}, cb)
```

#### Parameters

-   `ast` (object) - MSON AST in form of tree of plain JavaScript objects.
-   `contentType`: `application/schema+json` (string, default)

    Smart matching takes place. For example, if following formats are implemented and provided by Boutique...

    -   `application/json`
    -   `application/xml`
    -   `application/schema+json`

    ...then matching will work like this:

    -   `image/svg+xml; charset=utf-8` → `application/xml`
    -   `application/schema+json` → `application/schema+json`
    -   `application/hal+json` → `application/json`

    > **NOTE:** Distinguishing JSON Schema draft versions by matching according to `profile` parameter is [not implemented yet](https://github.com/apiaryio/boutique.js/issues/14).

-   `cb` ([Represent Callback](#represent-callback-function), required) - callback function

### Represent Callback (function)

#### Signature

```coffeescript
callback(err, repr, contentType)
```

#### Parameters

-   `err`: `null` (object, default) - Exception object in case of error
-   `repr` (string) - final string representation of given AST in given format
-   `contentType` (string) - selected content type, which was actually used for rendering the representation
