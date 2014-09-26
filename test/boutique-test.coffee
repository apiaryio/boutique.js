require 'mocha'

{createDescribe} = require './testutils'


FORMATS_TO_TEST =
  '../lib/formats/json': 'JSON'


for formatPath, formatName of FORMATS_TO_TEST
  # Core Boutique tests. Should test features of Boutique itself,
  # traversal algorithms, etc. Tested with every available format.

  describe "Core Boutique (tested with ‘#{formatName}’)", ->
    boutique = createDescribe require(formatPath).Format

    boutique "ensures that ‘primitive’ and ‘oneOf’ are mutually exclusive",
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
        oneOf: [
            primitive:
              type: 'number'
              value: '0'
          ,
            primitive:
              type: 'number'
              value: '1'
        ]
      errDesc: 'mutually exclusive'

    boutique "ensures that ‘primitive’ and ‘ref’ are mutually exclusive",
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
        ref: 'Something'
      errDesc: 'mutually exclusive'

    boutique "ensures that ‘ref’ and ‘oneOf’ are mutually exclusive",
      ast:
        oneOf: [
            primitive:
              type: 'number'
              value: '0'
          ,
            primitive:
              type: 'number'
              value: '1'
        ]
        ref: 'Something'
      errDesc: 'mutually exclusive'

    boutique "doesn't implement ‘ref’ yet",
      ast:
        ref: 'Another'
      errDesc: 'implemented'
