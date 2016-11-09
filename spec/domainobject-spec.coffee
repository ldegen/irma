DomainObject = require "../src/config-types/domainobject"


describe "Any Domain Object", ->
  domObj = new DomainObject()

  it "complains, if you try to instantiate it without the 'new' operator", ->
    expect -> DomainObject()
      .to.throw /new/

  describe "Hit Augmentation", ->
    src=
      _score: 24
      _id: 42
      _type: 'Typ'
      _source: foo:'bar'
    dst=
      score:24
      data:
        type:'Typ'
        id: 42
    it "does nothing, if not configured", ->

      domObj.augmentHit(src,dst)

      expect(dst).to.eql
        score:24
        data:
          type:'Typ'
          id: 42

    it "can be done by directly manipulating hit objects", ->
      domObj = new DomainObject  augmentHit:  (src,dst)->
        dst.data.foo=src._source.foo
      domObj.augmentHit(src,dst)

      expect(dst).to.eql
        score:24
        data:
          type:'Typ'
          id: 42
          foo: 'bar'
     

    it "can be done by returning an augmentation function", ->
      domObj = new DomainObject  augmentHit:  (src)->
        (dst) -> dst.data.foo=src._source.foo
      domObj.augmentHit(src,dst)

      expect(dst).to.eql
        score:24
        data:
          type:'Typ'
          id: 42
          foo: 'bar'
    
    it "can be done by returning an augmentation object", ->
      domObj = new DomainObject  augmentHit:  (src)->
        data: foo: src._source.foo
      domObj.augmentHit(src,dst)

      expect(dst).to.eql
        score:24
        data:
          type:'Typ'
          id: 42
          foo: 'bar'
