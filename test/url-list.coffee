test = require "prova"
UrlList = require "../lib/url-list.coffee"

urls = [{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/","created_at":"2013-10-09T21:12:38.674Z","url":"http://localhost:3011/","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/?id=1212","created_at":"2013-10-09T22:47:51.980Z","url":"http://localhost:3011/?id=1212","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/?id=2525","created_at":"2013-10-09T22:47:59.286Z","url":"http://localhost:3011/?id=2525","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=123","created_at":"2013-10-09T22:47:00.337Z","url":"http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=123","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=456","created_at":"2013-10-09T22:47:10.621Z","url":"http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=456","version":"0.2.0"}]
urlStrings = urls.map (url) -> url.url

test "== url list ==", (t) ->
  t.test "should assign id to every url in list", (st) ->
    ul = new UrlList urlStrings

    ul.urls.forEach (url) -> 
      st.ok url.id, "url obj gets an id"

    st.end()

  t.test "should set initial matches", (st) ->
    ul = new UrlList urlStrings

    ul.once "match", ->
      st.ok ul.urls[0].match, "match is true"

      [1..4].forEach (ix) ->
        st.notOk ul.urls[ix].match, "match is false"

      st.equal ul.totalCount, 5
      st.equal ul.matchCount, 1

      st.end()

    matchId = ul.urls[0].id
    ul.updateMatches [matchId]

  t.test "should overwrite matches", (st) ->
    ul = new UrlList urlStrings

    matchId = ul.urls[0].id
    ul.updateMatches [matchId]

    newMatchIds = [ul.urls[1].id, ul.urls[2].id]
    ul.updateMatches newMatchIds

    st.equal ul.totalCount, 5
    st.equal ul.matchCount, 2

    ul.urls.forEach (url) ->
      if url.id in newMatchIds
        st.ok url.match, "should be match"
      else
        st.notOk url.match, "should not be match"

    st.end()


  t.test "should drop url objects by id", (st) ->
    ul = new UrlList urlStrings
    toDrop = ul.urls.map (url) -> url.id

    ul.once "resize", (length) ->
      st.equal length, ul.totalCount

      st.equal ul.totalCount, 0
      st.equal ul.matchCount, 0

      for url in ul.urls
        st.notOk url.id in toDrop, "does not contain dropped id"

      st.end()

    ul.dropIds toDrop

  t.test "groupByPath should group", (st) ->
    ul = new UrlList urlStrings
    byPath = ul.groupByPath()
    st.equal (Object.keys byPath).length, 2

    st.equal byPath["/"].length, 3
    st.equal byPath["/form"].length, 2

    st.end()

  t.test "findById should find", (st) ->
    ul = new UrlList urlStrings
    findId = ul.urls[0].id

    found = ul.findById findId

    st.ok found, "find should return truthy"
    st.equal found.id, findId, "found obj should match id"

    st.end()

  t.test "getStatusByPath should return statuses", (st) ->
    ul = new UrlList urlStrings

    matchIds = [ul.urls[1].id, ul.urls[2].id]
    ul.updateMatches matchIds

    statuses = ul.getStatusByPath()

    st.equal statuses["/"], "partial"
    st.equal statuses["/form"], "none"

    matchIds = [ul.urls[3].id, ul.urls[4].id]
    ul.updateMatches matchIds

    statuses = ul.getStatusByPath()

    st.equal statuses["/"], "none"
    st.equal statuses["/form"], "full"

    st.end()
