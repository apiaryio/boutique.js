require 'mocha'
{assert} = require 'chai'

{Boutique} = require '../lib/boutique.coffee'


# straightforward pseudo-format to keep testing of the Boutique core
# as format-agnostic as it gets
pseudoFormat =
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


# another pseudo-format, with its own implementation of oneOf
pseudoFormatWithOneOf =
  representOneOfElements: (elements) ->
    joined = elements.join ','
    "elOneOf[#{joined}]"
  representOneOfProperties: (properties) ->
    joined = properties.join ','
    "propOneOf[#{joined}]"

for name, fn of pseudoFormat
  pseudoFormatWithOneOf[name] = fn


describe "Boutique", ->
  test = ({ast, repr, reprDesc, errDesc, format, options}) ->
    ->
      format = format or pseudoFormat
      boutique = new Boutique format, options

      err = undefined
      body = undefined

      before (next) ->
        boutique.represent ast, ->
          [err, body] = arguments
          next()

      if errDesc
        it "fails on error, which contains words ‘#{errDesc}’", ->
          assert.ok err
          assert.include err.message, errDesc
      else
        desc = "produces " + (reprDesc or "the right representation")
        it desc, ->
          assert.equal body, repr

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
    repr: 'obj[prop[id,num[1]]]'
    reprDesc: 'object with one property of name ‘id’, having number ‘1’ as a value'

  describe "handles empty MSON AST given as empty object", test
    ast: {}
    repr: 'nil'
    reprDesc: 'empty representation'

  describe "handles empty MSON AST given as ‘null’", test
    ast: null
    repr: 'nil'
    reprDesc: 'empty representation'


describe "Boutique's element handler", ->
  test = ({obj, repr, reprDesc, errDesc, format, options}) ->
    ->
      format = format or pseudoFormat
      boutique = new Boutique format, options

      err = undefined
      body = undefined

      before ->
        try
          body = boutique.handleElement obj
        catch err
          err = err

      if errDesc
        it "fails on error, which contains words ‘#{errDesc}’", ->
          assert.ok err
          assert.include err.message, errDesc
      else
        it 'produces no error', ->
          assert.notOk err
        desc = "produces " + (reprDesc or "the right representation")
        it desc, ->
          assert.equal body, repr

  describe "ensures that ‘primitive’ and ‘oneOf’ are mutually exclusive", test
    obj:
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

  describe "ensures that ‘primitive’ and ‘ref’ are mutually exclusive", test
    obj:
      primitive:
        type: 'string'
        value: 'Dummy value'
      ref: 'Something'
    errDesc: 'mutually exclusive'

  describe "ensures that ‘ref’ and ‘oneOf’ are mutually exclusive", test
    obj:
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

  describe "properly handles an element without neither type or example value", test
    obj:
      description: 'Dummy description'
    repr: 'nil'
    reprDesc: 'empty value'

  describe "properly handles simple value without type as ‘string’", test
    obj:
      primitive:
        value: '123'
    repr: 'str[123]'
    reprDesc: 'string with value ‘123’'

  describe "properly handles complex value without type as ‘object’", test
    obj:
      primitive:
        value: [
          name: 'name'
          primitive:
            value: 'Gargamel'
        ]
    repr: 'obj[prop[name,str[Gargamel]]]'
    reprDesc: 'object with one property of name ‘name’, having string ‘Gargamel’ as a value'

  describe "properly handles an element with type, but without value", test
    obj:
      primitive:
        type: 'number'
    repr: 'nil'
    reprDesc: 'empty value'

  describe "properly handles ‘string’", test
    obj:
      primitive:
        type: 'string'
        value: 'Dummy value'
    repr: 'str[Dummy value]'
    reprDesc: 'string with value ‘Dummy value’'

  describe "properly handles ‘number’", test
    obj:
      primitive:
        type: 'number'
        value: '1.2'
    repr: 'num[1.2]'
    reprDesc: 'number with value ‘1.2’'

  describe "properly handles ‘bool’", test
    obj:
      primitive:
        type: 'bool'
        value: 'True'
    repr: 'bool[True]'
    reprDesc: 'boolean with value ‘True’'

  describe "properly handles ‘boolean’", test
    obj:
      primitive:
        type: 'boolean'
        value: 'False'
    repr: 'bool[False]'
    reprDesc: 'boolean with value ‘False’'

  describe "properly handles ‘array’", test
    obj:
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
    repr: 'arr[str[h2g2],num[42]]'
    reprDesc: 'array containing two elements: string with value ‘h2g2’ and number with value ‘42’'

  describe "properly handles ‘object’", test
    obj:
      primitive:
        type: 'object'
        value: [
            name: 'abbr'
            primitive:
              type: 'string'
              value: 'h2g2'
          ,
            name: 'id'
            primitive:
              type: 'number'
              value: '42'
        ]
    repr: 'obj[prop[abbr,str[h2g2]],prop[id,num[42]]]'
    reprDesc: 'object containing two properties: string ‘abbr’ with value ‘h2g2’ and number ‘id’ with value ‘42’'

  describe "generates optional properties by default", test
      obj:
        primitive:
          type: 'object'
          value: [
              name: 'id'
              required: true
              description: 'The unique identifier of an employee'
              primitive:
                type: 'number'
                value: '1'
            ,
              name: 'name'
              required: false
              description: 'Name of the employee'
              primitive:
                type: 'string'
                value: 'Věroš'
          ]
      repr: 'obj[prop[id,num[1]],prop[name,str[Věroš]]]'
      reprDesc: 'object with one required property of name ‘id’ and one optional property of name ‘name’'

  describe "doesn't generate optional properties if ‘skipOptional’ option given as ‘true’", test
    options:
      skipOptional: true
    obj:
      primitive:
        type: 'object'
        value: [
            name: 'id'
            required: true
            description: 'The unique identifier of an employee'
            primitive:
              type: 'number'
              value: '1'
          ,
            name: 'name'
            required: false
            description: 'Name of the employee'
            primitive:
              type: 'string'
              value: 'Věroš'
        ]
    repr: 'obj[prop[id,num[1]]]'
    reprDesc: 'object with one required property of name ‘id’'

  describe "doesn't generate templated properties", test
    obj:
      primitive:
        type: 'object'
        value: [
            name: 'id'
            required: true
            description: 'The unique identifier of an employee'
            primitive:
              type: 'number'
              value: '1'
          ,
            name: 'additional properties'
            templated: true
            description: 'Any other additional properties.'
        ]
    repr: 'obj[prop[id,num[1]]]'
    reprDesc: 'object with one required property of name ‘id’ and one optional property of name ‘name’'

  describe "selects the first element from ‘oneOf’ if format doesn't implement it's own rendering", test
    obj:
      oneOf: [
          primitive:
            type: 'number'
            value: '42'
        ,
          primitive:
            type: 'string'
            value: 'hello'
      ]
    repr: 'num[42]'
    reprDesc: 'number with value ‘42’'

  describe "selects the first property from ‘oneOf’ if format doesn't implement it's own rendering", test
    obj:
      primitive:
        value: [
            name: 'name'
            primitive:
              value: 'Věroš'
          ,
            oneOf: [
                name: 'xor1'
                primitive:
                  type: 'number'
                  value: '42'
              ,
                name: 'xor2'
                primitive:
                  type: 'string'
                  value: 'hello'
            ]
          ,
            name: 'size'
            primitive:
              value: 'XL'
        ]
    repr: 'obj[prop[name,str[Věroš]],prop[xor1,num[42]],prop[size,str[XL]]]'
    reprDesc: 'object with properties ‘name’, ‘xor1’, and ‘size’.'

  describe "properly handles ‘oneOf’ elements if format implements it's own rendering", test
    format: pseudoFormatWithOneOf
    obj:
      oneOf: [
          primitive:
            type: 'number'
            value: '42'
        ,
          primitive:
            type: 'string'
            value: 'hello'
      ]
    repr: 'elOneOf[num[42],str[hello]]'
    reprDesc: 'one of values ‘42’ and ‘hello’'

  describe "properly handles ‘oneOf’ properties if format implements it's own rendering", test
    format: pseudoFormatWithOneOf
    obj:
      primitive:
        value: [
            name: 'name'
            primitive:
              value: 'Věroš'
          ,
            oneOf: [
                name: 'xor1'
                primitive:
                  type: 'number'
                  value: '42'
              ,
                name: 'xor2'
                primitive:
                  type: 'string'
                  value: 'hello'
            ]
          ,
            name: 'size'
            primitive:
              value: 'XL'
        ]
    repr: 'obj[prop[name,str[Věroš]],propOneOf[prop[xor1,num[42]],prop[xor2,str[hello]]],prop[size,str[XL]]]'
    reprDesc: 'object with properties ‘name’, then one of ‘xor1’ and ‘xor2’, and then ‘size’.'

  describe "doesn't implement ‘ref’ yet", test
    obj:
      ref: 'Another'
    errDesc: 'implemented'
