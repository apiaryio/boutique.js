require 'mocha'
{assert} = require 'chai'

{Boutique} = require '../lib/boutique'


createDescribe = (format) ->
  (description, {ast, repr, reprDesc, errDesc}) ->
    describe description, ->
      boutique = new Boutique format

      err = undefined
      result = undefined

      before (next) ->
        boutique.represent ast, ->
          [err, result] = arguments
          next()

      if errDesc
        it "fails on error, which contains words ‘#{errDesc}’", ->
          assert.ok err
          assert.include err.message, errDesc
      else
        it 'produces no error', ->
          assert.notOk err
        desc = "produces " + (reprDesc or "the right representation")
        it desc, ->
          assert.deepEqual result, repr


module.exports = {
  createDescribe
}
