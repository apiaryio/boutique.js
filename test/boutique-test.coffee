require 'mocha'
{assert} = require 'chai'

{createTest, callHandleElement} = require './testutils'
{pseudoFormat, pseudoFormatWithOneOf} = require './pseudoformats'


describe "Boutique", ->
  test = createTest pseudoFormat

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
    repr:
      type: 'object'
      value: [
        type: 'property'
        name: 'id'
        value:
          type: 'number'
          value: '1'
      ]
    reprDesc: 'object with one property of name ‘id’, having number ‘1’ as a value'

  describe "handles empty MSON AST given as empty object", test
    ast: {}
    repr:
      type: 'null'
    reprDesc: 'empty representation'

  describe "handles empty MSON AST given as ‘null’", test
    ast: null
    repr:
      type: 'null'
    reprDesc: 'empty representation'


describe "Boutique's element handler", ->
  test = createTest pseudoFormat, callHandleElement
  testOneOf = createTest pseudoFormatWithOneOf, callHandleElement

  describe "ensures that ‘primitive’ and ‘oneOf’ are mutually exclusive", test
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

  describe "ensures that ‘primitive’ and ‘ref’ are mutually exclusive", test
    ast:
      primitive:
        type: 'string'
        value: 'Dummy value'
      ref: 'Something'
    errDesc: 'mutually exclusive'

  describe "ensures that ‘ref’ and ‘oneOf’ are mutually exclusive", test
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

  describe "properly handles an element without neither type or example value", test
    ast:
      description: 'Dummy description'
    repr:
      type: 'null'
    reprDesc: 'empty value'

  describe "properly handles simple value without type as ‘string’", test
    ast:
      primitive:
        value: '123'
    repr:
      type: 'string'
      value: '123'
    reprDesc: 'string with value ‘123’'

  describe "properly handles complex value without type as ‘object’", test
    ast:
      primitive:
        value: [
          name: 'name'
          primitive:
            value: 'Gargamel'
        ]
    repr:
      type: 'object'
      value: [
        type: 'property'
        name: 'name'
        value:
          type: 'string'
          value: 'Gargamel'
      ]
    reprDesc: 'object with one property of name ‘name’, having string ‘Gargamel’ as a value'

  describe "properly handles an element with type, but without value", test
    ast:
      primitive:
        type: 'number'
    repr:
      type: 'null'
    reprDesc: 'empty value'

  describe "properly handles ‘string’", test
    ast:
      primitive:
        type: 'string'
        value: 'Dummy value'
    repr:
      type: 'string'
      value: 'Dummy value'
    reprDesc: 'string with value ‘Dummy value’'

  describe "properly handles ‘number’", test
    ast:
      primitive:
        type: 'number'
        value: '1.2'
    repr:
      type: 'number'
      value: '1.2'
    reprDesc: 'number with value ‘1.2’'

  describe "properly handles ‘bool’", test
    ast:
      primitive:
        type: 'bool'
        value: 'True'
    repr:
      type: 'bool'
      value: 'True'
    reprDesc: 'boolean with value ‘True’'

  describe "properly handles ‘boolean’", test
    ast:
      primitive:
        type: 'boolean'
        value: 'False'
    repr:
      type: 'bool'
      value: 'False'
    reprDesc: 'boolean with value ‘False’'

  describe "properly handles ‘array’", test
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
    repr:
      type: 'array'
      value: [
          type: 'string'
          value: 'h2g2'
        ,
          type: 'number'
          value: '42'
      ]
    reprDesc: 'array containing two elements: string with value ‘h2g2’ and number with value ‘42’'

  describe "properly handles ‘object’", test
    ast:
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
    repr:
      type: 'object'
      value: [
          name: 'abbr'
          type: 'property'
          value:
            type: 'string'
            value: 'h2g2'
        ,
          name: 'id'
          type: 'property'
          value:
            type: 'number'
            value: '42'
      ]
    reprDesc: 'object containing two properties: string ‘abbr’ with value ‘h2g2’ and number ‘id’ with value ‘42’'

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
    repr:
      type: 'object'
      value: [
          name: 'id'
          type: 'property'
          value:
            type: 'number'
            value: '1'
        ,
          name: 'name'
          type: 'property'
          value:
            type: 'string'
            value: 'Věroš'
      ]
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
    repr:
      type: 'object'
      value: [
        name: 'id'
        type: 'property'
        value:
          type: 'number'
          value: '1'
      ]
    reprDesc: 'object with one required property of name ‘id’'

  describe "doesn't generate templated properties", test
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
    repr:
      type: 'object'
      value: [
        name: 'id'
        type: 'property'
        value:
          type: 'number'
          value: '1'
      ]
    reprDesc: 'object with one required property of name ‘id’'

  describe "selects the first element from ‘oneOf’ if format doesn't implement it's own rendering", test
    ast:
      oneOf: [
          primitive:
            type: 'number'
            value: '42'
        ,
          primitive:
            type: 'string'
            value: 'hello'
      ]
    repr:
      type: 'number'
      value: '42'
    reprDesc: 'number with value ‘42’'

  describe "selects the first property from ‘oneOf’ if format doesn't implement it's own rendering", test
    ast:
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
    repr:
      type: 'object'
      value: [
          name: 'name'
          type: 'property'
          value:
            type: 'string'
            value: 'Věroš'
        ,
          name: 'xor1'
          type: 'property'
          value:
            type: 'number'
            value: '42'
        ,
          name: 'size'
          type: 'property'
          value:
            type: 'string'
            value: 'XL'
      ]
    reprDesc: 'object with properties ‘name’, ‘xor1’, and ‘size’.'

  describe "properly handles ‘oneOf’ elements if format implements it's own rendering", testOneOf
    ast:
      oneOf: [
          primitive:
            type: 'number'
            value: '42'
        ,
          primitive:
            type: 'string'
            value: 'hello'
      ]
    repr:
      type: 'oneOfElements'
      value: [
          type: 'number'
          value: '42'
        ,
          type: 'string'
          value: 'hello'
      ]
    reprDesc: 'one of values ‘42’ and ‘hello’'

  describe "properly handles ‘oneOf’ properties if format implements it's own rendering", testOneOf
    ast:
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
    repr:
      type: 'object'
      value: [
          name: 'name'
          type: 'property'
          value:
            value: 'Věroš'
            type: 'string'
        ,
          type: 'oneOfProperties'
          value: [
              name: 'xor1'
              type: 'property'
              value:
                type: 'number'
                value: '42'
            ,
              name: 'xor2'
              type: 'property'
              value:
                type: 'string'
                value: 'hello'
          ]
        ,
          name: 'size'
          type: 'property'
          value:
            value: 'XL'
            type: 'string'
      ]
    reprDesc: 'object with properties ‘name’, then one of ‘xor1’ and ‘xor2’, and then ‘size’.'

  describe "doesn't implement ‘ref’ yet", test
    ast:
      ref: 'Another'
    errDesc: 'implemented'
