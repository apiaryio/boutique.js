require 'mocha'
{assert} = require 'chai'

{selectFormat} = require '../lib/formatselection'


describe "Format selection", ->
  describe "if content type matches exactly with one of formats", ->
    format = undefined
    formats = [
      'application/json'
      'application/xml'
      'application/hal+json'
      'image/svg+xml; charset=utf-8'
    ]

    before ->
      format = selectFormat 'application/hal+json', formats

    it "selects the right format", ->
      assert.equal 'application/hal+json', format

  describe "if content type has ‘suffix’ matching with ‘type’ of one of formats", ->
    format = undefined
    formats = [
      'application/json'
      'application/xml'
      'image/svg+xml; charset=utf-8'
    ]

    before ->
      format = selectFormat 'application/hal+json', formats

    it "selects the right format", ->
      assert.equal 'application/json', format

  describe "if content type has ‘suffix’ matching with ‘type’ of one of formats", ->
    format = undefined
    formats = [
      'application/json'
      'application/xml; charset=utf-8'
      'application/hal+json'
    ]

    before ->
      format = selectFormat 'image/svg+xml; foo=bar', formats

    it "selects the right format, ignoring the parameters", ->
      assert.equal 'application/xml; charset=utf-8', format

  describe "if there is no match", ->
    format = undefined
    formats = [
      'application/json'
      'application/hal+json'
    ]

    before ->
      format = selectFormat 'image/svg+xml; foo=bar', formats

    it "returns falsy value", ->
      assert.notOk format
