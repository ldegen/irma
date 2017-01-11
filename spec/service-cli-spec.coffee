describe "The Service Manager CLI", ->
  {unit} = require "../src/config-builder"
  merge = require "deepmerge"
  endStreams = ({stdout, stderr})->stream.end() for stream in [stdout, stderr]
  cli = require "../src/service-cli"
  mocks = undefined
  trace = undefined
  serviceSettings = undefined
  beforeEach ->

    serviceSettings =
      name: "Super Service"
      description: "It's a description, duh."
      script: "/path/to/the/script.js"
    trace = []
    servers = []
    mocks=
      stderr: Sink()
      stdout: Sink()
      Service: (settings)->
        me = servers.length
        servers.push me
        trace.push ['Service', me, settings]
        install: ->
          trace.push ["Service", me, 'install']
          Promise.resolve settings
    tmpDir  = tmpFileName()

  it "wraps itself up as a system service", ->
    expect(
      unit {service: serviceSettings}
        .bind cli "install"
        .then endStreams
        .run(mocks)
    ).to.be.fulfilled.then ()->
      expect(trace).to.eql [
        [
          'Service'
          0
          serviceSettings
        ]
        ['Service',0, "install"]
      ]


  it "will guess the script name by looking at process.argv", ->
    delete serviceSettings.script
    expect(
      unit {service: serviceSettings}
        .bind cli "install"
        .then endStreams
        .run(mocks)
    ).to.be.fulfilled.then ()->
      expect(trace).to.eql [
        [
          'Service'
          0
          merge serviceSettings, script: process.argv[1]
        ]
        ['Service',0, "install"]
      ]

  it "will freeze the values of environment variables used by the current configuration", ->
    expect(
      unit
          service: serviceSettings
          __env: HOME: "/home/foobar", PUBLIC_IP:"123.456.78.9"
          __usedEnvVars: ["HOME", "PUBLIC_IP"]
        .bind cli "install"
        .then endStreams
        .run(mocks)
    ).to.be.fulfilled.then ()->
      expect(trace).to.eql [
        [
          'Service'
          0
          merge serviceSettings, 
            env: [
              name: "HOME"
              value: "/home/foobar"
            ,
              name: "PUBLIC_IP"
              value: "123.456.78.9"
            ]
        ]
        ['Service',0, "install"]
      ]


