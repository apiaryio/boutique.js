
typer = require 'media-typer'


selectFormat = (contentType, formats) ->
  # shortcut for simple cases
  return contentType[contentType] if contentType[contentType]

  contentTypeParts = typer.parse contentType
  candidates = []

  for own formatContentType, lib of formats
    formatContentTypeParts = typer.parse formatContentType

    if contentTypeParts.suffix is formatContentTypeParts.subtype
      # this means `image/svg+xml` will eventually match with `application/xml`
      candidates.push lib

    if contentTypeParts.type isnt formatContentTypeParts.type
      continue
    if contentTypeParts.subtype isnt formatContentTypeParts.subtype
      continue
    if contentTypeParts.suffix isnt formatContentTypeParts.suffix
      continue
    # ignoring `.parameters` for now

    return lib

  return candidates?[0]  # or undefined in case there's absolutely no match


module.exports = {
  selectFormat
}
