_ = require "underscore"
Collection = require "../reactive-backbone"
{ok, equal} = require "assert"

make = ->
  new Collection [
    {title:"Home", colors:["red","yellow","blue"], likes:12, featured:true, content: "Dummy content about coffeescript"}
    {title:"About", colors:["red"], likes:2, featured:true, content: "dummy content about javascript"}
    {title:"Contact", colors:["red","blue"], likes:20, content: "Dummy content about PHP"}
  ]

make2 = ->
  a = make()
  i = 0
  a.each (model) ->
    model.txs = new Collection
    model.txs.filterDeleted()
    model.txs.add [{a:i++}, {a:i++}, {a:i++}, {a:i++}]
  a

make3 = ->
  a = make()
  i = 0
  a.each (model) ->
    model.txs = new Collection [{a:i++}, {a:i++}, {a:i++}, {a:i++}]
  a


describe "filtered collections", ->

  it "can filter", ->
    a = make()
    b = a.filteredCollection {title:"Home"}
    equal b.length, 1


  it "can live filter", ->
    a = make()
    b = a.filteredCollection {title:"Home"}
    equal b.length, 1
    a.at(0).set("title","updated")
    equal b.length, 0


describe "paged collection", ->

  it "can page", ->
    a = make()
    b = a.pagedCollection(2)
    equal b.length, 2
    equal b.page, 1
    b.changePage(2)
    equal b.page, 2
    equal b.length, 1
    equal b.at(0), a.at(2)

describe "zoomed collection", ->

  it "can zoom", ->
    a = make()
    b = make()
    c = new Collection a.models
    c.add b.models
    equal c.length, 6
    d = c.zoomedCollection(3)
    equal d.length, 3
    equal d.first(), b.at(0)
    d.minus()
    equal d.first(), a.last()


describe "filter and page", ->

  it "can filter and page", ->

    a = make()
    b = a.filteredCollection {title:"Home"}
    c = a.filteredCollection {likes:$gt:0}
    equal b.length, 1
    equal c.length, 3
    d = c.pagedCollection(3)
    equal d.length, 3
    a.first().set("title","Updated")
    equal b.length, 0
    equal c.length, 3
    equal d.length, 3

  it "delete from parent", ->

    a = make()
    b = a.filteredCollection {title:"Home"}
    c = a.filteredCollection {likes:$gt:0}
    equal b.length, 1
    equal c.length, 3
    d = c.pagedCollection(3)
    equal d.length, 3
    a.remove a.at(0)
    equal b.length, 0
    equal c.length, 2
    equal d.length, 2

  it "delete from child", ->

    a = make()
    b = a.filteredCollection {title:"Home"}
    c = a.filteredCollection {likes:$gt:0}
    equal b.length, 1
    equal c.length, 3
    d = c.pagedCollection(3)
    equal d.length, 3
    d.remove(d.at(0))
    equal b.length, 1
    equal c.length, 3
    equal d.length, 2


describe "linkedCollections", ->

  it "can link", ->
    a = make2()
    equal a.length, 3
    b = new Collection
    b.linkSubCollections(a, "txs")
    equal b.length, 12

  it "can handle removal", ->
    a = make2()
    equal a.length, 3
    b = new Collection
    b.linkSubCollections(a, "txs")
    equal b.length, 12
    a.remove(a.first())
    equal b.length, 8

  it "can handle adding", ->
    a = make2()
    equal a.length, 3
    b = new Collection
    b.linkSubCollections(a, "txs")
    equal b.length, 12
    c = make2()
    a.add c.models
    equal b.length, 24

  it "can handle adding to subcollection", ->
    a = make2()
    equal a.length, 3
    b = new Collection
    b.linkSubCollections(a, "txs")
    equal b.length, 12
    a.at(0).txs.add {isNew:true}
    equal b.length, 13

  it "can handle removing from subcollection", ->
    a = make2()
    equal a.length, 3
    b = new Collection
    b.linkSubCollections(a, "txs")
    equal b.length, 12
    a.at(0).txs.remove a.at(0).txs.first()
    equal b.length, 11

describe "deletion", ->

  it "can handle changing to deleted", (done) ->

    a = make2()
    b = new Collection
    b.linkSubCollections(a, "txs")
    equal b.length, 12
    b.at(0).set("deleted", true)
    _.defer ->
      equal b.length, 11
      equal a.at(0).txs.length, 3
      done()

  it "can handle changing to deleted", (done) ->

    a = make3()
    b = new Collection
    b.linkSubCollections(a, "txs").filterDeleted()

    equal b.length, 12
    model = b.at(0)
    equal model, a.at(0).txs.at(0)
    model.set("deleted", true)

    _.defer ->
      equal b.length, 11
      equal b.indexOf(model), -1
      equal a.at(0).txs.indexOf(model), -1
      equal a.at(0).txs.length, 3
      done()

  it "can handle changing to deleted with paged collections", (done) ->

    a = make3()
    b = new Collection
    b.linkSubCollections(a, "txs").filterDeleted()
    c = b.pagedCollection(3)

    equal b.length, 12
    equal c.length, 3
    model = b.at(0)
    equal model, a.at(0).txs.at(0)
    equal model, c.at(0)

    model.set("deleted", true)

    _.defer ->
      equal b.length, 11
      equal b.indexOf(model), -1
      equal a.at(0).txs.indexOf(model), -1
      equal a.at(0).txs.length, 3
      equal c.length, 3
      equal c.indexOf(model), -1
      done()

  it "can handle changing to deleted with paged and filtered collections", (done) ->

    a = make3()
    b = new Collection
    b.linkSubCollections(a, "txs").filterDeleted()
    c = b.filteredCollection a:$lt:3
    equal c.length, 3
    d = c.pagedCollection(2)
    equal d.length, 2

    equal b.length, 12

    model = b.at(0)
    equal model, a.at(0).txs.at(0)
    equal model, c.at(0)
    equal model, d.at(0)
    ok (model.get("a") < 3)


    model.set("deleted", true)

    _.defer ->
      equal b.length, 11
      equal b.indexOf(model), -1
      equal a.at(0).txs.indexOf(model), -1
      equal a.at(0).txs.length, 3
      equal c.length, 2
      equal c.indexOf(model), -1
      equal d.length, 2
      equal d.indexOf(model), -1
      done()















