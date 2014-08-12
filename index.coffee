typer = require 'media-typer'


defaultFormats =
  'application/json': require './formats/json.coffee'


selectFormat = (contentType, formats) ->
  if contentType in Object.keys formats
    return formats[contentType]  # shortcut for simple cases

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


# TODO:
# * this could yield representation in events together with errors
# * ...or it could implement the 'stream' thingy...?
# * representer should validate the AST
class Boutique

  constructor: (@format, options) ->
    @skipOptional = options?.skipOptional ? true
    @skipTemplated = options?.skipTemplated ? true

  # Traverses the AST tree and returns its complete representation.
  represent: (ast) ->
    r = @handleElement ast

  handleElement: (element) ->
    if element.primitive?
      prim = element.primitive

      if not prim.type or not prim.value
        # TODO we don't know either type or the value
        # - should we skip the property?
        return null
      # TODO and what about having only one of them?
      if prim.type is 'object'
        @format.representObject @handleProperties prim.value
      else if prim.type is 'array'
        @format.representArray (
          @handleElement elem for elem in prim.value
        )
      else if prim.type is 'string'
        @format.representString prim.value
      else if prim.type is 'number'
        @format.representNumber prim.value
      else if prim.type in ['bool', 'boolean']
        @format.representBool prim.value
      else
        # TODO we don't know the type
        # - should we imply string or to skip the property?
        return null

    else if element?.oneOf?.length > 0
      @handleElement element.oneOf[0]  # choose the first one

    # TODO ref

  handleProperty: (property) ->
    @format.representObjectProperty property.name, @handleElement property

  handleProperties: (properties) ->
    represented = []
    for prop in properties
      if not prop.required and @skipOptional
        continue
      if prop.templated and @skipTemplated
        continue
      represented.push @handleProperty prop
    represented


represent = (ast, contentType, cb) ->
  format = selectFormat contentType, defaultFormats
  if not format
    cb new Error "Unknown format '#{contentType}'."
  else
    rep = new Boutique format
    cb null, rep.represent ast


module.exports = {
  defaultFormats
  selectFormat
  Boutique
  represent
}
