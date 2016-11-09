xdescribe "a fulltext attribute", ->
# FIXME: these tests are a mess. We should rewrite them from scratch

  Fulltext = require "../../src/config-types/fulltext"
  mockHighlight = (query)->
    (hit,i,hits)->
      pattern = if typeof query == "string" then ///#{query}///ig else query
      title = hit._source.title || ""
      abstract = hit._source.info.abstract || ""
      highlight = {}
      if title.search(pattern) != -1
        highlight.title = [title.replace(pattern, "<em>$&</em>")]
        hit.highlight = highlight
      if abstract.search(pattern) != -1
       highlight['info.abstract'] = [abstract.replace(pattern, "<em>$&</em>")]
       hit.highlight = highlight
    
  mockHit = (doc)->
    _index: doc.index ? "my_index"
    _type: doc.type ? ",y_type"
    _id: ""+doc.id ? "42"
    _score: 0.0
    _source: doc

  mockSearchResult =(docs, options)->
    hits = docs.map mockHit
    if options?.forEach?
      hits.forEach options?.forEach
    result =
      took: 0
      timed_out: false
      _shards:
        total: 0
        successful: 0
        failed: 0
      hits:
        total: options?.total || hits.length
        max_score: 0.0
        hits: hits
    result.aggregations = options.aggregations if options?.aggregations
    result



  it "states its intention to contribute to the query", ->
    f=new Fulltext field:'blah'
    expect(f.query ).to.be.truthy

  it "allows setting a boost value", ->
    f=new Fulltext field:'blah', boost:4
    expect(f.boost ).to.eql 4

  it "does can produce a highlighting expression", ->
    f=new Fulltext field:'blah'
    expect(f.highlight()  ).to.eql {}

  describe "render values in search results", ->

    it "uses highlighted values if available", ->
      f=new Fulltext field:'title'
      hit = mockSearchResult(
        [ type:"project", id:1, title: "Irgendwas mit Bienen"],
        forEach:mockHighlight "Bienen"
      ).hits.hits[0]
      expect(f.renderResult hit).to.eql "Irgendwas mit <em>Bienen</em>"

    it "truncates long strings", ->
      f=new Fulltext
        field:'info.abstract'
        teaserLength: 150
      hit = mockSearchResult([ type:"project", id: 1,
        info:
          abstract: "Laborum id amet nostrud adipisicing duis deserunt commodo
                     tempor ullamco tempor occaecat sit nulla laborum. Voluptate
                     non adipisicing et veniam nisi consectetur ad velit. Dolore
                     nisi laborum velit sint nisi duis minim labore ea ex do
                     aliqua deserunt. Ad laboris Lorem ad ipsum ipsum reprehenderit
                     voluptate incididunt magna ut velit enim mollit."
      ]).hits.hits[0]
      expect(f.renderResult hit).to.equal "
                  Laborum id amet nostrud adipisicing duis deserunt commodo
                  tempor ullamco tempor occaecat sit nulla laborum. Voluptate
                  non adipisicing et veniam nisi …"
  describe "augment results", ->
    it "supports non-destructive augmentation by merging additional properties", ->
      f=new Fulltext
        field:'title'
        augmentHit: (preview)->data:title: preview
      dstHit = id:42, data:foo:'bar'
      srcHit = mockSearchResult(
        [ type: "project", id: 1, title: "Irgendwas mit Bienen"],
        forEach:mockHighlight "Bienen"
      ).hits.hits[0]
      f.augmentHit srcHit, dstHit
      expect(dstHit).to.eql
        id:42
        data:
          foo: 'bar'
          title: "Irgendwas mit <em>Bienen</em>"



    it "supports destructive augmentation via higher-order function", ->
      f=new Fulltext
        field:'title'
        augmentHit: (preview)->(dst)->dst.data.title = preview
      dstHit = id:42, data:foo:'bar'
      srcHit = mockSearchResult(
        [ type:"project", id: 1, title: "Irgendwas mit Bienen"],
        forEach:mockHighlight "Bienen"
      ).hits.hits[0]
      f.augmentHit srcHit, dstHit
      expect(dstHit).to.eql
        id:42
        data:
          foo: 'bar'
          title: "Irgendwas mit <em>Bienen</em>"

    it "supports destructive direct manipulation of the hit", ->
      f=new Fulltext
        field:'title'
        augmentHit: (preview,src,dst)->dst.data.title = preview
      dstHit = id:42, data:foo:'bar'
      srcHit = mockSearchResult(
        [ type:"project", id: 1, title: "Irgendwas mit Bienen"],
        forEach:mockHighlight "Bienen"
      ).hits.hits[0]
      f.augmentHit srcHit, dstHit
      expect(dstHit).to.eql
        id:42
        data:
          foo: 'bar'
          title: "Irgendwas mit <em>Bienen</em>"


