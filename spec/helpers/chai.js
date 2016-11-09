var chai = require('chai');
var asPromised = require('chai-as-promised');
var Writable = require("stream").Writable;
var Readable = require("stream").Readable;
var Promise = require("promise");


chai.config.includeStack = true;
chai.use(asPromised);

global.expect = chai.expect;
global.AssertionError = chai.AssertionError;
global.Assertion = chai.Assertion;
global.assert = chai.assert;

global.Factory = require("./factory");

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
