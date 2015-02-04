require 'mocha'
{assert} = require 'chai'

{resolveType} = require '../lib/typeresolution'


testTypeResolution = (description, {astTreeNode, typeName, nestedTypes, errContains}) ->
  describe description, ->
    typeSpec = null
    err = null

    before (next) ->
      resolveType astTreeNode, ->
        [err, typeSpec] = arguments
        next (err unless errContains)

    if errContains
      it "results in an error with message containing ‘#{errContains}’", ->
        assert.include err.message.toLowerCase(), errContains.toLowerCase()
    else
      it "resolves ‘#{typeName}’ as the effective type", ->
        assert.equal typeName, typeSpec.name

      if nestedTypes
        quotedNames = nestedTypes.map (name) -> "‘#{name}’"
        joinedQuotedNames = quotedNames.join ' and '

        it "resolves #{joinedQuotedNames} as nested types", ->
          assert.deepEqual nestedTypes, typeSpec.nested


describe "Type resolution", ->
  testTypeResolution "if given with explicit type",
    astTreeNode:
      content:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name: 'number'
    typeName: 'number'

  testTypeResolution "if given with ‘array’ type and some nested types",
    astTreeNode:
      content:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name: 'array'
              nestedTypes: [
                'string'
                'boolean'
              ]
    typeName: 'array'
    nestedTypes: ['string', 'boolean']

  testTypeResolution "if given with ‘enum’ type and some nested types",
    astTreeNode:
      content:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name: 'enum'
              nestedTypes: [
                'string'
                'boolean'
              ]
    typeName: 'enum'
    nestedTypes: ['string', 'boolean']

  testTypeResolution "if given with nested types for type other than ‘array’ or ‘enum’",
    astTreeNode:
      content:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name: 'string'
              nestedTypes: [
                'string'
                'boolean'
              ]
    errContains: 'array and enum'

  testTypeResolution "if given with member sections and with no explicit type",
    astTreeNode:
      content:
        sections: [
            class: 'memberType'
          ,
            class: 'memberType'
        ]
    typeName: 'object'

  testTypeResolution "if given with no explicit type",
    astTreeNode:
      content: {}
    typeName: 'string'

  testTypeResolution "if given with multiple values and with no explicit type",
    astTreeNode:
      content:
        valueDefinition:
          values: [
              literal: 'home'
            ,
              literal: 'green'
          ]
    typeName: 'array'
    nestedTypes: ['string']

  testTypeResolution "if given ‘enum’ with multiple values and with no explicit nested type",
    astTreeNode:
      content:
        valueDefinition:
          values: [
              literal: 'home'
            ,
              literal: 'green'
          ]
          typeDefinition:
            typeSpecification:
              name: 'enum'
    typeName: 'enum'
    nestedTypes: ['string']

  testTypeResolution "if given with member sections and multiple values and with no explicit type",
    astTreeNode:
      content:
        valueDefinition:
          values: [
              literal: 'home'
            ,
              literal: 'green'
          ]
        sections: [
          class: 'memberType'
        ]
    errContains: 'ambiguous'

  testTypeResolution "if given with type, which is not base type",
    astTreeNode:
      content:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name: 'Person'
    errContains: 'Person'
