
{Boutique} = require './lib/boutique.coffee'
{selectFormat} = require './lib/formatselection.coffee'


defaultFormats =
  'application/json': require './lib/formats/json.coffee'


represent = (ast, contentType, cb) ->
  format = selectFormat contentType, defaultFormats
  if not format
    cb new Error "Unknown format '#{contentType}'."
  else
    rep = new Boutique format
    rep.represent ast, cb


module.exports = {
  defaultFormats
  selectFormat
  Boutique
  represent
}
