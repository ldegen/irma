describe "The ConfigBuilder", ->
  fs = require "fs"
  path = require "path"
  Promise = require "bluebird"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  merge = require "deepmerge"
  defaults = require("../default-settings.json")
  ConfigBuilder = require "../src/config-builder"

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
    expect(ConfigBuilder().cfg).to.eql defaults

  it "can load yaml config files", ->
    expect(
      ConfigBuilder()
        .tryLoad fileB
        .load fileA
        .cfg
    ).to.eql merge defaults, port: 4242, __files:[fileA]

  xdescribe "when adding options", ->
    it "can resolve placeholders", ->
      expect(
        ConfigBuilder()
          .add __env:PUBLIC_IP: "123.456.78.9"
          .add ["PUBLIC_IP"], (PUBLIC_IP)->host:PUBLIC_IP
          .cfg
      ).to.eql merge defaults,
        host: "123.456.78.9"
        __env: PUBLIC_IP: "123.456.78.9"
        __usedEnvVars: ["PUBLIC_IP"]

  describe "when loading files", ->
    it "can resolve placeholders in filenames", ->
      expect(
        ConfigBuilder()
          .add __env:HOME:tmpDir
          .load ["HOME"], (HOME)->path.join HOME,"fileA.yaml"
          .cfg
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
          .cfg
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
          .cfg
      ).to.eql merge defaults, port: 4242, __files:[fileA]
