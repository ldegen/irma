describe "The geolocation-Facet", ->
  Geolocation =require '../../src/config-types/geolocation'
  f=undefined
  beforeEach ->
    f = new Geolocation field:"blah"

  it "complains, if you try to instantiate it without the 'new' operator", ->
    expect -> Geolocation()
      .to.throw /new/

  it "can construct a filter expression", ->
    expect(f.filter("foo,bar,baz")).to.eql
      geo_distance:
        distance: 'baz'
        blah:
          lat:'foo'
          lon:'bar'
