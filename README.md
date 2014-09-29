# Boutique

Looking for the best fashion for your [MSON AST](https://github.com/apiaryio/mson-ast)? Boutique offers the finest quality, luxury representations to emphasize natural beauty of your AST.

![illustration](https://github.com/apiaryio/boutique/blob/master/assets/boutique.png?raw=true)

## Usage

Having following AST...

```coffee
ast =
  primitive:
    type: 'object'
    value: [
      name: 'id'
      required: true
      description: 'The unique identifier for a product'
      primitive:
        type: 'number'
        value: '1'
    ]
```

...we can convert it by Boutique:

```coffee
boutique = require 'boutique'
boutique.represent ast, 'application/json', (err, body) ->
  # body contains '{"id": 1}' string
```

It's possible to also pass format options:

```coffee
boutique = require 'boutique'

options =
  skipOptional: false

boutique.represent ast, 'application/json', options, (err, body) ->
  ...
```

## API

**boutique.represent(ast, contentType[, options], cb)**

-   ast (object) - MSON AST
-   contentType: "application/json" (string)
    
    Smart matching takes place. For example, if following formats are implemented and provided by Boutique...

    -   `application/json`
    -   `application/xml`
    -   `application/schema+json`

    ...then matching will work like this:

    -   `image/svg+xml; charset=utf-8` → `application/xml`
    -   `application/schema+json` → `application/schema+json`
    -   `application/hal+json` → `application/json`

-   options (object) - optional set of settings, which are passed to the selected format (*to be documented*)
-   cb (function) - callback function:
    
    **callback(err, repr, contentType)**

    -   err (object) - `null` or exception object in case of error
    -   repr (string) - final string representation of given AST in given format
    -   contentType (string) - selected content type, which was actually used for rendering the representation
