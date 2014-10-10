
parseArguments = (passedArgs) ->
  args =
    ast: passedArgs[0]
    contentType: passedArgs[1]
    typeIdentifier: null
    options: null
    cb: null

  if typeof passedArgs[2] is 'function'
    # (ast, contentType, cb)
    args.cb = passedArgs[2]

  else if typeof passedArgs[2] is 'string'
    # (ast, contentType, typeIdentifier, ...)
    args.typeIdentifier ?= passedArgs[2]

    if typeof passedArgs[3] is 'function'
      # (ast, contentType, typeIdentifier, cb)
      args.cb = passedArgs[3]
    else
      # (ast, contentType, typeIdentifier, options, cb)
      args.options = passedArgs[3]
      args.cb = passedArgs[4]

  else
    # (ast, contentType, options, cb)
    args.options = passedArgs[2]
    args.cb = passedArgs[3]

  args.options ?= {}
  args


module.exports = {
  parseArguments
}
