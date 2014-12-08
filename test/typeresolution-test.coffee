require 'mocha'
{assert} = require 'chai'

{resolveType} = require '../lib/typeresolution'


describe "Type resolution", ->
  describe "if given Named Type with ‘object’ base type", ->
    typeSpec = null
    astTreeNode =
      name:
        name: 'Person'
      base:
        typeSpecification:
          name:
            name: 'object'

    before (next) ->
      resolveType astTreeNode, (err, result) ->
        typeSpec = result
        next err

    it "resolves ‘object’ as the effective type", ->
      assert.equal 'object', typeSpec.name

  describe "if given Named Type with ‘array’ base type and some nested types", ->
    typeSpec = null
    astTreeNode =
      name:
        name: 'Some Elements'
      base:
        typeSpecification:
          name:
            name: 'array'
          nestedTypes: [
              name: 'string'
            ,
              name: 'number'
          ]

    before (next) ->
      resolveType astTreeNode, (err, result) ->
        typeSpec = result
        next err

    it "resolves ‘array’ as the effective type", ->
      assert.equal 'array', typeSpec.name
    it "resolves ‘string’ and ‘number’ as nested types", ->
      assert.deepEqual ['string', 'number'], typeSpec.nested

  describe "if given Named Type with no explicit base type", ->
    error = null
    astTreeNode =
      name:
        name: 'Person'

    before (next) ->
      resolveType astTreeNode, (err) ->
        error = err
        next null

    it "results in an error", ->
      assert.include error.message, 'type information missing'

  describe "if given Named Type with type, which is not primitive", ->
    error = null
    astTreeNode =
      name:
        name: 'Person'
      base:
        typeSpecification:
          name:
            name: 'Human'

    before (next) ->
      resolveType astTreeNode, (err) ->
        error = err
        next null

    it "results in an error", ->
      assert.include error.message, 'Human'

  describe "if given Value Member with ‘number’ base type", ->
    typeSpec = null
    astTreeNode =
      valueDefinition:
        typeDefinition:
          typeSpecification:
            name:
              name: 'number'

    before (next) ->
      resolveType astTreeNode, (err, result) ->
        typeSpec = result
        next err

    it "resolves ‘number’ as the effective type", ->
      assert.equal 'number', typeSpec.name

  describe "if given Value Member with ‘enum’ base type and some nested types", ->
    typeSpec = null
    astTreeNode =
      valueDefinition:
        typeDefinition:
          typeSpecification:
            name:
              name: 'enum'
            nestedTypes: [
                name: 'string'
              ,
                name: 'boolean'
            ]

    before (next) ->
      resolveType astTreeNode, (err, result) ->
        typeSpec = result
        next err

    it "resolves ‘enum’ as the effective type", ->
      assert.equal 'enum', typeSpec.name
    it "resolves ‘string’ and ‘boolean’ as nested types", ->
      assert.deepEqual ['string', 'boolean'], typeSpec.nested

  describe "if given Value Member with no explicit type", ->
    error = null
    astTreeNode =
      valueDefinition:
        typeDefinition:
          typeSpecification:
            name:
              name: null

    before (next) ->
      resolveType astTreeNode, (err) ->
        error = err
        next null

    it "results in an error", ->
      assert.include error.message, 'type information missing'

  describe "if given Value Member with type, which is not primitive", ->
    error = null
    astTreeNode =
      valueDefinition:
        typeDefinition:
          typeSpecification:
            name:
              name: 'Person'

    before (next) ->
      resolveType astTreeNode, (err) ->
        error = err
        next null

    it "results in an error", ->
      assert.include error.message, 'Person'
