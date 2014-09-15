{ BaseModule } = require './base-module'

{ CrudApi } = require './crud-api'

class AppApi extends BaseModule
  @include CrudApi
  
  @setDbProvider: (dbProvider) ->
	  CrudApi.dbProvider = dbProvider
	
  @setClientApi: (ClientApi) ->
	  CrudApi.clientApi = new ClientApi()
	
  @setCrudOperation: (CrudOperation) ->
	  CrudApi.crudOperation = new CrudOperation()
	
  @extend CrudApi
	
exports.AppApi = AppApi

