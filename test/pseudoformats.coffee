
# pseudo-format to keep testing of the Boutique core
# as format-agnostic as it gets
pseudoFormat =
  representObject: (properties) ->
    repr = JSON.stringify type: 'object', value: '###'
    repr.replace '"###"', "[#{properties.join ','}]"
  representObjectProperty: (name, value) ->
    repr = JSON.stringify type: 'property', name: name, value: '###'
    repr.replace '"###"', value
  representArray: (elements) ->
    repr = JSON.stringify type: 'array', value: '###'
    repr.replace '"###"', "[#{elements.join ','}]"
  representString: (value) ->
    JSON.stringify type: 'string', value: value.toString()
  representNumber: (value) ->
    JSON.stringify type: 'number', value: value.toString()
  representBool: (value) ->
    JSON.stringify type: 'bool', value: value.toString()
  representNull: ->
    JSON.stringify type: 'null'


# another pseudo-format, with its own implementation of oneOf
pseudoFormatWithOneOf =
  representOneOfElements: (elements) ->
    repr = JSON.stringify type: 'oneOfElements', value: '###'
    repr.replace '"###"', "[#{elements.join ','}]"
  representOneOfProperties: (properties) ->
    repr = JSON.stringify type: 'oneOfProperties', value: '###'
    repr.replace '"###"', "[#{properties.join ','}]"

for name, fn of pseudoFormat
  pseudoFormatWithOneOf[name] = fn


module.exports = {
  pseudoFormat
  pseudoFormatWithOneOf
}
