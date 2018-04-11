describe "The ConfigBuilder", ->
  fs = require "fs"
  path = require "path"
  Promise = require "bluebird"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  merge = require "deepmerge"
  defaults = require("../src/default-settings")
  ConfigBuilder = require "../src/config-builder"
  ConfigNode = require "../src/config-node"

  tmpDir = fileA = fileB = undefined
  beforeEach ->
    tmpDir = tmpFileName()
    fileA = path.join tmpDir, "fileA.yaml"
    fileB = path.join tmpDir, "fileB.yaml"
    mkdir tmpDir
      .then ->
        fs.writeFileSync fileA, """
        ---
        port: 4242
        """

  it "builds configuration objects", ->
    expect(ConfigBuilder().build()).to.eql defaults

  it "can load yaml config files", ->
    expect(
      ConfigBuilder()
        .tryLoad fileB
        .load fileA
        .build()
    ).to.eql merge defaults, port: 4242, __files:[fileA]

  describe "when adding options", ->
    xit "can resolve placeholders", ->
      expect(
        ConfigBuilder()
          .add __env:PUBLIC_IP: "123.456.78.9"
          .add ["PUBLIC_IP"], (PUBLIC_IP)->host:PUBLIC_IP
          .build()
          
      ).to.eql merge defaults,
        host: "123.456.78.9"
        __env: PUBLIC_IP: "123.456.78.9"
        __usedEnvVars: ["PUBLIC_IP"]

    it "allows ConfigNodes to customize the merging behaviour", ->
      class MyNode extends ConfigNode
        merge: (old)->
          nada: true

      oldSettings = foo:bar: new MyNode bang:baz: new MyNode oink:42
      newSettings = foo:bar: new MyNode bang:baz: new MyNode oink:45


      cfg = ConfigBuilder().add(oldSettings).add(newSettings).build()

      expect(cfg.foo).to.eql bar:nada:true



  describe "when loading files", ->
    it "can resolve placeholders in filenames", ->
      expect(
        ConfigBuilder()
          .add __env:HOME:tmpDir
          .load ["HOME"], (HOME)->path.join HOME,"fileA.yaml"
          .build()
      ).to.eql merge defaults,
        port: 4242,
        __files:[fileA]
        __env: HOME: tmpDir
        __usedEnvVars: ["HOME"]

    it "can parse placeholder names form callback arguments", ->
      expect(
        ConfigBuilder()
          .add __env:HOME:tmpDir
          .load (HOME)->path.join HOME,"fileA.yaml"
          .build()
      ).to.eql merge defaults,
        port: 4242,
        __files:[fileA]
        __env: HOME: tmpDir
        __usedEnvVars: ["HOME"]

    xit "can autodetect placeholders in filenames", ->
      expect(
        ConfigBuilder()
          .add __env:HOME:tmpDir
          .load path.join "{HOME}","fileA.yaml"
          .build()
      ).to.eql merge defaults, port: 4242, __files:[fileA]

