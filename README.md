# Boutique

Looking for the best fashion for your [MSON AST](https://github.com/apiaryio/mson-ast)? Boutique offers the finest quality, luxury representations to emphasize natural beauty of your AST.

![illustration](https://github.com/apiaryio/boutique/blob/master/assets/boutique.png?raw=true)

## Usage

Having following AST...

```coffeescript
ast = types: [
  name: null
  base:
    typeSpecification:
      name: "object"

  sections: [
    type: "member"
    content: [
      type: "property"
      content:
        name:
          literal: "id"

        valueDefinition:
          values: [literal: "1"]
          typeDefinition:
            attributes: ["required"]
    ,
      type: "property"
      content:
        name:
          literal: "name"

        valueDefinition:
          values: [literal: "A green door"]
    ,
      type: "property"
      content:
        name:
          literal: "price"

        valueDefinition:
          values: [literal: "12.50"]
          typeDefinition:
            typeSpecification:
              name: "number"
    ,
      type: "property"
      content:
        name:
          literal: "tags"

        valueDefinition:
          values: [
            literal: "home"
          ,
            literal: "green"
          ]
    ,
      type: "property"
      content:
        name:
          literal: "vector"

        valueDefinition:
          typeDefinition:
            typeSpecification:
              name: "array"

        sections: [
          type: "member"
          content: [
            type: "value"
            content:
              valueDefinition:
                values: [literal: "1"]
          ,
            type: "value"
            content:
              valueDefinition:
                values: [literal: "2"]
          ,
            type: "value"
            content:
              valueDefinition:
                values: [literal: "3"]
          ]
        ]
    ]
  ]
]
```

...we can convert it by Boutique to a representation:

```coffeescript
boutique = require 'boutique'
boutique.represent ast, 'application/json', (err, body) ->
  # body contains following string:
  # '{"id":"1","name":"A green door","price":12.50,"tags":["home","green"],"vector":["1","2","3"]}'

boutique.represent ast, 'application/schema+json', (err, body) ->
  # body contains following string:
  # '{"type":"object","properties":"id":{"type":"string"},"name":{"type":"string"},"price":{"type":"number"},"tags":{"type":"array"},"vector":{"type":"array"}}'
```

It's also possible to pass format options:

```coffeescript
boutique = require 'boutique'

options =
  skipOptional: false

boutique.represent ast, 'application/json', options, (err, body) ->
  ...
```

In case AST contains more (named) top-level `types`, it's possible to select the one to be rendered by passing it's name (identifier) as a third argument:

```coffeescript
ast =
  ...  # AST contains array of multiple named types deliberately referencing each other: 'Person', 'Person List', and 'Address'

boutique.represent ast, 'application/schema+json', 'Person List', options, (err, body) ->
  ...  # body contains 'Person List' rendered as JSON Schema
```

## API

**boutique.represent(ast, contentType[, typeName, options], cb)**

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

    Distinguishing JSON Schema draft versions by matching according to `profile` parameter is [not implemented yet](https://github.com/apiaryio/boutique/issues/14).

-   typeName (string) - optional name of top-level [Named Type](https://github.com/apiaryio/mson-ast#named-type-object) to be rendered (defaults to the first one)
-   options (object) - optional set of settings, which are passed to the selected format (*to be documented*)
-   cb (function) - callback function:
    
    **callback(err, repr, contentType)**

    -   err (object) - `null` or exception object in case of error
    -   repr (string) - final string representation of given AST in given format
    -   contentType (string) - selected content type, which was actually used for rendering the representation
