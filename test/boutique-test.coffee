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
      it 'ends with no error', ->
        assert.notOk e
      it 'produces the right body', ->
        assert.equal body, b


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
        description: 'Dummy description'
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
        description: 'Dummy description'
        primitive:
          type: 'string'
          value: 'Dummy value'
        ref: 'Something'
      err: 'mutually exclusive'

    describe 'it ensures that ‘ref’ and ‘oneOf’ are mutually exclusive', test
      ast:
        description: 'Dummy description'
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

  # describe 'handles property the right way', ->

  # describe 'deals with empty MSON AST', ->

  # describe 'can generate optional properties if asked', ->

  # describe 'can generate templated property if asked', ->
