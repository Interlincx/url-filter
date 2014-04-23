test = require "prova"
UrlFilter = require "../lib/index.coffee"
UrlList = require "../lib/url-list.coffee"

urls = [{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/","created_at":"2013-10-09T21:12:38.674Z","url":"http://localhost:3011/","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/?id=1212","created_at":"2013-10-09T22:47:51.980Z","url":"http://localhost:3011/?id=1212","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/?id=2525","created_at":"2013-10-09T22:47:59.286Z","url":"http://localhost:3011/?id=2525","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=123","created_at":"2013-10-09T22:47:00.337Z","url":"http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=123","version":"0.2.0"},{"_id":"com_aa2c55a0-443d-4df4-a29e-ee6985b839bd_http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=456","created_at":"2013-10-09T22:47:10.621Z","url":"http://localhost:3011/form?action=&loanAmount=500&firstName=&lastName=&phoneHome=&email=&submit=&sub=456","version":"0.2.0"}]
urlStrings = urls.map (url) -> url.url
ul = new UrlList urlStrings

# console.log "urls", ul.urls.map (url) -> return [url.pathname, url.query]

test "== url filter ==", (t) ->
  t.test "new instance matches nothing", (st) ->
    uf = new UrlFilter
    st.equal uf.getMatchIds(ul.urls).length, 0
    st.end()

  t.test "matches pathname criteria", (st) ->
    uf = new UrlFilter
    uf.addCriteria "pathname", "/"

    matchIds = uf.getMatchIds ul.urls
    st.equal matchIds.length, 3
    st.equal uf.getMatchIds(ul.urls).length, 3
    st.end()

  t.test "matches single query criteria", (st) ->
    uf = new UrlFilter
    uf.once "criteria", (criteria) ->
      st.equal (Object.keys criteria.query).length, 1
      st.end()

    uf.addCriteria "query", {id: "1212"}
    st.equal uf.getMatchIds(ul.urls).length, 1

  t.test "matches after remove", (st) ->
    uf = new UrlFilter
    uf.addCriteria "pathname", "/"
    uf.addCriteria "query", {id: "1212"}
    st.equal uf.getMatchIds(ul.urls).length, 1

    uf.removeCriteria "query", {id: "1212"}
    st.equal uf.getMatchIds(ul.urls).length, 3

    uf.removeCriteria "pathname", "/"
    st.equal uf.getMatchIds(ul.urls).length, 0
    st.end()

  t.test "remove twice in a row has no effect", (st) ->
    uf = new UrlFilter
    uf.addCriteria "pathname", "/"
    uf.addCriteria "query", {id: "1212"}

    uf.removeCriteria "query", {id: "1212"}
    uf.removeCriteria "query", {id: "1212"}
    st.equal uf.getMatchIds(ul.urls).length, 3

    uf.removeCriteria "pathname", "/"
    uf.removeCriteria "pathname", "/"
    st.equal uf.getMatchIds(ul.urls).length, 0

    st.equal uf.criteria.query, null
    st.equal uf.criteria.pathname, null


    st.end()

  t.test "matches two qs values", (st) ->
    uf = new UrlFilter
    uf.addCriteria "query", {sub: "456"}
    uf.addCriteria "query", {loanAmount: "500"}
    st.equal uf.getMatchIds(ul.urls).length, 1
    st.end()

  t.test "addPage emits criteria correctly", (st) ->
    spec =
      pathname: "/"
      query: { id: "1212" }

    uf = new UrlFilter

    uf.once "criteria", (newCriteria) ->
      st.deepEqual newCriteria.pathname, "/": true
      st.deepEqual newCriteria.query, spec.query
      st.equal uf.getMatchIds(ul.urls).length, 1
      st.end()

    uf.addPage spec

  t.test "addPage accepts pathname object", (st) ->
    spec =
      pathname: 
        "/": true
        "/form": true
      query: { id: "1212" }

    uf = new UrlFilter
    
    uf.addPage spec
    st.deepEqual uf.criteria.pathname, spec.pathname

    uf.removeCriteria "query", id: "1212"

    st.equal uf.getMatchIds(ul.urls).length, 5
    st.end()


  t.test "removePage fn", (st) ->
    spec =
      pathname: "/"
      query: { id: "1212" }

    uf = new UrlFilter

    uf.addPage spec

    uf.removePage spec

    st.deepEqual uf.criteria.pathname, null
    st.deepEqual uf.criteria.query, null

    st.equal uf.getMatchIds(ul.urls).length, 0
    st.end()

  t.test "use tag criteria check fns", (st) ->
    spec =
      pathname: "/"
      query: { id: "1212" }

    uf = new UrlFilter
    uf.addPage spec

    st.ok (uf.checkPathname "/"), "pathname should match"
    st.ok (uf.checkQuery "id", "1212"), "query pair should match"

    st.notOk (uf.checkPathname "/form"), "pathname should miss"
    st.notOk (uf.checkQuery "pid", "1212"), "query pair should miss"

    st.end()

  t.test "use checkQuery on empty object", (st) ->
    spec =
      pathname: "/"
      query: {}

    uf = new UrlFilter
    uf.addPage spec

    st.notOk (uf.checkQuery "id", "1212"), "query pair should miss"

    st.end()

  t.test "has criteria", (st) ->
      spec =
        pathname: "/"
        query: { id: "1212" }      

      uf = new UrlFilter

      uf.addPage spec

      st.ok uf.hasCriteria "query", {id: "1212"}
      st.notOk uf.hasCriteria "query", {other: "hoho"}

      st.ok uf.hasCriteria "pathname", "/"
      st.notOk uf.hasCriteria "pathname", "/page-final"

      st.end()

  t.test "toggle criteria", (st) ->
    spec =
      pathname: "/"
      query: { id: "1212" }

    uf = new UrlFilter

    st.equal uf.getMatchIds(ul.urls).length, 0, "starting matches zero"

    uf.addPage spec

    st.equal uf.getMatchIds(ul.urls).length, 1, "add page matches 1"

    uf.toggleCriteria "query", {id: "1212"}

    st.equal uf.getMatchIds(ul.urls).length, 3, "toggle query matches 3"

    uf.toggleCriteria "query", {id: "1212"}
    st.equal uf.getMatchIds(ul.urls).length, 1, "toggle same query matches 1"

    uf.toggleCriteria "pathname", "/"
    st.equal uf.getMatchIds(ul.urls).length, 1, "toggle path matches 1"

    uf.toggleCriteria "pathname", "/form"
    uf.toggleCriteria "query", {id: "1212"}

    st.equal uf.getMatchIds(ul.urls).length, 2, "toggle path and query matches 2"

    st.end()

  t.test "sets multiple paths", (st) ->
    uf = new UrlFilter
    uf.addCriteria "pathname", "/"
    uf.addCriteria "pathname", "/form"

    matches = uf.getMatchIds ul.urls
    st.equal matches.length, ul.totalCount
    st.end()

  t.test 'sets wildcard path', (st) ->
    uf = new UrlFilter
    uf.addCriteria 'pathname', '*'

    matches = uf.getMatchIds ul.urls
    st.equal matches.length, ul.totalCount
    st.end()




