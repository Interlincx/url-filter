Url             = require "url"
{EventEmitter}  = require "events"
util            = require "util"

module.exports = UrlList = (urls) ->
  @initUrls urls

  @totalCount = @urls.length
  @matchCount = 0

  return this

util.inherits UrlList, EventEmitter

UrlList::initUrls = (urls) ->
  idInc = 0
  @urls = urls.map (url) ->
    obj = Url.parse url, true
    obj.id = ["u", idInc].join ""
    idInc += 1
    return obj

  return true

UrlList::updateCounts = ->
  counts = @urls.reduce (acc, url) ->
    acc.match += 1 if url.match
    acc.total += 1
    return acc
  , {total: 0, match: 0}

  @totalCount = counts.total
  @matchCount = counts.match

  return true

UrlList::updateMatches = (matchIds=[]) ->
  @urls.forEach (url) ->
    if url.id in matchIds
      url.match = true
    else
      url.match = false

  @updateCounts()

  @emit "match"

  return true

UrlList::dropIds = (dropIds=[]) ->
  @urls = @urls.filter (url, i, arr) ->
    return url.id not in dropIds

  @updateCounts()

  @emit "resize", @totalCount

  return true

UrlList::groupByPath = ->
  byPath = @urls.reduce (acc, url) ->
    acc[url.pathname] ?= []
    acc[url.pathname].push url

    return acc
  , {}

  return byPath

UrlList::getStatusByPath = ->
  byPath = @groupByPath()

  countsByPath = {}
  for path, urls of byPath
    countsByPath[path] = urls.reduce (acc, url) ->
      acc.match += 1 if url.match
      acc.total += 1
      return acc
    , {total: 0, match: 0}

  statusByPath = {}
  for path, counts of countsByPath

    if counts.total is counts.match
      status = "full"
    else if counts.match > 0
      status = "partial"
    else
      status = "none"

    statusByPath[path] = status

  return statusByPath

UrlList::findById = (id) ->
  found = null
  @urls.some (url) ->
    if url.id is id
      found = url
      return true
    else
      return false

  return found
