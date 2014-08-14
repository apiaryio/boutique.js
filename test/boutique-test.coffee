require 'mocha'
{assert} = require 'chai'

{Boutique} = require '../lib/boutique.coffee'


# straightforward pseudo-format to keep testing of the Boutique core
# as format-agnostic as it gets
format =
  representObject: (properties) ->
    joined = properties.join ','
    "obj[#{joined}]"

  representObjectProperty: (name, value) ->
    "prop[#{name},#{value}]"

  representArray: (elements) ->
    joined = elements.join ','
    "arr[#{joined}]"

  representString: (value) ->
    "str[#{value}]"

  representNumber: (value) ->
    "num[#{value}]"

  representBool: (value) ->
    "bool[#{value}]"

  representNull: ->
    "nil"


# test helper to keep things DRY a bit
test = ({ast, body, err, options}) ->
  ->
    boutique = new Boutique format, options

    e = undefined
    b = undefined

    before (next) ->
      boutique.represent ast, ->
        [e, b] = arguments
        next()

    if err
      it 'fails on the right error', ->
        assert.include e.message, err
    else
      it 'produces the right body', ->
        assert.equal b, body


describe 'Boutique', ->

  describe 'handles basic MSON AST', test
    ast:
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
    body: 'obj[prop[id,num[1]]]'

  describe 'handles element the right way', ->

    describe 'it ensures that ‘primitive’ and ‘oneOf’ are mutually exclusive', test
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
        oneOf: [
            primitive:
              type: 'number'
              value: '0'
          ,
            primitive:
              type: 'number'
              value: '1'
        ]
      err: 'mutually exclusive'

    describe 'it ensures that ‘primitive’ and ‘ref’ are mutually exclusive', test
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
        ref: 'Something'
      err: 'mutually exclusive'

    describe 'it ensures that ‘ref’ and ‘oneOf’ are mutually exclusive', test
      ast:
        oneOf: [
            primitive:
              type: 'number'
              value: '0'
          ,
            primitive:
              type: 'number'
              value: '1'
        ]
        ref: 'Something'
      err: 'mutually exclusive'

    describe 'it properly handles an element without neither type or example value', test
      ast:
        description: 'Dummy description'
      body: 'nil'

    describe 'it properly handles an element with simple value, but without type', test
      ast:
        primitive:
          value: '123'
      body: 'str[123]'

    describe 'it properly handles an element with complex value, but without type', test
      ast:
        primitive:
          value: [
            name: 'name'
            primitive:
              value: 'Gargamel'
          ]
      body: 'obj[prop[name,str[Gargamel]]]'

    describe 'it properly handles an element with type, but without value', test
      ast:
        primitive:
          type: 'number'
      body: 'nil'

    describe 'it properly handles ‘string’', test
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
      body: 'str[Dummy value]'

    describe 'it properly handles ‘number’', test
      ast:
        primitive:
          type: 'number'
          value: '1.2'
      body: 'num[1.2]'

    describe 'it properly handles ‘bool’', test
      ast:
        primitive:
          type: 'bool'
          value: 'True'
      body: 'bool[True]'

    describe 'it properly handles ‘boolean’', test
      ast:
        primitive:
          type: 'boolean'
          value: 'False'
      body: 'bool[False]'

    describe 'it properly handles ‘array’', test
      ast:
        primitive:
          type: 'array'
          value: [
              primitive:
                type: 'string'
                value: 'h2g2'
            ,
              primitive:
                type: 'number'
                value: '42'
          ]
      body: 'arr[str[h2g2],num[42]]'

  # describe 'handles property the right way', ->

  # describe 'deals with empty MSON AST', ->

  # describe 'can generate optional properties if asked', ->

  # describe 'can generate templated property if asked', ->
