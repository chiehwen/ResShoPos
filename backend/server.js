// Generated by CoffeeScript 1.7.1

/* Config Run App */

(function() {
  var AppApi, ClientApi, CrudApi, MongooseCrud, MongooseDbProvider, User, Utils, app, appApi, crossOriginAllower, express, fs, http, passport, path, server, serverConfig, sessionStore, socketCore, uuid, _ref;

  serverConfig = require('./config/init').serverConfig;

  console.log(serverConfig._apiServerPath);


  /*
          Requires
   */

  fs = require('fs');

  uuid = require('node-uuid');

  express = require('express');

  path = require('path');

  http = require('http');


  /*
    Disable Redis for running in Windows
  redis = require("redis").createClient()
  RedisStore = require("connect-redis")(express)
  _redisStore = new RedisStore({ host: 'localhost', port: 6379, client: redis })
   */

  Utils = require('./core/utils').Utils;


  /*
    Loading core sections
   */

  AppApi = require('./core/app-api').AppApi;

  CrudApi = require('./core/crud-api').CrudApi;

  _ref = require('./core/component'), passport = _ref.passport, User = _ref.User;

  socketCore = require('./core/socket').socketCore;


  /*
    Loading Mongoose Database and CRUD section
   */

  MongooseDbProvider = require('./config/db-provider-mongo').MongooseDbProvider;

  MongooseCrud = require('./api/mongoose-crud').MongooseCrud;


  /*
    Loading Juggling Database and CRUD section - Not using YET as Redis
   */


  /*
  { JugglingDbProvider } = require './config/db-provider-juggling'
  { JugglingCrud } = require './api/juggling-crud'
   */


  /*
    Loading Client API section
   */

  ClientApi = require('./api/sencha-client').ClientApi;


  /*
    App API using Mongoose Database and mongoose CRUD and Sencha Client API
   */

  appApi = new CrudApi(MongooseDbProvider, new ClientApi(), new MongooseCrud());


  /*
    User API using Mongoose Database
   */

  User.dbProvider = MongooseDbProvider;


  /*
    loading Plug-ins - this does not work at the moment - then commented
   */


  /*
          Cross Origin Resource Sharing Enable
   */

  crossOriginAllower = function(req, res, next) {
    var origin;
    origin = req.header('Origin', '*');
    if (origin === 'null') {
      origin = '*';
    }
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.header('Access-Control-Allow-Headers', 'Authorization, Content-Type, X-Requested-With, X-Session-Id');
    res.header('Access-Control-Expose-Headers', 'Location, X-Session-Id');
    if (req.method === 'OPTIONS') {
      res.header('Access-Control-Max-Age', 86400);
      return res.send(200);
    } else {
      return next();
    }
  };


  /*
          Declare the Server
   */

  app = express();

  server = http.createServer(app);


  /*
    Load socketCore Server
   */

  sessionStore = null;

  socketCore(server, sessionStore, serverConfig._sessionSecret, appApi, User);


  /*
          Configure the Server
   */

  module.exports = app.configure(function() {
    app.set("port", process.env.PORT || serverConfig._port);
    app.use(express.favicon());
    app.use(express.logger("dev"));
    app.use(express.bodyParser({
      uploadDir: serverConfig._apiServerPath + '/uploads'
    }));
    app.use(express.methodOverride());
    app.use(express.cookieParser(serverConfig._cookieSecret));
    app.use(express.session({
      secret: serverConfig._sessionSecret,
      key: 'connect.sid'
    }));
    app.use(passport.initialize());
    app.use(crossOriginAllower);
    app.use(app.router);
    return app.use(express["static"](path.join(serverConfig._apiServerPath, "public")));
  });


  /*
     Declare Router
   */


  /*
    Login and Registration routing
   */

  app.post('/login', passport.authenticate('local', {
    session: false
  }), User.authenticateSuccess);

  app.post('/logout', User.logout);

  app.post('/register', User.register);

  app.post('/registerSite', User.registerSite);

  app.post('/validate', User.validateToken);

  app.get('/validate', User.validateToken);


  /*
    Image file upload from clients
   */

  app.post('/file-upload', function(req, res) {
    var e, extName, fileName, fileNameLen, newFileName, startIdx, subDirName, target_path, thumbnail, tmp_path, url_path;
    subDirName = req.body.tableName;
    thumbnail = req.files.file;
    if (thumbnail) {
      fileName = thumbnail.name;
      fileNameLen = fileName.length;
      startIdx = fileNameLen - 3;
      extName = fileName.substr(startIdx, 3);
      newFileName = uuid.v4();
      tmp_path = thumbnail.path;
      target_path = serverConfig._apiServerPath + '/public/images/' + subDirName + '/' + newFileName + '.' + extName;
      url_path = 'images/' + subDirName + '/' + newFileName + '.' + extName;
      try {
        fs.rename(tmp_path, target_path, function(err) {
          var result;
          if (err) {
            res.send({
              success: false,
              message: err.toString(),
              url: null
            });
          }
          result = {};
          result.url = url_path;
          res.send({
            success: true,
            message: null,
            url: url_path
          });
        });
      } catch (_error) {
        e = _error;
        res.send({
          success: false,
          message: e.toString(),
          url: null
        });
      }
    } else {
      res.send({
        success: false,
        message: 'no upload file found',
        url: null
      });
    }
  });


  /*
    Temporary disable for easing of test POST, PUT, DELETE
   */

  app.all(/^(\/api)/, User.restrict);


  /*
    Application API routing section
   */

  app.get('/api/databases/:database?/collections/:collection?', appApi.query);

  app.get('/api/databases/:database?/collections/:collection?/:id', appApi.findOne);

  app.post('/api/databases/:database?/collections/:collection?', appApi.insert);

  app.put('/api/databases/:database?/collections/:collection?/:id', appApi.updateOne);

  app["delete"]('/api/databases/:database?/collections/:collection?', appApi.removeAll);

  app["delete"]('/api/databases/:database?/collections/:collection?/:id', appApi.remove);


  /*
     Start - Log
   */

  server.listen(app.get("port"), function() {
    return Utils.writeLog("ResShoPos back-end server is listening on port " + app.get("port"));
  });

}).call(this);

//# sourceMappingURL=server.map
