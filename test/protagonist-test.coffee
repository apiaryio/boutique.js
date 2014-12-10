require 'mocha'
{assert} = require 'chai'
protagonist = require 'protagonist'


describe "Protagonist", ->
  ast = null

  before (next) ->
    protagonist.parse '# My API', (err, result) ->
      ast = result?.ast
      next err

  it "works", ->
    assert.ok ast
