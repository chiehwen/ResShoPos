###
# CoffeeDoc example documentation #

This is a module-level docstring, and will be displayed at the top of the module documentation.
Documentation generated by [CoffeeDoc](http://github.com/omarkhan/coffeedoc)
###

_ = require 'underscore'
{ EventEmitter } = require 'events'
{ Utils } = require './utils'
{ hash } = require('./pass')

{ userCan } = require './routing-config'

class CrudApi extends EventEmitter
  dbProvider: null
  clientApi: null
  crudOperation: null
  
  constructor: (@dbProvider, @clientApi, @crudOperation) ->
    Utils.logInfo 'Crud API constructed'
    return

  query: (req, res) =>
    
    actionName = 'read'
    actionDesc = 'Querying'
    
    @tryAction req, res, actionName, actionDesc, =>
      aFilter = @clientApi.getFilter()
      sQuery = @clientApi.getQuery()
      aSort = @clientApi.getSort()
      aGroup = @clientApi.getGroup()
      iOffset = @clientApi.getOffset()
      iLimit = @clientApi.getLimit()
      return [aFilter, sQuery, aSort, aGroup, iOffset, iLimit]
    
    return

  generateHashSalt: (value, id, callback) ->
    password = value.password
    if not password? or password is ''
      password = '123456'

    hash password, (err, salt, hash) ->
      if err
        Utils.logInfo 'Generate hash and salt - error:', err
        value.hash = 'hash'
        value.salt = 'salt'
      else
        Utils.logInfo 'Generate hash and salt - successed'
        value.hash = hash
        value.salt = salt

      if id?
        callback([id, value])
      else
        callback([value])
      return
    return

  findOne: (req, res) =>
    actionName = 'readOne'
    actionDesc = 'Read One'
	
    @tryAction req, res, actionName, actionDesc, =>
      id = @clientApi.getRecordId()
      return [id]
      
    return

    
  insert: (req, res) =>
    actionName = 'create'
    actionDesc = 'Create One'
    
    @tryAction req, res, actionName, actionDesc, (callback) =>
      value = @clientApi.getPostValue()
      delete value.id if value? and value.id?

      sTable = @clientApi.getTableName()
      if sTable is 'Users'
        @generateHashSalt(value, null, callback)
      else
        callback([value])
      return
    return

    
  updateOne: (req, res) =>
    actionName = 'update'
    actionDesc = 'Update One'
    
    @tryAction req, res, actionName, actionDesc, (callback) =>
      id = @clientApi.getRecordId()
      value = @clientApi.getPostValue()

      delete value.id if value? and value.id?
      delete value._id if value? and value._id?

      sTable = @clientApi.getTableName()
      if sTable is 'Users'
        @generateHashSalt(value, id, callback)
      else
        callback([id, value])
      return
		
    return

    
  remove: (req, res) =>
    actionName = 'delete'
    actionDesc = 'Delete One'
    
    @tryAction req, res, actionName, actionDesc, =>
      id = @clientApi.getRecordId()
      return [id]
		
    return

  removeAll: (req, res) =>
    actionName = 'deleteAll'
    actionDesc = 'Delete All'

    @tryAction req, res, actionName, actionDesc, =>
      return []

    return

  getTree: (req, res) =>
    return

  createAction: (req, res, sName, sDesc) ->
    ret = false

    @clientApi.setReq req

    msgCheck = @clientApi.checkReqParamsOk()
    if msgCheck isnt ''
      action =
        req: req
        res: res
        actionName: sName
        actionDescription: sDesc
        tableName: ''
        msgError: "ERROR: #{sDesc} \n"
        msgSuccess: "SUCCESS: #{sDesc} \n"

      @actionBegin action
      @actionEnd action, msgCheck, null, null
    else
      sTable = @clientApi.getTableName()
      ret =
        req: req
        res: res
        actionName: sName
        actionDescription: sDesc
        tableName: sTable
        msgError: "ERROR: #{sDesc} #{sTable} \n"
        msgSuccess: "SUCCESS: #{sDesc} #{sTable} \n"

    return ret

  tryAction: (req, res, actionName, actionDesc, fn) =>
    action = @createAction req, res, actionName, actionDesc

    if action
      if !@checkAuthorization(req, res, action)
        return

    if action and fn
      if actionName is 'create' or actionName is 'update'  # and action.tableName is 'Users'
        fn (result) =>
          args = result
          @actionProcess action, args
          return
      else
        args = fn()
        @actionProcess action, args
      
    return

  actionProcess: (action, args = []) =>
    @actionBegin action
    
    ModelClazz = @dbProvider[action.tableName]
    
    if not ModelClazz
      @actionEnd action, "Model Class #{action.tableName} does not exist", null, null
    else
      fn = @crudOperation[action.actionName]
      
      callback = (err, docs, total_count, sum_doc) =>
        if total_count?
          total = total_count
        else
          if _.isNull docs or _.isEmpty docs
            total = 0
          else if _.isArray docs
            total = docs.length
          else if _.isObject docs
            total = 1
        @actionEnd action, err, docs, total, sum_doc or null
        return

      args.unshift action.siteId
      args.unshift ModelClazz
      args.push callback
      
      fn.apply @, args
    return

  actionBegin: (action)->
    Utils.logInfo "BEGIN: #{action.actionDescription} #{action.tableName}"
    return
  
  actionEnd: (action, err, docs, total, sum_doc) =>
    if err
      Utils.logError action.msgError
      Utils.logError err
    else
      Utils.logInfo action.msgSuccess
      
    ret =
      data: (docs or {})
      success: (not err)
      total: total
      message: err
      groupSummaryData: [sum_doc]
      
    #Utils.writeLog JSON.stringify(ret, null, '\t')
    
    action.res.contentType 'application/json'
    action.res.send ret
    
    ###
      Emit CRUD operation's result to Socket.io
    ###
    unless err
      crud_notification =
        action: action.actionName
        table: action.tableName
        data: (docs or {})
      @emit 'crud', crud_notification
    
    return

  checkAuthorization: (req, res, action)->
    loginUser = req.loginUser

    msgCheck = ''
    authorized = false
    userRole = loginUser.role
    siteId = loginUser.site or '0'

    accessLevel = userCan[action.actionName][action.tableName]

    if !accessLevel
      msgCheck = 'accessLevel is not defined'
    else
      if accessLevel.bitMask <= userRole.bitMask
        authorized = true
        msgCheck = 'authorized'
      else
        msgCheck = 'unauthorized'

    if !authorized
      Utils.logInfo "checkAuthorization for action: #{action.actionName} on table: #{action.tableName}"
      Utils.logError "checkAuthorization for action: #{action.actionName} on table: #{action.tableName} is " + msgCheck
      res.send {message: msgCheck}, 403
    else
      Utils.logInfo "checkAuthorization for action: #{action.actionName} on table: #{action.tableName}"
      Utils.logInfo "checkAuthorization for siteId: #{siteId} is " + msgCheck
      action.siteId = siteId

    return authorized

exports.CrudApi = CrudApi
