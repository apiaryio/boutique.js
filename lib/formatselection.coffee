
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
  needleParts = needle.parts or {}

  for contentType in haystack
    contentTypeParts = contentType.parts or {}
    candidate = contentType.string

    if needleParts.suffix is contentTypeParts.subtype
      # this means `image/svg+xml` will eventually match with `application/xml`
      candidates.push candidate

    if needleParts.type isnt contentTypeParts.type
      continue
    if needleParts.subtype isnt contentTypeParts.subtype
      continue
    if needleParts.suffix isnt contentTypeParts.suffix
      continue
    if contentTypeParts.parameters?.profile? and needleParts.parameters?.profile isnt contentTypeParts.parameters?.profile
      continue

    return cb null, candidate

  cb null, candidates?[0]  # or undefined in case there's absolutely no match


selectFormat = (needle, haystack, cb) ->
  # shortcut for simple cases
  return (cb null, needle) if needle in haystack

  async.parallel [
    (next) -> parse needle, next  # parse the needle Content-Type
    (next) -> async.map haystack, parse, next  # parse each of haystack Content-Types
  ], (err, [needle, haystack]) ->
    return cb err if err

    # both needle and haystack are now transformed
    # from strings to parsed objects
    findCandidates needle, haystack, cb


module.exports = {
  selectFormat
}
