{assert} = require 'chai'

{Boutique} = require '../lib/boutique'


callRepresent = (boutique, ast, cb) ->
  boutique.represent ast, (err, body) ->
    cb err, body


callHandleElement = (boutique, ast, cb) ->
  try
    cb null, boutique.handleElement ast
  catch err
    cb err, null


createTest = (format, call, parse) ->
  if not call then call = callRepresent
  if not parse then parse = (body) ->
    try
      JSON.parse body
    catch e
      e.message += " (Unable to parse: #{body})"
      throw e

  ({ast, repr, reprDesc, errDesc, options}) ->
    ->
      boutique = new Boutique format, options

      err = undefined
      body = undefined

      before (next) ->
        call boutique, ast, ->
          [err, body] = arguments
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
          assert.deepEqual parse(body), repr


module.exports = {
  callRepresent
  callHandleElement
  createTest
}
