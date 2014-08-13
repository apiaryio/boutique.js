require 'mocha'
{assert} = require 'chai'

boutique = require '../index.coffee'


describe 'Boutique', ->

  describe 'can give JSON representation of MSON AST', ->
    contentType = 'application/json'
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

    err = undefined
    body = undefined

    before (next) ->
      boutique.represent ast, contentType, () ->
        [err, body] = arguments
        next()

    it 'produces no error', ->
      assert.notOk err

    it 'produces the right body', ->
      json = JSON.parse body
      assert.deepEqual json,
        id: 1
