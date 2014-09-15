###
This docstring documents SenchaClientApi. It can include *Markdown* syntax,
which will be converted to html.
###

_ = require 'underscore'

{ Utils } = require '../core/utils'
{ BaseClientApi } = require '../core/client'

class ClientApi extends BaseClientApi
  getFilter: =>
    filter = @req.query.filter
    
    elements = []
    if filter?
      Utils.logInfo 'Filter defined: ', filter
      
      if _.isString filter
        els = @getConditionFromString filter
        elements.push el for el in els
      else if _.isArray filter
        elements = @getConditionFromArray filter
    
    return elements
    
  getQuery: =>
    query = @req.query.query
    return query      
  
  getSort: =>
    sort = @req.query.sort
    mapSort = []
    
    if sort?
      Utils.logInfo 'Sort defined: ', sort
      
      if _.isString sort
        sortArr = JSON.parse sort
        
        if _.isArray sortArr
          mapSort = sortArr.map (item) -> {field: item.property, dir: item.direction}

      Utils.logInfo 'Sort output: ', mapSort

    return mapSort
  
  
  getGroup: =>
    group = @req.query.group
    mapGroup = []
    
    if group?
      #Utils.writeLog 'Group defined', group
    
      if _.isString group
        groupArr = JSON.parse group
        
        if _.isArray groupArr
          mapGroup = groupArr.map (item) -> {field: item.property, dir: item.direction}
          
    return mapGroup
    
  getOffset: =>
    return @req.query.start
  
  getLimit: =>
    return @req.query.limit

  getConditionFromString: (filter) =>
    elements = []
    items = JSON.parse filter
    
    if _.isArray items
      for item in items
        element = {field: item.property, value: item.value, type: (item.type or ''), cmp: (item.comparison or 'eq')}
        elements.push element
      
    return elements
    
  getConditionFromArray: (filter) =>
    elements = []
    for item in filter
      if _.isString item
        els = @getConditionFromString(item)
        elements.push el for el in els
      else if _.isObject item
        element = {field: item.field, value: item.data.value, type: item.data.type, cmp: item.data.comparison}
        elements.push element
        
    return elements


exports.ClientApi = ClientApi  
  

