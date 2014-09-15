###
This docstring documents BaseClientApi. It can include *Markdown* syntax,
which will be converted to html.
###


_ = require 'underscore'
{ Utils } = require './utils'


class BaseClientApi
  createError: (method) ->
    error = new Error "Unimplemented #{method}"
    return error
    
  setReq: (req) =>
    @req = req
    return
    
  getFilter: =>
    throw @createError('getFilter')
    return
    
  getQuery: =>
    throw @createError('getQuery')
    return
  
  getSort: =>
    throw @createError('getSort')
    return
  
  getGroup: =>
    throw @createError('getGroup')
    return
    
  getOffset: =>
    throw @createError('getOffset')
    return
  
  getLimit: =>
    throw @createError('getLimit')
    return
    
  getTableName: =>
    return Utils.firstUpperCase(@req.params.collection)
    
  getRecordId: ->
    return @req.params.id
    
  getPostValue: =>
    return @req.body
    
  checkReqParamsOk: =>
    result = ''

    databaseName = @req.params.database
    collectionName = @req.params.collection

    if not databaseName?
      result = 'Database name Undefined'

    if not collectionName?
      result  = 'Collection name Undefined'

    return result


exports.BaseClientApi = BaseClientApi  


