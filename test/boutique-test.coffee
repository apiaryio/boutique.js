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


describe "Boutique", ->
  test = ({ast, repr, reprDesc, errDesc, options}) ->
    ->
      boutique = new Boutique format, options

      e = undefined
      r = undefined

      before (next) ->
        boutique.represent ast, ->
          [e, r] = arguments
          next()

      if errDesc
        it "fails on error, which contains words ‘#{errDesc}’", ->
          assert.include e.message, errDesc
      else
        desc = "produces " + (reprDesc or "the right representation")
        it desc, ->
          assert.equal r, repr

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

  describe "handles empty MSON AST given as ‘object’", test
    ast: {}
    repr: 'nil'
    reprDesc: 'empty representation'

  describe "handles empty MSON AST given as ‘null’", test
    ast: null
    repr: 'nil'
    reprDesc: 'empty representation'

  describe "generates optional properties by default", test
    ast:
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
    ast:
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

  describe "does not generate templated properties", test
    ast:
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


describe "Boutique's element handler", ->
  test = ({obj, repr, reprDesc, errDesc, options}) ->
    ->
      boutique = new Boutique format, options

      e = undefined
      r = undefined

      before ->
        try
          r = boutique.handleElement obj
        catch err
          e = err

      if errDesc
        it "fails on error, which contains words ‘#{errDesc}’", ->
          assert.include e.message, errDesc
      else
        desc = "produces " + (reprDesc or "the right representation")
        it desc, ->
          assert.equal r, repr

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

  describe "properly handles an element with simple value, but without type", test
    obj:
      primitive:
        value: '123'
    repr: 'str[123]'
    reprDesc: 'string with value ‘123’'

  describe "properly handles an element with complex value, but without type", test
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
