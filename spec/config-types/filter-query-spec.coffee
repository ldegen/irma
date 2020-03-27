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
        bool:filter:[
          filterFoo:1
        ,
          filterBar:42
        ]

    it "understands empty queries", ->
      fq = new FilterQuery
      queryObj= {q:"no filter"}

      expect(fq.create(queryObj, type)).to.eql {}

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

    it "understands empty queries", ->
      fq = new FilterQuery
      reqObj=
        query: q: "not a filter either"
        type: 'my_type'

      expect(fq.apply reqObj, settings).to.eql {match_all:{}}

    it "supports explicitly overriding the processed attributes", ->

      fq = new FilterQuery
      reqObj=
        query: foo:1, bar:42
        type: 'my_type'

      attributes = settings.types.my_type.attributes.filter ({name})->name is "bar"

      expect(fq.apply reqObj, settings, attributes).to.eql [
        filterBar:42
      ]
