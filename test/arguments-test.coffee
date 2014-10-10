require 'mocha'
{assert} = require 'chai'

{parseArguments} = require '../lib/arguments'


describe "Arguments parsing for main ‘represent(...)’ function", ->
  describe "handles (ast, contentType, cb) signature", ->
    args = undefined
    passedArgs = [{types: {}}, 'application/json', -> ]

    before ->
      args = parseArguments passedArgs

    it "produces AST", ->
      assert.equal passedArgs[0], args.ast

    it "produces contentType", ->
      assert.equal passedArgs[1], args.contentType

    it "produces callback", ->
      assert.equal passedArgs[2], args.cb

    it "produces empty type identifier", ->
      assert.notOk args.typeIdentifier

    it "produces empty options object", ->
      assert.deepEqual {}, args.options

  describe "handles (ast, contentType, options, cb) signature", ->
    args = undefined
    passedArgs = [{types: {}}, 'application/json', {option: true}, -> ]

    before ->
      args = parseArguments passedArgs

    it "produces AST", ->
      assert.equal passedArgs[0], args.ast

    it "produces contentType", ->
      assert.equal passedArgs[1], args.contentType

    it "produces options object", ->
      assert.deepEqual passedArgs[2], args.options

    it "produces callback", ->
      assert.equal passedArgs[3], args.cb

    it "produces empty type identifier", ->
      assert.notOk args.typeIdentifier

  describe "handles (ast, contentType, typeIdentifier, cb) signature", ->
    args = undefined
    passedArgs = [{types: {}}, 'application/json', 'Person', -> ]

    before ->
      args = parseArguments passedArgs

    it "produces AST", ->
      assert.equal passedArgs[0], args.ast

    it "produces contentType", ->
      assert.equal passedArgs[1], args.contentType

    it "produces type identifier", ->
      assert.equal passedArgs[2], args.typeIdentifier

    it "produces callback", ->
      assert.equal passedArgs[3], args.cb

    it "produces empty options object", ->
      assert.deepEqual {}, args.options

  describe "handles (ast, contentType, typeIdentifier, options, cb) signature", ->
    args = undefined
    passedArgs = [{types: {}}, 'application/json', 'Person', {option: true}, -> ]

    before ->
      args = parseArguments passedArgs

    it "produces AST", ->
      assert.equal passedArgs[0], args.ast

    it "produces contentType", ->
      assert.equal passedArgs[1], args.contentType

    it "produces type identifier", ->
      assert.equal passedArgs[2], args.typeIdentifier

    it "produces options object", ->
      assert.deepEqual passedArgs[3], args.options

    it "produces callback", ->
      assert.equal passedArgs[4], args.cb
