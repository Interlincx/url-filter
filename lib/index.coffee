Url             = require "url"
{EventEmitter}  = require "events"
util            = require "util"
urlTag          = require "url-tag"

module.exports = UrlFilter = ->
  @clearCriteria()
  return this

util.inherits UrlFilter, EventEmitter

UrlFilter::urlIsMatch = (url) ->
  return urlTag @criteria, url

UrlFilter::getMatchIds = (urls=[]) ->
  ids = []

  hasPathname = @criteria.pathname?
  hasQuery = @criteria.query? and (Object.keys @criteria.query).length

  return ids unless hasPathname or hasQuery

  for url, i in urls
    ids.push url.id if @urlIsMatch url

  return ids

UrlFilter::clearCriteria = ->
  @criteria = pathname: null, query: null

UrlFilter::addPage = (pageSpec) ->
  for key, val of pageSpec
    if key is "pathname" and typeof val is "object"
      for path, v of val
        @addCriteria key, path, true

    else
      @addCriteria key, val, true


  @emit "criteria", @criteria

UrlFilter::removePage = (pageSpec) ->
  for key, val of pageSpec
    @removeCriteria key, val, true

  @emit "criteria", @criteria

UrlFilter::validateType = (type) ->
  if type not in ["pathname", "query"]
    throw new Error "type must be 'pathname' or 'query'"

UrlFilter::hasCriteria = (type, value) ->
  @validateType type

  if type is "pathname"
    return @checkPathname value
  else if type is "query"
    allMatched = true
    for k,v of value
      allMatched = false if !@checkQuery k, v 

    return allMatched

UrlFilter::toggleCriteria = (type, value) ->
  @validateType type

  if @hasCriteria type, value
    @removeCriteria type, value
  else
    @addCriteria type, value

UrlFilter::addCriteria = (type, value, silent=false) ->
  @validateType type

  if type is "pathname"
    @criteria.pathname ?= {}
    @criteria.pathname[value] = true

  else if type is "query"
    @criteria.query ?= {}

    for k,v of value

      @criteria.query[k] = v

  @emit "criteria", @criteria if !silent 

UrlFilter::removeCriteria = (type, value, silent=false) ->
  @validateType type

  if type is "pathname"
    return if !@criteria.pathname

    delete @criteria.pathname[value]
    if @criteria.pathname? and (Object.keys @criteria.pathname).length is 0
      @criteria.pathname = null

  else if type is "query"
    return if !@criteria.query

    for k,v of value
      delete @criteria.query[k]

    if @criteria.query? and (Object.keys @criteria.query).length is 0
      @criteria.query = null

  @emit "criteria", @criteria if !silent

UrlFilter::checkPathname = (value) ->
  return urlTag.testPathname @criteria.pathname, value

UrlFilter::checkQuery = (key, val) ->
  return false if !@criteria.query

  return @criteria.query[key] is val
