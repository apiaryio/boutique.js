require 'mocha'
{assert} = require 'chai'

boutique = require '../index'


describe "Main ‘represent(...)’ function", ->

  describe "when given a simple AST", ->
    ast =
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
    expected =
      id: 1
      name: 'Věroš'

    err = undefined
    repr = undefined
    contentType = undefined

    before (next) ->
      boutique.represent
        ast: ast
        contentType: 'application/hal+json'
      , ->
        [err, repr, contentType] = arguments
        next err

    it "representation is string", ->
      assert.equal 'string', typeof repr

    it "resulting content type is ‘application/json’", ->
      assert.equal 'application/json', contentType

    it "AST is represented correctly", ->
      assert.deepEqual expected, JSON.parse repr

  describe "when given a simple AST and format options are passed", ->
    ast =
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
    expected =
      id: 1

    err = undefined
    repr = undefined
    contentType = undefined

    before (next) ->
      boutique.represent
        ast: ast
        contentType: 'application/hal+json'
        options:
          skipOptional: true
      , ->
        [err, repr, contentType] = arguments
        next err

    it "representation is string", ->
      assert.equal 'string', typeof repr

    it "resulting content type is ‘application/json’", ->
      assert.equal 'application/json', contentType

    it "arguments are understood and AST is represented correctly", ->
      assert.deepEqual expected, JSON.parse repr

  describe "when given content type, which is not implemented", ->
    err = undefined

    before (next) ->
      boutique.represent
        ast: {}
        contentType: 'papa/smurf'
      , ->
        [err] = arguments
        next()

    it "error is returned", ->
      assert.ok err
