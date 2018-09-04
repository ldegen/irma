{ Given, When, Then, Before, After, defineParameterType} = require 'cucumber'

{ expect } = require 'chai'
Promise = require 'bluebird'

agg = require "agg"

defineParameterType
  name: 'ids'
  regexp: /((?:\d+\s*(?:,|und)\s*)*(?:\d+))?/
  transformer: (s)->
    (s?.split(/\s*(?:,|und)\s*/) ? [])
      .map (d)->parseInt d
  useForSnippets: true
  preferForRegexpMatch: false
  
Given 'folgende Lookup-Einträge:', (dataTable) ->
  data = {}
  data[lookup]=table for {lookup, table} in agg.transformSync dataTable.rawTable
  @putLookup data

Given 'folgende Institutionen:', (dataTable) ->
  institutions = agg.transformSync dataTable.rawTable
  @allInstitutions = institutions
  @putInstitutions institutions

Given 'ich verwende {string} als Default-Operator', (string)->
  @query ?= {}
  @query.qop = string


When 'ich nach {string} suche', (string) ->
  @explicitlyMentionedIds = 0
  @query ?= {}
  @query.q = string
  @search @query
    .then ({statusCode})->
      expect(statusCode).to.eql 200

expectResultDoesContain = (id)->
  @explicitlyMentionedIds += 1
  @response
    .then ({body})->
      foundIds = body.hits.map (d)->d.data.id
      expect(foundIds).to.include "#{id}" # es always stores _id as string.

Then 'muss die Institution {int} gefunden werden', expectResultDoesContain
Then 'die Institution {int} muss gefunden werden', expectResultDoesContain

expectResultDoesNotContain = (id) ->
  @explicitlyMentionedIds += 1
  @response
    .then ({body})->
      foundIds = body.hits.map (d)->d.data.id
      expect(foundIds).not.to.include "#{id}" # es always stores _id as string.

Then 'darf die Institution {int} nicht gefunden werden', expectResultDoesNotContain
Then 'die Institution {int} darf nicht gefunden werden', expectResultDoesNotContain

expectResultDoesContainEach = (ids)->
  @explicitlyMentionedIds += ids.length
  @response
    .then ({body})->
      foundIds = body.hits.map (d)->d.data.id
      for id in ids
        expect(foundIds).to.include "#{id}"

Then 'müssen die Institutionen {ids} gefunden werden', expectResultDoesContainEach
Then 'die Institutionen {ids} müssen gefunden werden', expectResultDoesContainEach

expectResultContainsNothingElse = ->
  @response
    .then ({body})=>
      expect(body.hits.length - @explicitlyMentionedIds).to.equal 0

Then 'es dürfen keine anderen Institutionen gefunden werden', expectResultContainsNothingElse
Then 'keine anderen Institutionen dürfen gefunden werden', expectResultContainsNothingElse

expectHigherScoreThan = (higherIds, lowerIds)->
  @response
    .then ({body}) ->
      scores = {}
      scores[hit.data.id] = hit.score for hit in body.hits

      for higherId in higherIds
        for lowerId in lowerIds
          expect(scores[higherId]).to.be.above(scores[lowerId], "expected #{higherId} to have higher score than #{lowerId}")

Then 'müssen die Institutionen {ids} höher bewertet werden als {ids}', expectHigherScoreThan
Then 'die Institutionen {ids} müssen höher bewertet werden als {ids}', expectHigherScoreThan
Then 'die Institution {ids} muss höher bewertet werden als {ids}', expectHigherScoreThan

expectMonotonicallyIncreasing = (numbers, message)->
  prev = null
  for number in numbers 
    expect.fail(numbers, "monotonically increasing", message) if prev? and prev > number
    prev = number

expectOrderOfOccurrence = (ids)->
  @response
    .then ({body}) ->
      positions = {}
      positions[hit.data.id] = pos for hit,pos in body.hits
      idPositions = ids.map (id)->positions[id]
      actualIds = body.hits
        .map (hit)->hit.data.id
      message = """
        Expected institutions to appear in the follwing order: #{ids}
        But the actual order was #{actualIds}
      
      """
      expectMonotonicallyIncreasing idPositions, message

Then 'zwar in der Reihenfolge: {ids}', expectOrderOfOccurrence

expectAllInstitutions = ->
  ids = @allInstitutions.map ({id})->id
  expectResultDoesContainEach.call this, ids

Then 'müssen alle Institutionen gefunden werden', expectAllInstitutions 
  

Then 'gibt es keine Treffer', ->
  @response
    .then ({body})->
      expect(body.total).to.eql 0

Before (testCase)->
  Promise.all [
    @resetIndex()
  ]


After ->
  Promise.all [
  ]
