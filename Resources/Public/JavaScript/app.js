(function() {
  var TYPO3, convertToSimpleObject,
    __hasProp = Object.prototype.hasOwnProperty;

  TYPO3 = window.TYPO3 || {};

  window.TYPO3 = TYPO3;

  TYPO3.FormBuilder = Ember.Application.create({
    rootElement: 'body'
  });

  TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION;

  window.setTimeout((function() {
    var o, r;
    TYPO3.FormBuilder.Model.AvailableFormElements.set('content', [
      {
        type: 'TYPO3.Form:Textbox',
        label: 'Text Box'
      }, {
        type: 'TYPO3.Form:Textfield',
        label: 'Text Field'
      }
    ]);
    o = function(obj) {
      return Ember.Object.create(obj);
    };
    r = function(obj) {
      return TYPO3.FormBuilder.Model.Renderable.create(obj);
    };
    TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create({
      identifier: 'myForm',
      renderables: [
        {
          type: 'TYPO3.Form:Page',
          identifier: 'myPage',
          renderables: [
            {
              identifier: 'foobarbaz',
              type: 'TYPO3.Form:Textfield',
              label: 'My Label'
            }
          ]
        }, {
          type: 'TYPO3.Form:Page',
          identifier: 'myPage2'
        }
      ]
    }));
    return window.setTimeout(function() {
      return console.log(TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition')));
    }, 2000);
  }), 2000);

  TYPO3.FormBuilder.Utility = {};

  convertToSimpleObject = function(input) {
    var key, simpleObject, value;
    simpleObject = {};
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      value = input[key];
      if (key.match(/^__/) || key === 'parentRenderable') continue;
      if (!value) {} else if (typeof value === 'function') {} else if (typeof value === 'object') {
        simpleObject[key] = convertToSimpleObject(value);
      } else {
        simpleObject[key] = value;
      }
    }
    return simpleObject;
  };

  TYPO3.FormBuilder.Utility.convertToSimpleObject = convertToSimpleObject;

  TYPO3.FormBuilder.Model = {};

  TYPO3.FormBuilder.Model.AvailableFormElements = Ember.ArrayController.create();

  TYPO3.FormBuilder.Model.Renderable = Ember.Object.extend({
    parentRenderable: null,
    renderables: null,
    __nestedPropertyChange: 0,
    init: function() {
      this.renderables = [];
      return this.renderables.addArrayObserver(this);
    },
    somePropertyChanged: function(theInstance, propertyName) {
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables." + (this.parentRenderable.get('renderables').indexOf(this)) + "." + propertyName);
      }
    },
    arrayWillChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref, _results;
      _results = [];
      for (i = startIndex, _ref = startIndex + removeCount; startIndex <= _ref ? i < _ref : i > _ref; startIndex <= _ref ? i++ : i--) {
        _results.push(subArray.objectAt(i).set('parentRenderable', null));
      }
      return _results;
    },
    arrayDidChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref, _results;
      console.log('arrayDidChange', arguments);
      _results = [];
      for (i = startIndex, _ref = startIndex + addCount; startIndex <= _ref ? i < _ref : i > _ref; startIndex <= _ref ? i++ : i--) {
        _results.push(subArray.objectAt(i).set('parentRenderable', this));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.Model.Renderable.reopenClass({
    create: function(obj) {
      var childRenderable, childRenderables, k, renderable, v, _i, _len;
      childRenderables = obj.renderables;
      delete obj.renderables;
      renderable = Ember.Object.create.call(TYPO3.FormBuilder.Model.Renderable, obj);
      for (k in obj) {
        v = obj[k];
        renderable.addObserver(k, renderable, 'somePropertyChanged');
      }
      if (childRenderables) {
        for (_i = 0, _len = childRenderables.length; _i < _len; _i++) {
          childRenderable = childRenderables[_i];
          renderable.get('renderables').pushObject(TYPO3.FormBuilder.Model.Renderable.create(childRenderable));
        }
      }
      return renderable;
    }
  });

  TYPO3.FormBuilder.Model.Form = Ember.Object.create({
    formDefinition: null
  });

  TYPO3.FormBuilder.View = {};

  TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.CollectionView.extend({
    contentBinding: 'TYPO3.FormBuilder.Model.AvailableFormElements.content',
    click: function() {
      return console.log('click');
    },
    itemViewClass: Ember.View.extend({
      templateName: 'item',
      didInsertElement: function() {
        return this.$().draggable({
          connectToSortable: '.typo3-form-sortable',
          helper: function() {
            return $('<div>' + $(this).html() + '</div>');
          },
          revert: 'invalid'
        });
      }
    })
  });

  TYPO3.FormBuilder.View.FormPageView = Ember.View.extend({
    formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
    currentPageIndex: 0,
    page: Ember.computed(function() {
      var _ref;
      return (_ref = this.get('formPages')) != null ? _ref.get(this.get('currentPageIndex')) : void 0;
    }).property('formPages', 'currentPageIndex').cacheable(),
    renderPageIfPageObjectChanges: (function() {
      var formDefinition, _ref,
        _this = this;
      if (!((_ref = TYPO3.FormBuilder.Model.Form.get('formDefinition')) != null ? _ref.get('identifier') : void 0)) {
        return;
      }
      formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
      console.log("POST: ", formDefinition);
      return $.post(TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer, {
        formDefinition: formDefinition
      }, function(data) {
        _this.$().html(data);
        return _this.postProcessRenderedPage();
      });
    }).observes('page', 'page.__nestedPropertyChange'),
    postProcessRenderedPage: function() {
      return this.$().find('fieldset').addClass('typo3-form-sortable').sortable({
        revert: 'true'
      });
    }
  });

}).call(this);
