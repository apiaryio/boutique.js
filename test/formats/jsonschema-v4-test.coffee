require 'mocha'

{createDescribe} = require '../testutils'
{Format} = require '../../lib/formats/jsonschema-v4'


describe "JSON Schema v4 format", ->
  boutique = createDescribe Format

  boutique "handles basic MSON AST",
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
      properties:
        id:
          type: 'number'
          description: 'The unique identifier for a product'
      required: ['id']
      additionalProperties: false
    reprDesc: 'schema with ‘object’ type having one required string property of name ‘id’ and no additional properties'

  boutique "handles empty MSON AST given as empty object",
    ast: {}
    repr: {}
    reprDesc: 'empty schema'

  boutique "handles empty MSON AST given as ‘null’",
    ast: null
    repr: {}
    reprDesc: 'empty schema'

  boutique "properly handles an element without neither type or example value",
    ast:
      description: 'Dummy description'
    repr:
      description: 'Dummy description'
    reprDesc: 'empty schema (with description only)'

  boutique "properly handles simple value without type as ‘string’",
    ast:
      primitive:
        value: '123'
    repr:
      type: 'string'
    reprDesc: 'schema with ‘string’ type'

  boutique "properly handles complex value without type as ‘object’",
    ast:
      primitive:
        value: [
          name: 'name'
          primitive:
            value: 'Gargamel'
        ]
    repr:
      type: 'object'
      properties:
        name:
          type: 'string'
      additionalProperties: false
    reprDesc: 'schema with ‘object’ type having one property of name ‘name’'

  boutique "properly handles an element with type, but without value",
    ast:
      description: 'Something'
      primitive:
        type: 'number'
    repr:
      description: 'Something'
      type: 'number'
    reprDesc: 'schema with ‘number’ type'

  boutique "properly handles ‘string’",
    ast:
      description: 'Something'
      primitive:
        type: 'string'
        value: 'Dummy value'
    repr:
      description: 'Something'
      type: 'string'
    reprDesc: 'schema with ‘string’ type'

  boutique "properly handles ‘number’",
    ast:
      description: 'Something'
      primitive:
        type: 'number'
        value: '1.2'
    repr:
      description: 'Something'
      type: 'number'
    reprDesc: 'schema with ‘number’ type'

  boutique "properly handles ‘bool’",
    ast:
      description: 'Something'
      primitive:
        type: 'bool'
        value: 'true'
    repr:
      description: 'Something'
      type: 'boolean'
    reprDesc: 'schema with ‘boolean’ type'

  boutique "properly handles ‘boolean’",
    ast:
      description: 'Something'
      primitive:
        type: 'boolean'
        value: 'true'
    repr:
      description: 'Something'
      type: 'boolean'
    reprDesc: 'schema with ‘boolean’ type'

  boutique "properly handles ‘array’",
    ast:
      description: 'Something'
      primitive:
        type: 'array'
        value: [
            primitive:
              type: 'string'
              value: 'h2g2'
          ,
            description: 'Something else'
            primitive:
              type: 'number'
              value: '42'
        ]
    repr:
      description: 'Something'
      type: 'array'
      items: [
          type: 'string'
        ,
          description: 'Something else'
          type: 'number'
      ]
    reprDesc: 'schema for array containing two elements: string and number'

  boutique "properly handles ‘object’",
    ast:
      description: 'Something'
      primitive:
        type: 'object'
        value: [
            name: 'abbr'
            primitive:
              type: 'string'
              value: 'h2g2'
          ,
            description: 'Something else'
            name: 'id'
            primitive:
              type: 'number'
              value: '42'
        ]
    repr:
      description: 'Something'
      type: 'object'
      properties:
        abbr:
          type: 'string'
        id:
          description: 'Something else'
          type: 'number'
      additionalProperties: false
    reprDesc: 'schema for object containing two properties: string ‘abbr’ and number ‘id’'

  boutique "properly handles required properties",
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
      properties:
        id:
          description: 'The unique identifier of an employee'
          type: 'number'
        name:
          description: 'Name of the employee'
          type: 'string'
      required: ['id']
      additionalProperties: false
    reprDesc: 'schema for object with one required property of name ‘id’ and one optional property of name ‘name’'

  boutique "properly handles templated properties",
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
      properties:
        id:
          description: 'The unique identifier of an employee'
          type: 'number'
      required: ['id']
    reprDesc: 'object with one required property of name ‘id’ and allowed additional properties'

  boutique "properly handles ‘oneOf’ on array elements",
    ast:
      primitive:
        type: 'array'
        value: [
            primitive:
              type: 'number'
              value: '1'
          ,
            oneOf: [
              primitive:
                type: 'number'
                value: '42'
            ,
              primitive:
                type: 'string'
                value: 'hello'
          ]
        ]
    repr:
      type: 'array'
      items: [
          type: 'number'
        ,
          oneOf: [
              type: 'number'
            ,
              type: 'string'
          ]
      ]
    reprDesc: 'array with element ‘1’ and one of ‘42’ or ‘hello’'
