FilterQuery = require "../../src/config-types/filter-query.coffee"
describe "The Filter Query", ->

  type =
    attributes:[
      name: "foo"
      filter: (s)->filterFoo:s
    ,
      name: "bar"
      filter: (s)->filterBar:s
    ]
  settings =
    types: my_type: type

  describe "legacy api", ->

    it "picks up filter attributes from given type", ->
      fq = new FilterQuery
      queryObj= foo:1, bar:42

      expect(fq.create(queryObj, type)).to.eql
        query:bool:filter:[
          filterFoo:1
        ,
          filterBar:42
        ]

  describe "new api", ->

    it "picks up filter attributes from given type", ->
      fq = new FilterQuery
      reqObj=
        query: foo:1, bar:42
        type: 'my_type'

      expect(fq.apply reqObj, settings).to.eql [
        filterFoo:1
      ,
        filterBar:42
      ]

    it "supports explicitly overriding the processed attributes", ->

      fq = new FilterQuery
      reqObj=
        query: foo:1, bar:42
        type: 'my_type'

      attributes = settings.types.my_type.attributes.filter ({name})->name is "bar"

      expect(fq.apply reqObj, settings, attributes).to.eql [
        filterBar:42
      ]
