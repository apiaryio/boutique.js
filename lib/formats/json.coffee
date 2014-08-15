

module.exports =
  representObject: (properties) ->
    joined = properties.join ','
    "{#{joined}}"

  representObjectProperty: (name, value) ->
    "\"#{name}\":#{value}"

  representArray: (elements) ->
    joined = elements.join ','
    "[#{joined}]"

  representString: (value) ->
    JSON.stringify value

  representNumber: (value) ->
    value

  representBool: (value) ->
    value = !!JSON.parse value
    JSON.stringify value

  representNull: ->
    "null"
