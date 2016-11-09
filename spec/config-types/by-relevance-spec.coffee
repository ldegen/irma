describe "Sorting by relevance", ->
  ByRelevance = require "../../src/config-types/by-relevance"
  
  sorter = undefined

  beforeEach ->
    sorter = new ByRelevance field:'blah'

  it "complains, if you try to instantiate it without the 'new' operator", ->
    expect -> ByRelevance()
      .to.throw /new/

  it "always sorts on field by score, descending", ->
    expect(sorter.direction('some direction').sort()).to.eql
      '_score':'desc'
