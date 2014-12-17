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
  describe "on Named Type node", ->
    testTypeResolution "if given with explicit type",
      astTreeNode:
        base:
          typeSpecification:
            name:
              name: 'object'
      typeName: 'object'

    testTypeResolution "if given with ‘array’ type and some nested types",
      astTreeNode:
        base:
          typeSpecification:
            name:
              name: 'array'
            nestedTypes: [
                name: 'string'
              ,
                name: 'number'
            ]
      typeName: 'array'
      nestedTypes: ['string', 'number']

    testTypeResolution "if given with ‘enum’ type and some nested types",
      astTreeNode:
        base:
          typeSpecification:
            name:
              name: 'enum'
            nestedTypes: [
                name: 'string'
              ,
                name: 'number'
            ]
      typeName: 'enum'
      nestedTypes: ['string', 'number']

    testTypeResolution "if given with nested types for type other than ‘array’ or ‘enum’",
      astTreeNode:
        base:
          typeSpecification:
            name:
              name: 'string'
            nestedTypes: [
                name: 'string'
              ,
                name: 'number'
            ]
      errContains: 'array and enum'

    testTypeResolution "if given with member sections and with no explicit type",
      astTreeNode:
        sections: [
            type: 'member'
          ,
            type: 'member'
        ]
      typeName: 'object'

    testTypeResolution "if given with no explicit type",
      astTreeNode: {}
      typeName: 'string'

    testTypeResolution "if given with type, which is not base type",
      astTreeNode:
        base:
          typeSpecification:
            name:
              name: 'Human'
      errContains: 'Human'

  describe "on Value Member (or Property Member) node", ->
    testTypeResolution "if given with explicit type",
      astTreeNode:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name:
                name: 'number'
      typeName: 'number'

    testTypeResolution "if given with ‘array’ type and some nested types",
      astTreeNode:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name:
                name: 'array'
              nestedTypes: [
                  name: 'string'
                ,
                  name: 'boolean'
              ]
      typeName: 'array'
      nestedTypes: ['string', 'boolean']

    testTypeResolution "if given with ‘enum’ type and some nested types",
      astTreeNode:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name:
                name: 'enum'
              nestedTypes: [
                  name: 'string'
                ,
                  name: 'boolean'
              ]
      typeName: 'enum'
      nestedTypes: ['string', 'boolean']

    testTypeResolution "if given with nested types for type other than ‘array’ or ‘enum’",
      astTreeNode:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name:
                name: 'string'
              nestedTypes: [
                  name: 'string'
                ,
                  name: 'boolean'
              ]
      errContains: 'array and enum'

    testTypeResolution "if given with member sections and with no explicit type",
      astTreeNode:
        sections: [
            type: 'member'
          ,
            type: 'member'
        ]
      typeName: 'object'

    testTypeResolution "if given with no explicit type",
      astTreeNode: {}
      typeName: 'string'

    testTypeResolution "if given with multiple values and with no explicit type",
      astTreeNode:
        valueDefinition:
          values: [
              literal: 'home'
            ,
              literal: 'green'
          ]
      typeName: 'array'

    testTypeResolution "if given with member sections and multiple values and with no explicit type",
      astTreeNode:
        valueDefinition:
          values: [
              literal: 'home'
            ,
              literal: 'green'
          ]
        sections: [
          type: 'member'
        ]
      errContains: 'ambiguous'

    testTypeResolution "if given with type, which is not base type",
      astTreeNode:
        valueDefinition:
          typeDefinition:
            typeSpecification:
              name:
                name: 'Person'
      errContains: 'Person'
