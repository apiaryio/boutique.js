# Generic utility functions


async = require 'async'


# Supplement to async.js. Returns result of the first successful function
# call on an item of given array.
#
# This function applies given function to every item in given array.
# If the function call results in error, the item is skipped. If the function
# call succeeds, its result is passed to given callback as the final result.
# In case no item passes through the function call successfully, the last
# issued error is passed to given callback.
detectSuccessful = (arr, fn, cb) ->
  error = null
  result = null

  async.detectSeries arr, (item, next) ->
    fn item, (err, res) ->
      [error, result] = if err then [err, null] else [null, res]
      next not err
  , ->
    cb error, result


module.exports = {
  detectSuccessful
}
