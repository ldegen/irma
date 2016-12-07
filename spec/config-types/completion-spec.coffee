describe "A Completion", ->
  
  Completion =require '../../src/config-types/completion'
  Suggest = require '../../src/config-types/suggest'

  c=undefined
  beforeEach ->
    c = new Completion field:"blah"

  it "complains if you try to instantiate it without `new`", ->
    mistake = -> c = Completion field:"blah"
    expect(mistake).to.throw /new/
  it "is a special kind of Suggestion", ->
   expect(c).to.be.an.instanceof Suggest

  it "knows how to ask ES for suggestions", ->
    expect(c.build q:"onkel").to.eql
      text:"onkel"
      completion: field: "blah"

  it "knows how to transform suggestions returned by ES", ->
    #TODO: identity for now -- do we need something else?
    input = 
      text: "lari"
      offset: 42
      length: 4
      options: [
        text: "Lari Fari Mogelzahn"
        score: 9001
        payload: foo:"bar", id:2
      ]
    expect(c.transform input).to.eql input
