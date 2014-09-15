###
This is docstring documents BaseCrud. It can include *Markdown* syntax,
which will be converted to html.
###

class BaseCrud
  createError: (method) ->
    error = new Error "Unimplemented #{method}"
    return error
    
  read: (BaseModelClazz, aFilter = [], sQuery = '', aSort = [], iOffset = 0, iLimit = 15, callback) =>
    callback @createError('read'), null, null, null
    return

  readOne: (BaseModelClazz, id, callback) ->
    callback @createError('readOne'), null
    return
    
  create: (BaseModelClazz, value, callback) ->
    callback @createError('create'), null
    return

  update: (BaseModelClazz, id, value, callback) ->
    callback @createError('update'), null
    return

  delete: (BaseModelClazz, id, callback) ->
    callback @createError('delete'), null
    return

  deleteAll: (BaseModelClazz, callback) ->
    callback @createError('deleteAll'), null
    return

exports.BaseCrud = BaseCrud

