
typer = require 'media-typer'


selectFormat = (needle, haystack) ->
  # shortcut for simple cases
  return needle if needle in haystack

  needleParts = typer.parse needle
  candidates = []

  for contentType in haystack
    contentTypeParts = typer.parse contentType

    if needleParts.suffix is contentTypeParts.subtype
      # this means `image/svg+xml` will eventually match with `application/xml`
      candidates.push contentType

    if needleParts.type isnt contentTypeParts.type
      continue
    if needleParts.subtype isnt contentTypeParts.subtype
      continue
    if needleParts.suffix isnt contentTypeParts.suffix
      continue
    # ignoring `.parameters` for now

    return contentType

  return candidates?[0]  # or undefined in case there's absolutely no match


module.exports = {
  selectFormat
}
