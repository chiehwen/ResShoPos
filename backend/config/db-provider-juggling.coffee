{ Schema } = require 'jugglingdb'

schema = new Schema 'redis', {port: 6379}

# define models
Post = schema.define 'Post',
    title:     { type: String, length: 255 },
    content:   { type: Schema.Text },
    date:      { type: Date,    default: () -> return new Date },
    timestamp: { type: Number,  default: Date.now },
    published: { type: Boolean, default: false, index: true }

JugglingDbProvider = {}


JugglingDbProvider.Post = Post


exports.JugglingDbProvider = JugglingDbProvider
