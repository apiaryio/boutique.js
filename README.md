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

...we can convert it using Boutique's **simple interface**. Simple interface
has sensible defaults and built-in set of supported formats:

```coffee
boutique = require 'boutique'
boutique.represent ast, 'application/json', (err, body) ->
  # body contains '{"id": 1}' string

```

However, there's also **fully-customizable interface**:

```coffee
{Boutique, defaultFormats} = require 'boutique'

jsonFormat = defaultFormats['application/json']
boutique = new Boutique jsonFormat
boutique.represent ast, (err, body) ->
  # body contains '{"id": 1}' string

foobarFormat = require './formats/foobar.coffee'
boutique = new Boutique foobarFormat,
  skipOptional: false
boutique.represent ast, (err, body) ->
  # ...

```

Also the logic of **format selection** is exposed, if you need it:

```coffee
{defaultFormats, selectFormat} = require 'boutique'
foobarFormat = require './formats/foobar.coffee'

formats =
  'application/vnd.foobar+json': foobarFormat
for own contentType, format of defaultFormats
  formats[contentType] = format

format = selectFormat 'application/vnd.foobar+json', formats
# format equals to `foobarFormat` from the example above

format = selectFormat 'application/json', formats
# format equals to `jsonFormat` from the example above
```

For examples of format implementation please see [the
collection of default formats](https://github.com/apiaryio/boutique/tree/master/formats).
