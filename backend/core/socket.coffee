socketio = require 'socket.io'
#parseCookie = require('connect').utils.parseSignedCookies
#cookie = require("cookie")

{ Utils } = require './utils'

Logger = require './logger'

socketCore = (httpServer, _sessionStore, _sessionSecret, appApi, User) ->
  io = socketio.listen httpServer
  io.set 'log level', 1

  io.set 'authorization', (data, accept) ->
    if data and data.query and data.query.token
      access_token = data.query.token
      ip = data.address.address

      User.verifyToken access_token, ip, (error, result) ->
        #Add the sessionId. This will show up in
        #socket.handshake.sessionId.

        #It's useful to set the ID and session separately because of
        #those fun times when you have an ID but no session - it makes
        #debugging that much easier.
        #data.sessionId = sessionId;

        if error or not result
          accept( "ERROR: #{error}", false )
        else
          # Add the session. This will show up in
          # socket.handshake.session.
          #data.session =
          accept( null, true )
    else
      accept("NO_TOKEN", false)
    return





  #
  # Server side event
  # TODO: we might wait a little bit to let session being retrieved from database
  # when server is restarted (connection is called before session retrieval)
  crudSocket = io.of '/crud'
  loggerSocket = io.of '/logger'

  logger = Logger.inject()

  #logger.on "socket", () ->
  #  console.log 'logger.on socket'
  #  logger.socketIo = loggerSocket

    #io.sockets
    #  .on 'connection', (socket) ->

  crudSocket.on 'connection', (socket) ->
    #socket.join socket.handshake.sessionID
    #console.log "On socket client connection handling"

    ###
    Socket.io session handling
    ###

    ###
    sessionID = socket.handshake.sessionID

    _sessionStore.get sessionID, (err, session) ->
      if err or not session
        #console.log "error in get session"
      else
        socket.handshake.session = session
        #console.log "On connection session : ",socket.handshake.session
    ###

    ###
      CRUD Operations Notification to Socket Clients
    ###
    appApi.on "crud", (crud_notification) ->
      socket.emit 'crud', crud_notification
      return

    setInterval ()->
      socket.emit 'send:time',
        time: (new Date()).toString()
    , 1000

    #socket.on 'my other event', (data) ->
    #  console.log 'my other event data: ', data
    return

  loggerSocket.on 'connection', (socket) ->
    #socket.join socket.handshake.sessionID
    #console.log 'loggerSocket.on connection'

    logger.setSocketIo loggerSocket
    return

  return

exports.socketCore = socketCore


