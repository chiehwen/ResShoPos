# check out https://github.com/visionmedia/node-pwd

###
 * Module dependencies.
###

crypto = require 'crypto'


# Bytesize.
len = 128

# Iterations. ~300ms
iterations = 12000

###
 * Hashes a password with optional `salt`, otherwise
 * generate a salt for `pass` and invoke `fn(err, salt, hash)`.
 *
 * @param {String} password to hash
 * @param {String} optional salt
 * @param {Function} callback
 * @api public
###

exports.hash = (pwd, salt, fn) ->
  if 3 is arguments.length
    try
      crypto.pbkdf2 pwd, salt, iterations, len, (err, hash) ->
        if err
          fn err, null
        else
          hash = hash.toString 'base64'
          fn null, hash
        return
    catch e
      fn e.toString(), null
  else
    fn = salt
    crypto.randomBytes len, (err, salt) ->
      if err
        return fn err
				
      salt = salt.toString 'base64'

      try
        crypto.pbkdf2 pwd, salt, iterations, len, (err, hash) ->
          if err
            return fn err
          hash = hash.toString 'base64'
          fn null, salt, hash
          return
      catch e
        fn e.toString(), null, null
      return
  return
