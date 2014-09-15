###
This docstring documents MongooseCrud. It can include *Markdown* syntax,
which will be converted to html.
###

async = require 'async'
{ BaseCrud } = require '../core/crud'
_ = require 'underscore'

{ Utils } = require '../core/utils'

class MongooseCrud extends BaseCrud
  read: (MongooseModelClazz, siteId, aFilter = [], sQuery = '', aSort = [], aGroup = [], iOffset = 0, iLimit = 15, callback) ->
    findOptions = {}
    findOptions.skip = parseInt iOffset
    findOptions.limit = parseInt iLimit

    ###
    Get order list from aSort
    each element is a object {field, dir}
    ###
    findOptions.sort = aSort.reduce (l, r) ->
      oSort = {}
      switch r.dir.toUpperCase()
        when 'ASC'
          oSort[r.field] = 1
        when 'DESC'
          oSort[r.field] = -1
        else
          oSort[r.field] = 1

      oSort = _.extend l, oSort
      return oSort
    , {}

    Utils.logDebug 'findOptions: ', findOptions

    operMap =
      eq: '$eq'
      lt: '$lt'
      gt: '$gt'
      gte: '$gte'
      lte: '$lte'
      ne: '$ne'
      bt: '$in'
      nbt: '$nin'
      like: '$LIKE'

    findConditionsStartUp = null
    if siteId is '0' or siteId is 0
      findConditionsStartUp = {}
    else
      findConditionsStartUp = {site: siteId}

    findConditions = aFilter.reduce (l, r)->
      oLeft = l
      #oLeft[r.field] = {}

      switch r.cmp
        when 'eq'
          #oLeft[r.field] = {$eq: r.value}
          switch r.type
            when 'integer'
              oLeft[r.field] = r.value
            when 'string'
              oLeft[r.field] = '' + r.value + ''
            when 'date'
              oLeft[r.field] = r.value
              #new Date(r.value)
            else
              oLeft[r.field] = r.value
          ###
            when 'lt'
              oLeft[r.field] = {$lt: r.value}
            when 'gt'
              oLeft[r.field] = {$gt: r.value}
            when 'gte'
              oLeft[r.field] = {$gte: r.value}
            when 'lte'
              oLeft[r.field] = {$lte: r.value}
            when 'ne'
              oLeft[r.field] = {$ne: r.value}
            when 'bt'
              oLeft[r.field] = {$in: r.value}
            when 'nbt'
              oLeft[r.field] = {$nin: r.value}
          ###
        when 'like'
          oLeft[r.field] = new RegExp r.value, 'i'
        else
          oper = {}
          oper[operMap[r.cmp]] = r.value
          oLeft[r.field] = _.extend oLeft[r.field] or {}, oper


      #ret = _.extend l, oLeft
      ret = l
      return ret
    , findConditionsStartUp

    Utils.logDebug 'findConditions: ', findConditions

    modelPopulation = []
    if MongooseModelClazz.getPopulation?
      modelPopulation = MongooseModelClazz.getPopulation()

    #if modelPopulation isnt ''
    Utils.logDebug 'modelPopulation: ', modelPopulation

    async.waterfall [
      (cb) =>
        MongooseModelClazz.count findConditions, (err, return_count) ->
          cb err, return_count
          return
        return
      (return_count, cb) =>
        if modelPopulation.length > 0
          chaining = MongooseModelClazz.find(findConditions, null, findOptions)

          for populate in modelPopulation
            tableName = populate[0]
            fieldsName = populate[1]
            if fieldsName is '*'
              chaining.populate(tableName)
            else
              chaining.populate(tableName, fieldsName)

          chaining.exec (error,docs) ->
            cb error, docs, return_count
            return
          return
        else
          MongooseModelClazz.find(findConditions, null, findOptions).exec (error,docs) ->
            cb error, docs, return_count
            return
          return
    ], (error, docs, return_count) ->
      sumDoc = {}
      callback error, docs, return_count, sumDoc
      return
    return
  
  readOne: (MongooseModelClazz, siteId, id, callback) ->
    MongooseModelClazz.findById id, (error,doc) ->
      callback error, doc
    return
    
  create: (MongooseModelClazz, siteId, value, callback) ->
    if siteId is '0' or siteId is 0
      # do something
    else
      value.site = siteId

    MongooseModelClazz.create value, (error, doc) ->
      callback error, doc
    return

  update: (MongooseModelClazz, siteId, id, value, callback) ->
    MongooseModelClazz.findByIdAndUpdate id, value, (error,doc) ->
      callback error, doc
    return


  delete: (MongooseModelClazz, siteId, id, callback) ->
    async.waterfall [
      (cb) =>
        MongooseModelClazz.findById id, (error,doc) ->
          cb error, doc
          return
        return
      (doc, cb) =>
        MongooseModelClazz.remove {_id: id}, (error) ->
          cb error, doc
          return
        return
    ], (error, doc) ->
      callback error, doc
      
    return

  deleteAll: (MongooseModelClazz, siteId, callback) ->
    removeCondition = null

    if siteId is '0' or siteId is 0
      removeCondition = {}
    else
      removeCondition = {site: siteId}


    async.waterfall [
      (cb) =>
        MongooseModelClazz.remove removeCondition, (error) ->
          cb null, error
          return
        return
    ], (error, doc) ->
      callback error, doc

    return

exports.MongooseCrud = MongooseCrud