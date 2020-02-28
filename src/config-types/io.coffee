ConfigNode = require "../config-node"
{Console} = require "console"
{Readable, Writable} = require "stream"
{createReadStream, createWriteStream} = require "fs"

readFrom = (spec, opts, fallback)->
  if spec?
    if spec instanceof Readable
      spec
    else if typeof spec is "string"
      createReadStream spec, opts
    else
      throw new Error "Don't know how to read from #{spec}"
  else fallback

writeTo = (spec, opts, fallback)->
  if spec?
    if spec instanceof Writable
      spec
    else if typeof spec is "string"
      createWriteStream spec, opts
    else
      throw new Error "Don't know how to write to #{spec}"
  else fallback
      
module.exports = class Io extends ConfigNode
  init: ->

    @stdin = readFrom @_options.stdin, @_options.stdinOptions, process.stdin
    @stdout = writeTo @_options.stdout,@_options.stdoutOptions, process.stdout
    @stderr = writeTo @_options.stderr,@_options.stderrOptions, process.stderr
    @ignoreErrors = @_options.ignoreErrors ? true
    @colorMode = @_options.colorMode ? 'auto'
    @inspectOptions = @_options.inspectOptions ? {}
    @console = new Console
      stdout: @stdout
      stderr: @stderr
      ignoreErrors: @ignoreErrors
      colorMode: @colorMode
      inspectOptions: @inspectOptions
