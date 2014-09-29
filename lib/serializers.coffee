
json = (obj, cb) ->
  try
    cb null, JSON.stringify obj
  catch e
    cb e


module.exports = {
  json
}
