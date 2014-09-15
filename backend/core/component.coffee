async = require 'async'
{hash} = require './pass'
{Utils} = require './utils'

passport = require "passport"
LocalStrategy = require('passport-local').Strategy
FacebookStrategy = require('passport-facebook').Strategy;

{ User } = require './user'

###
  PassPort Settings
###
localStrategy = new LocalStrategy {usernameField: 'username', passReqToCallback: true}
, (req, username, password, done) ->

  siteId = req.body.siteId or '0'

  User.authenticate siteId, username, password, done
  return
  
passport.use localStrategy

passport.use new FacebookStrategy
  clientID: "YOUR ID",
  clientSecret: "YOUR CODE",
  callbackURL: "http://localhost:3000/auth/facebook/callback"
, (accessToken, refreshToken, profile, done) ->
  User.authenticateFb accessToken, refreshToken, profile, done
  return

passport.serializeUser (user, done) ->
  done null, user.id
  return

passport.deserializeUser (id, done) ->
  User.deserializeUser id, done
  return

exports.User = User
exports.passport = passport
