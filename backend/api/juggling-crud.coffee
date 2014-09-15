###
This docstring documents JugglingCrud. It can include *Markdown* syntax,
which will be converted to html.
###

async = require 'async'
{ BaseCrud } = require '../core/crud'

class JugglingCrud extends BaseCrud
  read: (ModelClazz, aFilter = [], sQuery = '', aSort = [], aGroup = [], iOffset = 0, iLimit = 15, callback) ->
    findOptions = {}
    oWhere = {}
    
    ###
    Get order list from aSort
    each element is a object {field, dir}
    ###
    findOptions.order = aSort.reduce (l, r) ->
      s = r.field + ' ' + r.dir.toUpperCase()
      if l is ''
        l = s
      else
        l += ',' + s
      return l
    , ''
    
    operMap =
      eq: '='
      lt: '<'
      gt: '>'
      gte: '>='
      lte: '<='
      ne: '!='
      bt: 'BETWEEN'
      nbt: 'NOT BETWEEN'
      like: 'LIKE'
      
    ###
    Get where list from aFilter
    each element is a object {field, cmp, value}
    ###
    reduceWhere = aFilter.reduce (l, r)->
      sHolder = l.holder
      aValues = l.values
      
      s = r.field + ' ' + operMap[r.cmp] + ' ? '
      
      aValues.push r.value
      
      if sHolder is ''
        sHolder = s
      else
        sHolder += ' AND ' + s
        
      ret = 
        holder: sHolder
        values: aValues
      return ret
    , {holder: '', values: []}
    
    
    if reduceWhere.holder isnt '' and reduceWhere.values.length >0
      cWhere1 = [reduceWhere.holder]
      cWhere1.push value for value in reduceWhere.values
      
      cWhere2 = [reduceWhere.holder]
      cWhere2.push value for value in reduceWhere.values
      
      findOptions['where'] = cWhere1
      oWhere = 'where' : cWhere2
      
    findOptions = {}
    oWhere = {}
    
    findOptions.skip = parseInt iOffset
    findOptions.limit = parseInt iLimit
    
    async.waterfall [
      (cb) =>
        ModelClazz.count oWhere, (err, return_count) ->
          #console.log 'count: ', return_count
          cb err, return_count
          return
        return
      (return_count, cb) =>
        ModelClazz.all findOptions, (error,docs) ->
          cb error, docs, return_count
          return
        return
    ], (error, docs, return_count) ->
      #console.log docs
      sumDoc = {}
      callback error, docs, return_count, sumDoc
      return
    return
  
  readOne: (ModelClazz, id, callback) ->
    ModelClazz.find id, (error,doc) ->
      callback error, doc
    return
    
  create: (ModelClazz, value, callback) ->
    ModelClazz.create value, (error, doc) ->
      callback error, doc
    return

  update: (ModelClazz, id, value, callback) ->
    async.waterfall [
      (cb) =>
        console.log 'record id: ', id
        ModelClazz.find id, (error,doc) ->
          cb error, doc
          return
        return
      (doc, cb) =>
        if doc?
          doc.updateAttributes value, (error, model) ->
            cb error, model
            return
        else
          cb "Cound not find record id: #{id}", null
        return
    ], (error, doc) ->
      callback error, doc
    return

  delete: (ModelClazz, id, callback) ->
    async.waterfall [
      (cb) =>
        console.log 'record id: ', id
        ModelClazz.find id, (error,doc) ->
          cb error, doc
          return
        return
      (doc, cb) =>
        if doc?
          doc.destroy (error) ->
            cb error, null
            return
        else
          cb "Cound not find record id: #{id}", null
        return
    ], (error, doc) ->
      callback error, doc
      
    return
      
exports.JugglingCrud = JugglingCrud


