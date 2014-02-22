###
  This module is designed to be installed via bower and user via Brunch
  It expects underscore, underscore_query & Backbone to be available globally.
###

_ = (window ? global)._


class ReactiveCollection

  # Main Query method
  query: (params) ->
    if params
      # If a query is provided, then the query is run immediately
      _.query @models, params, "get"

    else
      # If no query is provided then we return a query builder object
      _.query.build @models, "get"

  # Helper method to return the first filtered model
  findOne: (query) -> _.query.findOne @models, query, "get"

  # This method assists in creating live collections that remain updated
  filteredCollection: (query) ->
    parent = @
    #parent.on "all", (e) -> console.log "parent event: #{e}"
    filtered = new parent.constructor
    # Need a reference to the parent in case the filter is updated
    filtered._query_parent = parent

    # A checking function is created to test models against
    # The function is added to the collection instance so that it can later be updated
    if query
      filtered._query = _.query.tester(query, "get")
      # Any existing models on the parent are filtered and added to this collection
      filtered.set _.query(parent.models, filtered._query, "get")

    else
      # No models to be added by default until filter is set
      filtered._query = -> false
      # To allow chaining form
      # col.setFilter(parent).add(a,b).not(c,d).set()
      builder = _.query().getter("get")
      builder.set = =>
        filtered._query = builder.tester()
        # In case the filter is set later we need to ensure any existing models are updated
        filtered.set _.query(parent.models, filtered._query, "get")

    # Listeners are added to the parent collection
    filtered.listenTo parent,
      # Any model added to the parent, will be added to this collection if it passes the test
      add: (model) ->
        if filtered._query(model) then filtered.add(model)
    # Any model removed from the parent will be removed from this collection
      remove: (model, collection) ->
        # events seems to stop propogating on deleting / removing - this is an attempt to fix that
        if collection is parent
          filtered.remove(model)
    # Any model that is changed on the parent will be re-tested
      change: (model) ->
        if filtered._query(model) then filtered.add(model) else filtered.remove(model)

    # Return is dependeant on whether a query was set
    if query then filtered else builder


  updateFilter: (query) ->
    throw new Error "filteredCollection must be called before updateFilter" unless @_query
    if query
      @_query = _.query.tester(query, "get")
      @set _.query(@_query_parent.models, @_query, "get")
    else
      # To allow the form col.updateFilter().and(a,v).set()
      builder = _.query().getter("get")
      builder.set = =>
        @_query = builder.tester()
        @set _.query(@_query_parent.models, @_query, "get")
      builder

  # Returns a new pagination enabled live collection
  # This collection has 2 extra properties:
  # page and numberOfPages
  # It also has an extra method: changePage
  pagedCollection: (num = 20) ->
    parent = @
    paged = new parent.constructor parent.first(num)
    paged.page = 1
    paged.numberOfPages = Math.ceil(parent.length / num)
    paged.changePage = (page) =>
      if (0 < page <= paged.numberOfPages) or (paged.numberOfPages is 0)
        paged.page = page
        start = (page - 1) * num
        end = start + (num - 1)
        paged.set parent.models[start..end]
        paged.trigger "page:change"

    #parent.on "all", (e) -> console.log "filtered event: #{e}"
    #paged.on "all", (e) -> console.log "paged event: #{e}"

    paged.listenTo parent, "add sort reset remove", ->
      paged.numberOfPages = Math.ceil(parent.length / num)
      if paged.page > paged.numberOfPages
        paged.page = paged.numberOfPages
      else if paged.page is 0
        paged.page = 1
      paged.changePage(paged.page)
    paged

  # Similar to paged collectiom, but allows changing by one model at a time rather than page
  zoomedCollection: (num = 5) ->
    parent = @
    extent = (index) ->
      start = index
      end = start + num
      [start,end]
    [start,end] = extent(parent.length / 2)
    paged = new parent.constructor parent.models[start...end]
    paged.index = parent.length / 2
    paged.plus = ->
      if (paged.index + ((num + 1) / 2)) < parent.length
        paged.index +=1
        [start,end] = extent(paged.index)
        paged.set parent.models[start...end]

    paged.minus = ->
      if (paged.index - ((num - 1) / 2)) > 0
        paged.index -=1
        [start,end] = extent(paged.index)
        paged.set parent.models[start...end]

    paged.goto = (id) ->
      model = parent.get(id)
      index = parent.indexOf(model)
      if index
        paged.index = index
        [start,end] = extent(paged.index)
        paged.set parent.models[start...end]
        model



    paged.listenTo parent, "add reset remove", ->
      [start,end] = extent(paged.index)
      paged.set parent.models[start...end]
    paged

  pages: ->
    middle = @page
    start = middle - 4
    if start < 1 then start = 1
    end = Math.min (start + 8), @numberOfPages
    for num in [start..end]
      active = num is middle
      {active, num}

  pageData: ->
    prev: (@page > 1)
    next: (@page < @numberOfPages)
    start:0
    end:@length
    count: @length
    page: @page
    num: @numberOfPages
    pages: @pages()

  # This method can be set up on the main collections to ensure deleted models are removed
  filterDeleted: ->
    @on "add", (model) ->
      if model.get("deleted")
        @remove(model)
    @on "change:deleted", (model, value) =>
      if value
        # need to defer as otherwise messes with looping through models
        _.defer =>
          @remove(model)
    this

  onLinkedAdd: (name) =>
    (model) =>
      if model[name]
        model.linkedSubs ?= []
        unless name in model.linkedSubs
          @createCollectionLink(model, name)

  linkSubCollections: (collection, name) =>
    onAdd = @onLinkedAdd(name)
    collection.each(onAdd)
    @listenTo collection, "add", onAdd
    @listenTo collection, "remove", (model) =>
      if model[name] and model.linkedSubs and (name in model.linkedSubs)
        @removeCollectionLink(model, name)
    this

  createCollectionLink: (model, name) ->
    model.linkedSubs.push(name)
    @add model[name].models
    @listenTo @, "remove", (m) => model[name].remove(m)
    @listenTo model[name], "add", (model) => @add(model)
    @listenTo model[name], "remove", (m, collection) =>
      if collection is model[name]
        @remove(m)

  removeCollectionLink: (model, name) ->
    model.linkedSubs = _.without(model.linkedSubs, name)
    @remove model[name].models
    @stopListening model[name]


if require and require.brunch
  require.register "reactive-backbone", (exports, require, module) ->
    module.exports = ReactiveCollection

else
  _ = require "underscore"
  require("underscore-query")(_)
  module.exports = ReactiveCollection


