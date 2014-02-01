// Generated by CoffeeScript 1.6.3
(function() {
  var Backbone, QueryCollection, _, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  _ = require("underscore");

  require("underscore-query")(_);

  Backbone = require("backbone");

  module.exports = QueryCollection = (function(_super) {
    __extends(QueryCollection, _super);

    function QueryCollection() {
      this.linkSubCollections = __bind(this.linkSubCollections, this);
      this.onLinkedAdd = __bind(this.onLinkedAdd, this);
      _ref = QueryCollection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    QueryCollection.prototype.query = function(params) {
      if (params) {
        return _.query(this.models, params, "get");
      } else {
        return _.query.build(this.models, "get");
      }
    };

    QueryCollection.prototype.findOne = function(query) {
      return _.query.findOne(this.models, query, "get");
    };

    QueryCollection.prototype.filteredCollection = function(query) {
      var builder, filtered, parent,
        _this = this;
      parent = this;
      filtered = new parent.constructor;
      filtered._query_parent = parent;
      if (query) {
        filtered._query = _.query.tester(query, "get");
        filtered.set(_.query(parent.models, filtered._query, "get"));
      } else {
        filtered._query = function() {
          return false;
        };
        builder = _.query().getter("get");
        builder.set = function() {
          filtered._query = builder.tester();
          return filtered.set(_.query(parent.models, filtered._query, "get"));
        };
      }
      filtered.listenTo(parent, {
        add: function(model) {
          if (filtered._query(model)) {
            return filtered.add(model);
          }
        },
        remove: function(model, collection) {
          if (collection === parent) {
            return filtered.remove(model);
          }
        },
        change: function(model) {
          if (filtered._query(model)) {
            return filtered.add(model);
          } else {
            return filtered.remove(model);
          }
        }
      });
      if (query) {
        return filtered;
      } else {
        return builder;
      }
    };

    QueryCollection.prototype.updateFilter = function(query) {
      var builder,
        _this = this;
      if (!this._query) {
        throw new Error("filteredCollection must be called before updateFilter");
      }
      if (query) {
        this._query = _.query.tester(query, "get");
        return this.set(_.query(this._query_parent.models, this._query, "get"));
      } else {
        builder = _.query().getter("get");
        builder.set = function() {
          _this._query = builder.tester();
          return _this.set(_.query(_this._query_parent.models, _this._query, "get"));
        };
        return builder;
      }
    };

    QueryCollection.prototype.pagedCollection = function(num) {
      var paged, parent,
        _this = this;
      if (num == null) {
        num = 20;
      }
      parent = this;
      paged = new parent.constructor(parent.first(num));
      paged.page = 1;
      paged.numberOfPages = Math.ceil(parent.length / num);
      paged.changePage = function(page) {
        var end, start;
        if (((0 < page && page <= paged.numberOfPages)) || (paged.numberOfPages === 0)) {
          paged.page = page;
          start = (page - 1) * num;
          end = start + (num - 1);
          paged.set(parent.models.slice(start, +end + 1 || 9e9));
          return paged.trigger("page:change");
        }
      };
      paged.listenTo(parent, "add sort reset remove", function() {
        paged.numberOfPages = Math.ceil(parent.length / num);
        if (paged.page > paged.numberOfPages) {
          paged.page = paged.numberOfPages;
        } else if (paged.page === 0) {
          paged.page = 1;
        }
        return paged.changePage(paged.page);
      });
      return paged;
    };

    QueryCollection.prototype.zoomedCollection = function(num) {
      var end, extent, paged, parent, start, _ref1;
      if (num == null) {
        num = 5;
      }
      parent = this;
      extent = function(index) {
        var end, start;
        start = index;
        end = start + num;
        return [start, end];
      };
      _ref1 = extent(parent.length / 2), start = _ref1[0], end = _ref1[1];
      paged = new parent.constructor(parent.models.slice(start, end));
      paged.index = parent.length / 2;
      paged.plus = function() {
        var _ref2;
        if ((paged.index + ((num + 1) / 2)) < parent.length) {
          paged.index += 1;
          _ref2 = extent(paged.index), start = _ref2[0], end = _ref2[1];
          return paged.set(parent.models.slice(start, end));
        }
      };
      paged.minus = function() {
        var _ref2;
        if ((paged.index - ((num - 1) / 2)) > 0) {
          paged.index -= 1;
          _ref2 = extent(paged.index), start = _ref2[0], end = _ref2[1];
          return paged.set(parent.models.slice(start, end));
        }
      };
      paged.goto = function(id) {
        var index, model, _ref2;
        model = parent.get(id);
        index = parent.indexOf(model);
        if (index) {
          paged.index = index;
          _ref2 = extent(paged.index), start = _ref2[0], end = _ref2[1];
          paged.set(parent.models.slice(start, end));
          return model;
        }
      };
      paged.listenTo(parent, "add reset remove", function() {
        var _ref2;
        _ref2 = extent(paged.index), start = _ref2[0], end = _ref2[1];
        return paged.set(parent.models.slice(start, end));
      });
      return paged;
    };

    QueryCollection.prototype.pages = function() {
      var active, end, middle, num, start, _i, _results;
      middle = this.page;
      start = middle - 4;
      if (start < 1) {
        start = 1;
      }
      end = Math.min(start + 8, this.numberOfPages);
      _results = [];
      for (num = _i = start; start <= end ? _i <= end : _i >= end; num = start <= end ? ++_i : --_i) {
        active = num === middle;
        _results.push({
          active: active,
          num: num
        });
      }
      return _results;
    };

    QueryCollection.prototype.pageData = function() {
      return {
        prev: this.page > 1,
        next: this.page < this.numberOfPages,
        start: 0,
        end: this.length,
        count: this.length,
        page: this.page,
        num: this.numberOfPages,
        pages: this.pages()
      };
    };

    QueryCollection.prototype.filterDeleted = function() {
      var _this = this;
      this.on("add", function(model) {
        if (model.get("deleted")) {
          return this.remove(model);
        }
      });
      this.on("change:deleted", function(model, value) {
        if (value) {
          return _.defer(function() {
            return _this.remove(model);
          });
        }
      });
      return this;
    };

    QueryCollection.prototype.onLinkedAdd = function(name) {
      var _this = this;
      return function(model) {
        if (model[name]) {
          if (model.linkedSubs == null) {
            model.linkedSubs = [];
          }
          if (__indexOf.call(model.linkedSubs, name) < 0) {
            return _this.createCollectionLink(model, name);
          }
        }
      };
    };

    QueryCollection.prototype.linkSubCollections = function(collection, name) {
      var onAdd,
        _this = this;
      onAdd = this.onLinkedAdd(name);
      collection.each(onAdd);
      this.listenTo(collection, "add", onAdd);
      this.listenTo(collection, "remove", function(model) {
        if (model[name] && model.linkedSubs && (__indexOf.call(model.linkedSubs, name) >= 0)) {
          return _this.removeCollectionLink(model, name);
        }
      });
      return this;
    };

    QueryCollection.prototype.createCollectionLink = function(model, name) {
      var _this = this;
      model.linkedSubs.push(name);
      this.add(model[name].models);
      this.listenTo(this, "remove", function(m) {
        return model[name].remove(m);
      });
      this.listenTo(model[name], "add", function(model) {
        return _this.add(model);
      });
      return this.listenTo(model[name], "remove", function(m, collection) {
        if (collection === model[name]) {
          return _this.remove(m);
        }
      });
    };

    QueryCollection.prototype.removeCollectionLink = function(model, name) {
      model.linkedSubs = _.without(model.linkedSubs, name);
      this.remove(model[name].models);
      return this.stopListening(model[name]);
    };

    return QueryCollection;

  })(Backbone.Collection);

}).call(this);