path = require "path"
bulk = require "bulk-require"
module.exports = bulk (path.resolve __dirname, 'config-types'), '*'
