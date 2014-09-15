_ = require 'underscore'
{ EventEmitter } = require 'events'
{ Utils } = require './utils'

winston = require 'winston'
require('winston-mongodb').MongoDB

{ serverConfig } = require '../config/init'


#winston.loggers.add 'userLog',
#  MongoDB:
#    host: 'mongodb://localhost'
#    db: 'testDb'
#    collection: 'userLog'
#_userLog = winston.loggers.get 'userLog'
#_userLog.info 'User log started'


_allLogFilePath = serverConfig._apiServerPath + '/logs/all-logs.log'
_exceptionLogFilePath = serverConfig._apiServerPath + '/logs/exceptions.log'

_something = ''

#console.log '_exceptionLogFilePath: ', _exceptionLogFilePath


_logger = new (winston.Logger)
  transports: [
    #new (winston.transports.Console)()
    new (winston.transports.File)
      filename: _allLogFilePath
    #new (winston.transports.MongoDB)
    #  db: 'testDb'
    #  collection: 'systemLog'
  ]
  exceptionHandlers: [
    new (winston.transports.File)
      filename: _exceptionLogFilePath
  ]
  exitOnError: false

class Logger extends EventEmitter
  constructor: (di) ->
    _logger.on 'logging', (transport, level, msg, meta) =>
      if @socketIo and transport.name is 'file'
        #console.log "\n**emitting socket msg: ", msg
        @socketIo.emit "newLog", {level: level, message: msg}
      return

    #_logger.stream().on 'log', (log) =>
      #console.log log
    #  if @socketIo and log.transport[0] is 'mongodb'
    #    console.log "\n**emitting socket msg"
    #    @socketIo.emit "newLog", log
    #  return
    #return

  socketIo: null

  info: (msg, metadata) ->
    _logger.info msg

  warn: (msg, metadata) ->
    _logger.warn msg

  error: (msg, metadata) ->
    _logger.error msg

  setSocketIo: (socket) ->
    @socketIo = socket


_loggerInstance = null

module.exports.inject = (di) ->
  if !_loggerInstance
    _loggerInstance = new Logger(di)
  return _loggerInstance
