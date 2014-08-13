require 'mocha'
{assert} = require 'chai'

{selectFormat} = require '../lib/formatselection.coffee'


describe 'Format selection', ->
  describe 'if given Content-Type matches exactly', ->
    format = undefined
    formats =
      'application/json': 1
      'application/xml': 2
      'application/hal+json': 3
      'image/svg+xml; charset=utf-8': 4

    before ->
      format = selectFormat 'application/hal+json', formats
    it 'selects the right format', ->
      assert.equal 3, format

  describe 'if given Content-Type matches by suffix', ->
    format = undefined
    formats =
      'application/json': 1
      'application/xml': 2
      'image/svg+xml; charset=utf-8': 3

    before ->
      format = selectFormat 'application/hal+json', formats
    it 'selects the right format', ->
      assert.equal 1, format

  describe 'if given Content-Type matches by suffix', ->
    format = undefined
    formats =
      'application/json': 1
      'application/xml; charset=utf-8': 2
      'application/hal+json': 3

    before ->
      format = selectFormat 'image/svg+xml; foo=bar', formats
    it 'selects the right format, parameters are ignored', ->
      assert.equal 2, format

  describe 'if there is no match', ->
    format = undefined
    formats =
      'application/json': 1
      'application/hal+json': 2

    before ->
      format = selectFormat 'image/svg+xml; foo=bar', formats
    it 'returns falsy value', ->
      assert.notOk format
