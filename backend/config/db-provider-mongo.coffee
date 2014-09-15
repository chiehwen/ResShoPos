jwt = require 'jwt-simple'
{ serverConfig } = require './init'
{ Utils } = require '../core/utils'




mongoose = require 'mongoose'
mongoose.connect serverConfig._mongoConnectStr




db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')
db.once 'open', () ->
  Utils.logInfo 'MongoDb Opened'



DbProvider = {}
ObjectId = mongoose.Schema.Types.ObjectId



###
Kitten example for testing
###
kittySchema = mongoose.Schema
  name: { type: String, required: true }

Kitten = mongoose.model 'Kitten', kittySchema


###
Site schema and model
###
siteSchema = mongoose.Schema
  name: { type: String, required: true, index: true }
  description: { type: String}
  logoUrl: { type: String }
  address: { type: String }
  telephone: { type: String }
  totalTable: { type: Number }
  admin: { type: ObjectId, ref: 'UserAuths', index: true}
  createdTime: { type: Date, index: true, default: () -> return new Date }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

Site = mongoose.model('Site', siteSchema)




###
User schema and model
###
localUserSchema = mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  username: { type: String, required: true, index: true }
  fullname: { type: String, required: true}
  password: { type: String }
  salt: { type: String, required: true }
  hash: { type: String, required: true }
  role: { type: String, required: true, default: 'user' }
  shiftNumber: { type: String }
  jointDate: { type: Date, index: true, default: () -> return new Date }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

localUserSchema.methods.getAccessToken = () ->
  payload = { foo: 'bar' }
  token = jwt.encode(payload, serverConfig._tokenScrete)
  return token

Users = mongoose.model('UserAuths', localUserSchema)



###
UserFinalization schema and model
###
userFinalizationSchema = mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  dateFinalize:
    type: Date
    index: true
    required: true
    #default: () ->
    #  recent = new Date
    #  recent.setHours(0, 0, 0, 0)
    #  return recent
  user: { type: ObjectId, ref: 'UserAuths', index: true , required: true }
  paymentAmount: { type: Number, required: true }
  realAmount: { type: Number, required: true }
  lostAmount: { type: Number, required: true }
  shiftNumber: { type: Number, required: true }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

userFinalizationSchema.statics.getPopulation = () ->
  return [['user', 'username fullname _id']]

UserFinalization = mongoose.model('UserFinalization', userFinalizationSchema)


###
Order schema and model
###
orderSchema = mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  orderNo: { type: Number, required: true, index: true }
  tableNo: { type: Number, required: true, index: true  }
  createdTime: { type: Date, index: true, default: () -> return new Date }
  totalAmount: { type: Number, required: true, default: 0 }
  itemCount: { type: Number, required: true, default: 0 }
  status: { type: Number, required: true, default: 0 }
  createdBy: { type: ObjectId, ref: 'UserAuths', index: true , required: true }
  closedBy: { type: ObjectId, ref: 'UserAuths', index: true }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

orderSchema.statics.getPopulation = () ->
  return [['createdBy', 'username fullname']]

Order = mongoose.model('Order', orderSchema)


###
OrderItem schema and model
###
orderItemSchema = mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  order: { type: ObjectId, ref: 'Order', index: true , required: true }
  menuData: { type: ObjectId, ref: 'MenuData', index: true , required: true }
  itemName: { type: String }
  price: { type: Number, required: true }
  quantity: { type: Number, required: true }
  amount: { type: Number, required: true }
  status: { type: Number, index: true, required: true, default: 0 }
  userRequest: { type: String }
  hashKey: { type: String }
  createdTime: { type: Date, index: true , default: () -> return new Date }
  orderedBy: { type: ObjectId, ref: 'UserAuths', index: true , required: true }
  deletedBy: { type: ObjectId, ref: 'UserAuths', index: true }
  deletedReason: { type: String }
  voided: { type: Boolean, index: true, default: false }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

orderItemSchema.statics.getPopulation = () ->
  ret = [
    ['order', '*'],
    ['menuData', '*'],
    ['orderedBy', 'username fullname'],
    ['deletedBy', 'username fullname'],
  ]

  return ret

OrderItem = mongoose.model('OrderItem', orderItemSchema)


###
Category schema and model
###
categorySchema = mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  name: { type: String, required: true }
  createdTime: { type: Date,    default: () -> return new Date }
  allowOrder: { type: Boolean, default: true }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

Category = mongoose.model('Category', categorySchema)




###
MenuData schema and model
###
menuDataSchema = mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  name: { type: String, required: true }
  enName: { type: String, required: true } 
  price: { type: Number, required: true } 
  createdTime: { type: Date,    default: () -> return new Date }
  type: { type: String, required: true }
  category: { type: ObjectId, ref: 'Category', index: true }
  url: { type: String, required: true }
  allowOrder: { type: Boolean, default: true }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

Menudata = mongoose.model('MenuData', menuDataSchema)



###
Table schema and model
###
tableSchema = mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  tableNo: { type: Number, index: true, required: true }
  status: { type: Number, index: true, required: true, default: 0 }
  createdTime: { type: Date, index: true, default: () -> return new Date }
,
  toObject: { virtuals: true },
  toJSON: { virtuals: true }

Table = mongoose.model('Table', tableSchema)




###
Invoice schema and model
###
invoiceSchema = mongoose.Schema
  #orderId: { type: ObjectId, ref: 'Order', required: true, index: true }
  site: { type: ObjectId, ref: 'Site', index: true}
  orderNo: { type: Number, required: true, index: true  }
  invoiceNo: { type: Number }
  tableNo: { type: Number, required: true, index: true  }
  createdTime: { type: Date, index: true, default: () -> return new Date }
  totalAmount: { type: Number, required: true }
  status: { type: Number, required: true, default: 1 }
  doneBy: { type: ObjectId, ref: 'UserAuths', index: true , required: true }
,
  toObject: { virtuals: true }
  toJSON: { virtuals: true }
  id: Number

invoiceSchema.statics.getPopulation = () ->
  return [['doneBy', 'username fullname']]

Invoice = mongoose.model('Invoice', invoiceSchema)



###
FacebookUser schema and model
###
facebookUserSchema = new mongoose.Schema
  site: { type: ObjectId, ref: 'Site', index: true}
  fbId: { type: String, required: true }
  email: { type : String , lowercase : true, required: true }
  name : { type: String, required: true } 
    
FbUsers = mongoose.model('Fbs',facebookUserSchema)




###
News schema and model for testing
###
newsSchema = mongoose.Schema
  title:     { type: String, required: true  },
  content:   { type: String, required: true  },
  date:      { type: Date,    default: () -> return new Date }
  timestamp: { type: Number,  default: Date.now },
  published: { type: Boolean, default: false, index: true }
News = mongoose.model('News', newsSchema)




###
Attach model to DbProvider and Export
###
DbProvider.mongoose = mongoose


DbProvider.Kitten = Kitten
DbProvider.News = News


DbProvider.Site = Site

DbProvider.Users = Users
DbProvider.FbUsers = FbUsers
DbProvider.Table = Table
DbProvider.Category = Category
DbProvider.Menudata = Menudata
DbProvider.Order = Order
DbProvider.OrderItem = OrderItem
DbProvider.Invoice = Invoice
DbProvider.UserFinalization = UserFinalization

exports.MongooseDbProvider = DbProvider

