### Updated 25/12/2013 ###
###
This docstring documents User-Plugin. It can include *Markdown* syntax,
which will be converted to html.
###

_ = require 'underscore'
async = require 'async'

{ hash } = require('../core/pass')
{ Utils } = require '../core/utils'


userPlugin = (appApi, User) ->
  appApi.on 'before_create', (before_create_notification) ->
    switch before_create_notification.table
      when 'Users'
        console.log 'before_create', before_create_notification

        data = before_create_notification.data

        password = data.password
        if not password? or password is ''
          password = '123456'

        console.log 'before_create - password: ', password

        console.log 'Create hash and salt...'

        hash password, (err, salt, hash) ->
          if err
            console.log 'Generate hash and salt - error:', err
          else
            console.log 'Generate hash and salt - successed'
            data.hash = hash
            data.salt = salt
            before_create_notification_feedback = {}
            before_create_notification_feedback.data = data
            appApi.emit 'before_create_feedback', before_create_notification_feedback
          return
        console.log 'before_create_feedback'
      else
        console.log 'come here 3'
        process.nextTick () ->
          before_create_notification_feedback = {}
          before_create_notification_feedback.data = before_create_notification.data
          console.log 'come here 4'
          appApi.emit 'before_create_feedback', before_create_notification_feedback
    return

  appApi.on "crud", (crud_notification) ->
    switch crud_notification.table
      when 'Users'
        switch crud_notification.action
          when 'update'
            console.log 'crud_notification', crud_notification

            password = crud_notification.data.password

            if not password? or password is ''
              password = '123456'

            console.log 'password: ', password

            userData = {}
            userData._id = crud_notification.data._id

            console.log 'Update hash and salt...'
            async.waterfall [
              (cb) =>
                hash password, (err, salt, hash) ->
                  cb err, salt, hash
              (salt, hash, cb) =>
                userData.hash = hash
                userData.salt = salt

                User.updateUser userData, (error, result) ->
                  cb error, result
            ], (error, result) ->
              if error
                console.log 'Update hash and salt - error:', error
              else
                console.log 'Update hash and salt - successed result: ', result
              return
          else
            break;
      else
        break;
    return

  return


exports.userPlugin = userPlugin