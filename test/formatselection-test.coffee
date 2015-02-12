require 'mocha'
{assert} = require 'chai'

{selectFormat} = require '../src/formatselection'


describe "Format selection", ->
  describe "if content type matches exactly with one of formats", ->
    format = undefined
    formats = [
      'application/json'
      'application/xml'
      'application/hal+json'
      'image/svg+xml; charset=utf-8'
    ]

    before (next) ->
      selectFormat 'application/hal+json', formats, (err, result) ->
        format = result
        next err

    it "selects the right format", ->
      assert.equal 'application/hal+json', format

  describe "if content type has ‘suffix’ matching with ‘type’ of one of formats", ->
    format = undefined
    formats = [
      'application/json'
      'application/xml'
      'image/svg+xml; charset=utf-8'
    ]

    before (next) ->
      selectFormat 'application/hal+json', formats, (err, result) ->
        format = result
        next err

    it "selects the right format", ->
      assert.equal 'application/json', format

  describe "if content type has ‘suffix’ matching with ‘type’ of one of formats", ->
    format = undefined
    formats = [
      'application/json'
      'application/xml; charset=utf-8'
      'application/hal+json'
    ]

    before (next) ->
      selectFormat 'image/svg+xml; foo=bar', formats, (err, result) ->
        format = result
        next err

    it "selects the right format, ignoring the parameters", ->
      assert.equal 'application/xml; charset=utf-8', format

  describe "if matches can be distinguished only by ‘profile’ parameter", ->
    format = undefined
    formats = [
      'application/json; profile="http://example.com/schema"'
      'application/json; profile="http://example.com/draft-03/schema"'
      'application/hal+json'
      'application/json; profile="http://example.com/draft-04/schema"'
    ]

    before (next) ->
      selectFormat 'application/json; profile="http://example.com/draft-03/schema"; foo=bar', formats, (err, result) ->
        format = result
        next err

    it "selects the format with the same ‘profile’ parameter", ->
      assert.equal 'application/json; profile="http://example.com/draft-03/schema"', format

  describe "if matches can be distinguished only by ‘profile’ parameter, but content type doesn't have one", ->
    format = undefined
    formats = [
      'application/foo; profile="http://example.com/schema"'
      'application/foo; profile="http://example.com/draft-03/schema"'
    ]

    before (next) ->
      selectFormat 'application/foo', formats, (err, result) ->
        format = result
        next err

    it "returns falsy value", ->
      assert.notOk format

  describe "if matches can be distinguished only by existence of ‘profile’ parameter", ->
    format = undefined
    formats = [
      'application/foo; profile="http://example.com/schema"'
      'application/foo'
      'application/foo; profile="http://example.com/draft-03/schema"'
    ]

    before (next) ->
      selectFormat 'application/foo', formats, (err, result) ->
        format = result
        next err

    it "selects the right format", ->
      assert.equal 'application/foo', format

  describe "if content type has ‘profile’, but no related format specifies ‘profile’", ->
    format = undefined
    formats = [
      'application/json'
      'application/hal+json'
    ]

    before (next) ->
      selectFormat 'application/hal+json; profile="http://example.com/draft-03/schema"; foo=bar', formats, (err, result) ->
        format = result
        next err

    it "selects the right format, ignoring the parameters", ->
      assert.equal 'application/hal+json', format

  describe "if there is no match", ->
    format = undefined
    formats = [
      'application/json'
      'application/hal+json'
    ]

    before (next) ->
      selectFormat 'image/svg+xml; foo=bar', formats, (err, result) ->
        format = result
        next err

    it "returns falsy value", ->
      assert.notOk format

  describe "if erroneous content type is given as needle", ->
    error = undefined
    formats = [
      'application/json'
    ]

    before (next) ->
      selectFormat 'application/xml; profile=http://localhost', formats, (err) ->
        error = err
        next()

    it "results with an error", ->
      assert.ok error

  describe "if erroneous content type is given as part of haystack", ->
    error = undefined
    formats = [
      'application/json; profile=http://localhost'
    ]

    before (next) ->
      selectFormat 'application/xml', formats, (err) ->
        error = err
        next()

    it "results with an error", ->
      assert.ok error
