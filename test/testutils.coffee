require 'mocha'
fs = require 'fs'
path = require 'path'
{assert} = require 'chai'

{Boutique} = require '../lib/boutique'


FORMATS_DIR = '../lib/formats'


iterFormats = () ->
  formats = []
  files = fs.readdirSync path.join __dirname, FORMATS_DIR

  for file in files when file isnt 'base.coffee'
    formatPath = path.join FORMATS_DIR, file
    {Format} = require formatPath

    formats.push
      class: Format
      name: path.basename file, '.coffee'

  formats


createDescribe = (Format) ->
  (description, {ast, repr, reprDesc, errDesc, options}) ->
    describe description, ->
      format = new Format options
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
  iterFormats
}
