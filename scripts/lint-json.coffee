
fs = require 'fs'
path = require 'path'
async = require 'async'


formatsDir = path.resolve __dirname, '..', 'test', 'formats'
jsonDirs = [
  path.resolve formatsDir, 'samples-json-schema-v4'
]


# Reads a file with JSON and checks whether it's valid JSON.
checkJsonFile = (jsonPath, cb) ->
  fs.readFile jsonPath, (err, data) ->
    cb err if err
    try
      JSON.parse data.toString()
      cb null
    catch err
      cb new Error "#{jsonPath}: #{err.message}"


# Checks whether all `.json` files in given directory contain
# valid JSONs.
checkJsonDir = (jsonDir, cb) ->
  fs.readdir jsonDir, (err, filenames) ->
    jsonFilenames = (f for f in filenames when f.match /\.json$/)
    async.forEach jsonFilenames, (filename, next) ->
      jsonPath = path.resolve jsonDir, filename
      checkJsonFile jsonPath, next
    , cb


main = ->
  async.forEach jsonDirs, checkJsonDir, (err) ->
    if err
      console.error "[JSON Lint] #{err.message}"
      process.exit 1


main()
