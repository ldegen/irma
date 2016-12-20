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

  it "builds configuration objects", ->
    expect(ConfigBuilder().cfg).to.eql defaults

  it "can load yaml config files", ->
    fs.writeFileSync fileA, """
    ---
    port: 4242
    """
    expect(
      ConfigBuilder()
        .tryLoad fileB
        .load fileA
        .cfg
    ).to.eql merge defaults, port: 4242, __files:[fileA]
