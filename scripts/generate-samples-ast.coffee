
fs = require 'fs'
path = require 'path'
async = require 'async'

try
  protagonist = require 'protagonist-experimental'
catch
  console.error "You need to install the latest Protagonist first by running 'npm install protagonist-experimental'."
  process.exit 1


formatsDir = path.resolve __dirname, '..', 'test', 'formats'
msonSamplesDir = path.resolve formatsDir, 'samples-mson'
astSamplesDir = path.resolve formatsDir, 'samples-ast'


# Parses given MSON and passes resulting AST to the callback.
parse = (topLevelName, mson, cb) ->
  indentedMson = ("    #{line}" for line in mson.split '\n').join '\n'

  # Dummy API Blueprint
  blueprint = """
    # #{topLevelName} [/]

    + Attributes
    #{indentedMson}
  """

  protagonist.parse blueprint, (err, result) ->
    ast = result?.ast?.resourceGroups?[0]?.resources?[0]?.attributes?.source
    cb err, ast


# Reads MSON file on location specified by filename argument. Contents are
# provided to callback as string.
readMsonFile = (filename, cb) ->
  msonPath = path.resolve msonSamplesDir, filename
  fs.readFile msonPath, (err, data) ->
    cb err, (data.toString() if data)


# Writes AST file corresponding to given MSON filename. Contents are written
# as stringified and "prettified" JSON.
writeAstFile = (filename, ast, cb) ->
  basename = path.basename filename, path.extname filename
  astPath = path.resolve astSamplesDir, "#{basename}.json"

  data = JSON.stringify ast, undefined, 2
  fs.writeFile astPath, data, cb


# Generates AST version of given MSON file.
generate = (filename, cb) ->
  async.waterfall [
    (next) -> readMsonFile filename, next
    (mson, next) -> parse filename, mson, next
    (ast, next) -> writeAstFile filename, ast, next
  ], cb


# Generates AST versions of given MSON files. Encountered errors are reported
# to stderr and aggregated to an error object passed to callback function;
# they do not break the loop.
generateMany = (filenames, cb) ->
  async.map filenames, (filename, next) ->
    generate filename, (err) ->
      # we don't want to stop the loop on error, so we pass no error and we record
      # unsuccessful generation by providing 'false' result
      console.error "Sample '#{filename}' couldn't be parsed: #{err.message}" if err
      next null, not err

  , (err, successFlags) ->
    if not err and false in successFlags
      cb new Error 'Generation of some samples was unsuccessful.'
    else
      cb err


main = ->
  async.waterfall [
    (next) -> fs.readdir msonSamplesDir, next
    generateMany
  ], (err) ->
    if err
      console.error err.message
      process.exit 1


main()
