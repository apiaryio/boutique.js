
async = require 'async'
typer = require 'media-typer'


# Parses given Content-Type. Resulting object contains both the original string
# and the result of parsing.
parse = (contentType, cb) ->
  try
    cb null,
      string: contentType
      parts: typer.parse contentType
  catch err
    return cb new Error "Unable to parse Content-Type #{contentType}: #{err.message}"


# Takes parsed needle Content-Type and array of parsed Content-Types as haystack.
findCandidates = (needle, haystack, cb) ->
  candidates = []

  for contentType in haystack
    if needle.parts.suffix is contentType.parts.subtype
      # this means `image/svg+xml` will eventually match with `application/xml`
      candidates.push contentType.string

    if needle.parts.type isnt contentType.parts.type
      continue
    if needle.parts.subtype isnt contentType.parts.subtype
      continue
    if needle.parts.suffix isnt contentType.parts.suffix
      continue
    if contentType.parts.parameters?.profile? and needle.parts.parameters?.profile isnt contentType.parts.parameters?.profile
      continue

    return cb null, contentType.string

  cb null, candidates?[0]  # or undefined in case there's absolutely no match


selectFormat = (needle, haystack, cb) ->
  # shortcut for simple cases
  return (cb null, needle) if needle in haystack

  async.parallel [
      (next) ->  # parse the needle Content-Type
        parse needle, next
    ,
      (next) ->  # parse each of haystack Content-Types
        async.map haystack, parse, next

  ], (err, results) ->
    return cb err if err

    # both needle and haystack are now transformed
    # from strings to parsed objects
    findCandidates results[0], results[1], cb


module.exports = {
  selectFormat
}
