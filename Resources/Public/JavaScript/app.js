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
    var o;
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
    return TYPO3.FormBuilder.Model.FormDefinition.setProperties({
      identifier: 'myForm',
      pages: [
        o({
          type: 'TYPO3.Form:Page',
          identifier: 'myPage'
        })
      ]
    });
  }), 2000);

  TYPO3.FormBuilder.Utility = {};

  convertToSimpleObject = function(input) {
    var key, simpleObject, value;
    simpleObject = {};
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      value = input[key];
      if (key.match(/^__/)) continue;
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

  TYPO3.FormBuilder.Model.FormDefinition = Ember.Object.create();

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
    formPagesBinding: 'TYPO3.FormBuilder.Model.FormDefinition.pages',
    currentPageIndex: 0,
    page: Ember.computed(function() {
      var _ref;
      return (_ref = this.get('formPages')) != null ? _ref.get(this.get('currentPageIndex')) : void 0;
    }).property('formPages', 'currentPageIndex').cacheable(),
    renderPageIfPageObjectChanges: (function() {
      var formDefinition,
        _this = this;
      formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.FormDefinition);
      return $.post(TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer, {
        formDefinition: formDefinition
      }, function(data) {
        _this.$().html(data);
        return _this.postProcessRenderedPage();
      });
    }).observes('page'),
    postProcessRenderedPage: function() {
      return this.$().find('fieldset').addClass('typo3-form-sortable').sortable({
        revert: 'true'
      });
    }
  });

}).call(this);
