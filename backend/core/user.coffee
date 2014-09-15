jwt = require 'jwt-simple'
async = require('async')
hash = require('./pass').hash

{ serverConfig } = require '../config/init'
{ Utils } = require './utils'
{ userRoles } = require './routing-config'


class User
  @dbProvider: null
  @cacheTokens: []
  
  @getUser: (siteId, name, callback) =>
    findConditions = null
    if siteId is 0 or siteId is '0'
      findConditions = {username: name}
    else
      findConditions = {site: siteId, username: name}

    Utils.logInfo findConditions

    @dbProvider.Users.findOne findConditions, (err, user) ->
      callback err, user
      return
    return
    
  @getFbUser: (name, callback) =>
    @dbProvider.FbUsers.findOne {username: name}, (err, user) ->
      callback err, user
      return
    return
    
  @getFbUserById: (id, callback) =>
    @dbProvider.FbUsers.findOne {fbId : id}, (err, user) ->
      callback err, user
      return
    return

  @createSite: (site, callback) =>
    @dbProvider.Site.create site, (error, doc) ->
      callback error, doc
      return
    return

  @updateSite: (siteId, value, callback) =>
    @dbProvider.Site.findByIdAndUpdate siteId, value, (error,doc) ->
      callback error, doc
    return

  @saveUser: (user, callback) =>
    @dbProvider.Users.create user, (error, doc) ->
      callback error, doc
      return
    return

  @updateUser: (user, callback) =>
    id = user._id
    delete user._id
    @dbProvider.Users.findByIdAndUpdate id, user, (error, doc) ->
      callback error, doc
      return
    return

  @authenticate: (siteId, userName, passWord, callback) =>
    Utils.logInfo 'Authenticating starting...'
    Utils.logInfo 'siteId: ', siteId
    Utils.logInfo 'username: ', userName
    Utils.logInfo 'password: ', passWord

    if siteId is '0' and userName is 'anon'
      user = {}
      user.site = siteId
      user.id = '0'
      user.name = userName
      user.fullname = 'Anonymous User'
      user.role = 'anon'
      callback null, user

    else

      async.waterfall [
        (cb) =>
          @getUser siteId, userName, (error, user) ->
            cb error, user
            return
          return
        (user, cb) ->
          if user
            hash passWord, user.salt, (err, hash) ->
              cb err, user, hash
              return
          else
            errMsg = 'Invalid login'
            cb errMsg, null
            Utils.logInfo 'Authenticating', 'error', errMsg
          return
        (user, hash, cb) ->
          if hash is user.hash
            cb null, user
          else
            errMsg = 'Invalid login'
            cb errMsg, null
          return
      ], (error, result) ->
        callback error, result
        return

    return

  @authenticateSuccess: (req, res) =>
    expired_date = new Date()
    expired_date.setMinutes(expired_date.getMinutes() + 6 * 60)

    client_ip = Utils.getClientIp req

    user = {}
    user.site = req.user.site
    user.id = req.user.id
    user.name = req.user.username
    user.fullname = req.user.fullname
    user.role = userRoles[req.user.role]
    user.expired = expired_date
    user.ip = client_ip

    token = jwt.encode(user, serverConfig._tokenScrete)

    @cacheTokens.push(token)

    res.send {user: user, token: token}, 200
    return

  @logout: (req, res) =>
    token = req.headers['authorization'] or req.query.token
    ip = Utils.getClientIp req

    @verifyToken token, ip, (error, user) =>
      if user
        index = 0
        foundToken = null

        for item in @cacheTokens
          if item is token
            foundToken = index
          index++;

        if foundToken
          @cacheTokens.splice(foundToken, 1)

        res.send {success: true}
      else
        res.send {success: false, message: error}
      return
    return

  @register: (req, res) =>
    userName = req.body.username
    fullName = req.body.fullname
    password = req.body.password
    
    async.waterfall [
      (cb) =>
        hash password, (err, salt, hash) ->
          cb err, salt, hash
          return
        return
      (salt, hash, cb) =>
        user = username: userName, fullname: fullName, salt: salt, hash: hash
        Utils.logInfo 'user: ', user

        @saveUser user, (error, result) ->
          cb error, result
          return
        return
    ], (error, result) ->
      if error
        msg = error
      else
        msg = 'Registration Success'

      res.send {message: msg}, 200
      return
    return

  # POST: { "siteName": "JodomaxShop", "siteDescription": "Jodomax Fashion",  "adminName": "admin_all", "adminFullName": "Admin All", "adminPassword": "123456"}
  @registerSite: (req, res) =>
    siteData = {}
    siteData.name = req.body.siteName or 'DefaultNewSite'
    siteData.description = req.body.siteDescription
    siteData.logoUrl = req.body.siteLogoUrl
    siteData.address = req.body.siteAddress
    siteData.telephone = req.body.siteTelephone
    siteData.totalTable = req.body.siteTotalTable


    adminData = {}
    adminData.username = req.body.adminName or siteData.name + 'Admin'
    adminData.fullname = req.body.adminFullName or 'Site Admin'
    adminData.password = req.body.adminPassword or '123456'
    adminData.role = 'admin'

    async.waterfall [
      (cb) =>
        Utils.logInfo 'newSite: ', siteData
        @createSite siteData, (error, result) ->
          cb error, result
          return
        return
      (newSite, cb) =>
        hash adminData.password, (err, salt, hash) ->
          cb err, newSite, salt, hash
          return
        return
      (newSite, salt, hash, cb) =>
        adminData.site = newSite.id
        adminData.salt = salt
        adminData.hash = hash

        @saveUser adminData, (error, siteAdmin) ->
          cb error, newSite, siteAdmin
          return
        return
      (newSite, siteAdmin, cb) =>
        siteId = newSite.id
        adminId = siteAdmin.id
        @updateSite siteId, {admin: adminId}, (error, updatedSite) ->
          cb error, updatedSite, siteAdmin
          return
        return
    ], (error, newSite, siteAdmin) ->
      success = false
      if error
        success = false
        msg = error
      else
        success = true
        msg = 'Site registration was successed'

      res.send {success: success, message: msg, newSite: newSite, siteAdmin: siteAdmin}, 200
      return
    return

  @verifyToken: (token, ip, cb) ->
    Utils.logInfo 'verifyToken...'
    Utils.logInfo "request_ip: ", ip

    errMsg = ''
    user = null

    if !token
      errMsg = 'Token is null'
    else
      try
        foundToken = false

        for item in @cacheTokens
          if item is token
            foundToken = true

        if (!foundToken)
          errMsg = 'Token is not found'
        else
          user = jwt.decode(token, serverConfig._tokenScrete)

          if user.ip is ip
            if new Date(user.expired) < new Date()
              errMsg = 'Token was expired'
          else
            errMsg = 'Token has invalid ip address: ' + ip

      catch e
        errMsg = 'Token decode eror: ' + e.toString()

    if errMsg is ''
      cb null, user
      Utils.logInfo 'verifyToken OK, user:', user
    else
      cb errMsg, false
      Utils.logError errMsg

    return

  @validateToken: (req, res) =>
    token = req.headers['authorization'] or req.query.token
    ip = Utils.getClientIp req

    @verifyToken token, ip, (error, user) ->
      if user
        res.send {success: true, user: user}
      else
        res.send {success: false, message: error}
      return
    return

  @restrict: (req, res, next) =>
    token = req.headers['authorization'] or req.query.token
    clientIp = Utils.getClientIp req

    @verifyToken token, clientIp, (error, user) ->
      if user
        req.loginUser = user;
        next()
      else 
        res.send {message: 'Unauthenticated', error: error or ''}, 401
      return
    return

  @deserializeUser: (id, done) =>
    async.waterfall [
      (cb) =>
        @getFbUser id, (err, user) ->
          cb err, user
      (user, cb) =>
        if user
          cb null, user
        else
          @getUser id, (err, user) ->
            cb err, user
    ], (error, result) ->
      done error, result
    return

  @authenticatedOrNot: (req, res, next) ->
    if req.isAuthenticated()
      next()
    else
      res.redirect "/login"

  @userExist: (req, res, next) ->
    @dbProvider.Users.count { username: req.body.username }, (err, count) ->
      if count is 0
        next()
      else
        # req.session.error = "User Exist"
        res.redirect("/singup");



  
exports.User = User

