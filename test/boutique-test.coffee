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
test = ({ast, body, bodyDesc, errDesc, options}) ->
  ->
    boutique = new Boutique format, options

    e = undefined
    b = undefined

    before (next) ->
      boutique.represent ast, ->
        [e, b] = arguments
        next()

    if errDesc
      it "fails on error, which contains words ‘#{errDesc}’", ->
        assert.include e.message, errDesc
    else
      desc = "produces " + (bodyDesc or "the right body")
      it desc, ->
        assert.equal b, body


describe "Boutique", ->

  describe "handles basic MSON AST", test
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
    bodyDesc: 'object with one property of name ‘id’, having number ‘1’ as a value'

  describe "handles element the right way", ->

    describe "it ensures that ‘primitive’ and ‘oneOf’ are mutually exclusive", test
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
      errDesc: 'mutually exclusive'

    describe "it ensures that ‘primitive’ and ‘ref’ are mutually exclusive", test
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
        ref: 'Something'
      errDesc: 'mutually exclusive'

    describe "it ensures that ‘ref’ and ‘oneOf’ are mutually exclusive", test
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
      errDesc: 'mutually exclusive'

    describe "it properly handles an element without neither type or example value", test
      ast:
        description: 'Dummy description'
      body: 'nil'
      bodyDesc: 'empty value'

    describe "it properly handles an element with simple value, but without type", test
      ast:
        primitive:
          value: '123'
      body: 'str[123]'
      bodyDesc: 'string with value ‘123’'

    describe "it properly handles an element with complex value, but without type", test
      ast:
        primitive:
          value: [
            name: 'name'
            primitive:
              value: 'Gargamel'
          ]
      body: 'obj[prop[name,str[Gargamel]]]'
      bodyDesc: 'object with one property of name ‘name’, having string ‘Gargamel’ as a value'

    describe "it properly handles an element with type, but without value", test
      ast:
        primitive:
          type: 'number'
      body: 'nil'
      bodyDesc: 'empty value'

    describe "it properly handles ‘string’", test
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
      body: 'str[Dummy value]'
      bodyDesc: 'string with value ‘Dummy value’'

    describe "it properly handles ‘number’", test
      ast:
        primitive:
          type: 'number'
          value: '1.2'
      body: 'num[1.2]'
      bodyDesc: 'number with value ‘1.2’'

    describe "it properly handles ‘bool’", test
      ast:
        primitive:
          type: 'bool'
          value: 'True'
      body: 'bool[True]'
      bodyDesc: 'boolean with value ‘True’'

    describe "it properly handles ‘boolean’", test
      ast:
        primitive:
          type: 'boolean'
          value: 'False'
      body: 'bool[False]'
      bodyDesc: 'boolean with value ‘False’'

    describe "it properly handles ‘array’", test
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
      bodyDesc: 'array containing two elements: string with value ‘h2g2’ and number with value ‘42’'

  # describe "handles property the right way", ->

  # describe "deals with empty MSON AST", ->

  # describe "can generate optional properties if asked", ->

  # describe "can generate templated property if asked", ->
