
fs = require 'fs'
path = require 'path'
async = require 'async'

try
  protagonist = require 'protagonist'
catch
  console.error "You need to install the latest Protagonist first by running 'npm install protagonist-experimental'."
  process.exit 1


formatsDir = path.resolve __dirname, '..', 'test', 'formats'
msonSamplesDir = path.resolve formatsDir, 'samples-mson'
astSamplesDir = path.resolve formatsDir, 'samples-ast'


parse = (mson, cb) ->
  # Dummy API Blueprint
  blueprint = """
    # Name [/]

    + Attributes
        #{mson}
  """
  protagonist.parse blueprint, (err, result) ->
    ast = result?.ast?.resourceGroups?[0]?.resources?[0]?.attributes?.source
    cb err, ast


generate = (filename, cb) ->
  async.waterfall [
      (next) ->
        msonPath = path.resolve msonSamplesDir, filename
        fs.readFile msonPath, (err, data) ->
          next err, (data.toString() if data)
    ,
      parse
    ,
      (ast, next) ->
        basename = path.basename filename, path.extname filename
        astPath = path.resolve astSamplesDir, "#{basename}.json"

        data = JSON.stringify ast, undefined, 2
        fs.writeFile astPath, data, next

  ], (err) ->
    console.error "Sample '#{filename}' couldn't be parsed: #{err.message}" if err
    cb null, not err


main = ->
  async.waterfall [
      (next) ->
        fs.readdir msonSamplesDir, next
    ,
      (filenames, next) ->
        async.map filenames, generate, (err, results) ->
          if not err and false in results
            err = new Error 'Generation of some samples was unsuccessful.'
          next err

  ], (err) ->
    process.exit 1 if err


main()
