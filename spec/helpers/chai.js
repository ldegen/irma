var chai = require('chai');
var asPromised = require('chai-as-promised');
var Writable = require("stream").Writable;
var Readable = require("stream").Readable;
var Promise = require("bluebird");


chai.config.includeStack = true;
chai.use(asPromised);

global.expect = chai.expect;
global.AssertionError = chai.AssertionError;
global.Assertion = chai.Assertion;
global.assert = chai.assert;


global.Source = function(chunks,opts0){
  var opts = opts0 || {
    objectMode: true
  };
  var input = new Readable(opts);
  chunks.forEach(function(chunk){
    input.push(chunk);
  });
  input.push(null);
  return input;
};

global.Sink = function(opts0) {
  var opts = opts0 || {
    objectMode: true
  };
  var buf = opts.objectMode ? [] : new Buffer([]);
  var output = new Writable(opts);
  output._write = function(chunk, enc, next) {
    if (chunk) {
      if (opts.objectMode) {
        buf.push(chunk);
      } else {
        buf = Buffer.concat([buf, chunk]);
      }
    }
    next();
  };
  output.promise = new Promise(function(resolve, reject) {
    output.on("error", reject);
    output.on("finish", function() {
      resolve(opts.objectMode ? buf : buf.toString().trim());
    });
  });
  return output;
};
global.tmpFileName = function(test) {
  var buf;
  var crypto = require("crypto");
  if(test == null){
    buf = crypto.randomBytes(20);
  } else {
    var sha1 = crypto.createHash("sha1");
    sha1.update(new Buffer([process.pid]));
    sha1.update(test.fullTitle());
    buf = sha1.digest();
  }
  return require("path").join(
    require("os").tmpdir(),
    buf.toString("hex")
  );
};
