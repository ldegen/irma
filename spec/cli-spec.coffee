describe "The Command Line Interface", ->
  Io = require "../src/config-types/io"
  yaml = require "js-yaml"
  cli = require "../src/cli"
  {ConfigBuilder} = require "@l.degener/irma-config"
  {unit} = ConfigBuilder
  io = undefined
  defaults =
    by:"default"
  path = require "path"
  Promise = require "bluebird"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  fs = require "fs"
  readme = yaml.load fs.readFileSync path.resolve __dirname, "../README.yaml"
  Automist = require "automist"
  mocks = undefined
  trace = undefined
  servers = undefined
  foo1 = bar1= bar2= baz2=undefined
  merge = require "deepmerge"
  endStreams = (_,{io:{stdout, stderr}})->stream.end() for stream in [stdout, stderr]
  tmpDir = typeDir1 = typeDir2 = configFile1= configFile2 = undefined
  capitalize = (x)->x.replace /^(\w)/g, (_,c)->c.toUpperCase()
  toCamelCase = (x)->x.replace /\W+(\w)/g, (_,c)->c.toUpperCase()
  createModule = (dir, name)->
    file= path.join dir, "#{name.toLowerCase()}.coffee"
    fs.writeFileSync file, """
    module.exports=class #{capitalize toCamelCase name}
    module.exports._dir="#{dir}"
    """
    require file

  beforeEach ->

    trace = []
    servers = []
    io = new Io stderr: Sink(), stdout: Sink()
    defaults.io = io
    mocks=
      Server: (settings)->
        me = servers.length
        servers.push me
        trace.push ['Server', me, settings._options]
        start: ->
          trace.push ["Server", me, 'start']
          Promise.resolve settings
        stop: ->
          trace.push ["Server", me, 'stop']
          Promise.resolve()
    tmpDir  = tmpFileName()
    typeDir1 = path.join tmpDir, "types1"
    typeDir2 = path.join tmpDir, "types2"
    configFile1 = path.join tmpDir, "config1.yaml"
    configFile2 = path.join tmpDir, "config2.yaml"

    Promise.all [typeDir1, typeDir2].map (d)-> mkdir d
      .then ->
        foo1 = createModule typeDir1, "foo"
        bar1 = createModule typeDir1, "bar"
        bar2 = createModule typeDir2, "bar"
        baz2 = createModule typeDir2, "baz"
        fs.writeFileSync configFile1, """
        port: 4242
        nő: Irma néni
        """
        fs.writeFileSync configFile2, """
        férfi: Károly bácsi
        nő: Vilma néni
        kutya: Frakk
        macskák:
          - Lukrécia
          - Szerénke
        """

  it "starts an IRMa server, applying factory defaults", ->
    expect(
      unit defaults
        .bind cli()
        .run mocks
    ).to.be.fulfilled.then (outcome)->
      expect(outcome._options).to.eql defaults
      expect(trace).to.eql [
        ['Server', 0, defaults]
        ['Server', 0, 'start']
      ]

  it "can produce a help message", ->
    expect(
      unit defaults
        .bind cli "--help"
        .then endStreams
        .run mocks
    ).to.be.fulfilled.then (outcome)->
      expect(trace).to.eql []
      expect(io.stderr.promise).to.eventually.eql [Automist(readme).help()]

  it "can produce manpage", ->
    expect(
      unit defaults
        .bind cli "--manpage"
        .then endStreams
        .run mocks
    ).to.be.fulfilled.then (outcome)->
      expect(trace).to.eql []
      expect(io.stdout.promise).to.eventually.eql [Automist(readme).manpage()]

  it "can add directories to search for config types", ->
    expect(
      unit defaults
        .bind cli "-T", typeDir1, "-T", typeDir2
        .run mocks
    ).to.be.fulfilled.then (outcome)->
      expect(outcome._options).to.eql merge defaults,
        __types:
          foo: foo1
          bar: bar1
          baz: baz2
        __typePath: [
          typeDir2
          typeDir1
        ]
      expect(trace).to.eql [
        ['Server', 0, outcome._options]
        ['Server', 0, 'start']
      ]

  it "can override settings on the command line", ->
    expect(
      unit defaults
        .bind cli "--es-host", "neenee.gibtsni.ch:1234", "--es-index", "fum", "--listen", "192.168.1.2:42", configFile1, configFile2
        .run mocks
    ).to.be.fulfilled.then (outcome)->
      expect(outcome._options).to.eql merge defaults,
        __files: [configFile2, configFile1]
        host: "192.168.1.2"
        port: 42
        férfi: "Károly bácsi"
        nő: "Irma néni"
        kutya: "Frakk"
        macskák: ["Lukrécia", "Szerénke"]
        elasticSearch:
          host: "neenee.gibtsni.ch"
          port: 1234
          index: "fum"
      expect(trace).to.eql [
        ['Server', 0, outcome._options]
        ['Server', 0, 'start']
      ]
