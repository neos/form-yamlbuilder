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
    return TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create({
      identifier: 'myForm',
      renderables: [
        {
          type: 'TYPO3.Form:Page',
          identifier: 'myPage',
          label: 'My Page 1',
          renderables: [
            {
              identifier: 'foobarbaz',
              type: 'TYPO3.Form:Textfield',
              label: 'My Label'
            }, {
              identifier: 'foobarbaz2',
              type: 'TYPO3.Form:Textfield',
              label: 'My Label'
            }, {
              identifier: 'gender',
              type: 'TYPO3.Form:Radiobuttons',
              label: 'Gender',
              properties: {
                options: [
                  {
                    _key: 'm',
                    _value: 'Male'
                  }, {
                    _key: 'f',
                    _value: 'Female'
                  }
                ]
              }
            }
          ]
        }, {
          type: 'TYPO3.Form:Page',
          identifier: 'myPage2',
          label: ''
        }
      ]
    }));
  }), 2000);

  TYPO3.FormBuilder.Utility = {};

  convertToSimpleObject = function(input) {
    var key, simpleObject, value;
    simpleObject = {};
    for (key in input) {
      if (!__hasProp.call(input, key)) continue;
      value = input[key];
      if (key.match(/^__/) || key === 'parentRenderable') continue;
      if (typeof value === 'function') {} else if (typeof value === 'object') {
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
      var i, _ref;
      for (i = startIndex, _ref = startIndex + addCount; startIndex <= _ref ? i < _ref : i > _ref; startIndex <= _ref ? i++ : i--) {
        subArray.objectAt(i).set('parentRenderable', this);
      }
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables");
      }
    },
    _path: (function() {
      if (this.parentRenderable) {
        return "" + (this.parentRenderable.get('_path')) + ".renderables." + (this.parentRenderable.get('renderables').indexOf(this));
      } else {
        return '';
      }
    }).property()
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

  TYPO3.FormBuilder.Model.FormElementType = Ember.Object.extend({
    _isCompositeRenderable: false
  });

  TYPO3.FormBuilder.Model.FormElementTypes = Ember.Object.create({
    init: function() {
      var typeConfiguration, typeName, _ref, _results;
      _ref = TYPO3.FormBuilder.Configuration.formElementTypes;
      _results = [];
      for (typeName in _ref) {
        typeConfiguration = _ref[typeName];
        _results.push(this.set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.Model.Form = Ember.Object.create({
    formDefinition: null,
    currentlySelectedRenderable: null
  });

  TYPO3.FormBuilder.View = {};

  TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.CollectionView.extend({
    contentBinding: 'TYPO3.FormBuilder.Model.AvailableFormElements.content',
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

  TYPO3.FormBuilder.View.FormStructure = Ember.View.extend({
    formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition',
    didInsertElement: function() {
      this.$().dynatree({
        onActivate: function(node) {
          return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', node.data.formRenderable);
        },
        dnd: {
          onDragStart: function() {
            return true;
          },
          autoExpandMS: 300,
          onDragEnter: function(targetNode, sourceNode) {
            var targetNodeIsCompositeRenderable;
            targetNodeIsCompositeRenderable = TYPO3.FormBuilder.Model.FormElementTypes.get("" + (targetNode.data.formRenderable.get('type')) + "._isCompositeRenderable");
            if (sourceNode.getLevel() === 1) {
              if (targetNode.getLevel() === 1) {
                return ['before', 'after'];
              } else {
                return false;
              }
            } else {
              if (targetNode.getLevel() === 1) {
                return ['over'];
              } else {
                if (targetNodeIsCompositeRenderable) {
                  return ['before', 'over', 'after'];
                } else {
                  return ['before', 'after'];
                }
              }
            }
          },
          onDrop: function(targetNode, sourceNode, hitMode) {
            var indexOfTargetRenderable, sourceRenderable, targetRenderable;
            sourceRenderable = sourceNode.data.formRenderable;
            targetRenderable = targetNode.data.formRenderable;
            sourceRenderable.getPath('parentRenderable.renderables').removeObject(sourceRenderable);
            if (hitMode === 'over') {
              return targetRenderable.get('renderables').pushObject(sourceRenderable);
            } else {
              indexOfTargetRenderable = targetRenderable.getPath('parentRenderable.renderables').indexOf(targetRenderable);
              if (hitMode === 'before') {
                return targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable, sourceRenderable);
              } else {
                return targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable + 1, sourceRenderable);
              }
            }
          }
        }
      });
      return this.updateTreeStateFromModel(this.$().dynatree('getRoot'), this.getPath('formDefinition.renderables'));
    },
    updateTree: (function() {
      var activeNodePath, expandedNodePath, expandedNodePaths, _base, _i, _len, _ref, _ref2;
      if (!this.$().dynatree('getTree').visit) return;
      expandedNodePaths = [];
      this.$().dynatree('getTree').visit(function(node) {
        if (node.isExpanded()) return expandedNodePaths.push(node.data.key);
      });
      activeNodePath = (_ref = this.$().dynatree('getActiveNode')) != null ? _ref.data.key : void 0;
      if (typeof (_base = this.$().dynatree('getRoot')).removeChildren === "function") {
        _base.removeChildren();
      }
      this.updateTreeStateFromModel(this.$().dynatree('getRoot'), this.getPath('formDefinition.renderables'));
      for (_i = 0, _len = expandedNodePaths.length; _i < _len; _i++) {
        expandedNodePath = expandedNodePaths[_i];
        this.$().dynatree('getTree').getNodeByKey(expandedNodePath).expand(true);
      }
      return (_ref2 = this.$().dynatree('getTree').getNodeByKey(activeNodePath)) != null ? _ref2.activate(true) : void 0;
    }).observes('formDefinition.__nestedPropertyChange'),
    updateTreeStateFromModel: function(dynaTreeParentNode, currentListOfSubRenderables) {
      var newNode, subRenderable, _i, _len, _results;
      if (!currentListOfSubRenderables) return;
      _results = [];
      for (_i = 0, _len = currentListOfSubRenderables.length; _i < _len; _i++) {
        subRenderable = currentListOfSubRenderables[_i];
        newNode = dynaTreeParentNode.addChild({
          key: subRenderable.get('_path'),
          title: subRenderable.label ? subRenderable.label : subRenderable.identifier,
          formRenderable: subRenderable
        });
        _results.push(this.updateTreeStateFromModel(newNode, subRenderable.getPath('renderables')));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.View.FormElementInspector = Ember.View.extend({
    templateName: 'formElementInspector',
    formElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable',
    formElementType: (function() {
      var formElementTypeName;
      formElementTypeName = this.getPath('formElement.type');
      if (!formElementTypeName) return null;
      return TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
    }).property('formElement', 'formElement.type').cacheable()
  });

  TYPO3.FormBuilder.View.FormElementInspectorPart = Ember.ContainerView.extend({
    formElement: null,
    propertyPath: null,
    schema: null,
    orderedSchema: (function() {
      var k, orderedSchema, schema, v;
      schema = $.extend({}, this.get('schema'));
      orderedSchema = (function() {
        var _results;
        _results = [];
        for (k in schema) {
          v = schema[k];
          v['key'] = k;
          _results.push(v);
        }
        return _results;
      })();
      orderedSchema.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return orderedSchema;
    }).property('schema').cacheable(),
    render: function() {
      var formElement, pathToCurrentValue, schemaElement, subViewClass, subViewOptions, _i, _len, _ref;
      if (!this.formElement) return;
      formElement = this.formElement;
      _ref = this.get('orderedSchema');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        schemaElement = _ref[_i];
        console.log(schemaElement);
        subViewClass = Ember.getPath(schemaElement.viewName);
        if (!subViewClass) {
          throw "Editor class '" + schemaElement.viewName + "' not found";
        }
        pathToCurrentValue = this.propertyPath + '.' + schemaElement.key;
        subViewOptions = $.extend({}, schemaElement.viewOptions, {
          _pathToCurrentValue: pathToCurrentValue,
          value: formElement.getPath(pathToCurrentValue),
          changed: function() {
            formElement.setPath(this._pathToCurrentValue, this.value);
            return formElement.somePropertyChanged(formElement, this._pathToCurrentValue);
          }
        });
        this.appendChild(subViewClass.create(subViewOptions));
      }
      return this._super();
    },
    onFormElementChange: (function() {
      return this.rerender();
    }).observes('formElement')
  });

  TYPO3.FormBuilder.View.Editor = {};

  TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend({
    value: null,
    changed: Ember.K
  });

  TYPO3.FormBuilder.View.Editor.PropertyGrid = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({
    columns: null,
    options: {
      enableColumnReorder: false,
      autoHeight: true,
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: false
    },
    grid: null,
    didInsertElement: function() {
      var _this = this;
      this.grid = new Slick.Grid(this.$(), this.value, this.columns, this.options);
      this.grid.setSelectionModel(new Slick.CellSelectionModel());
      this.grid.onCellChange.subscribe(function(e, args) {
        _this.value.replace(args.row, 1, args.item);
        return _this.changed();
      });
      return this.grid.onAddNewRow.subscribe(function(e, args) {
        var columnDefinition, newItem, _i, _len, _ref;
        _this.grid.invalidateRow(_this.value.length);
        newItem = {};
        _ref = _this.columns;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          columnDefinition = _ref[_i];
          newItem[columnDefinition.field] = '';
        }
        $.extend(newItem, args.item);
        console.log("add new row", newItem);
        _this.value.push(newItem);
        console.log(_this.value);
        _this.grid.updateRowCount();
        _this.grid.render();
        return _this.changed();
      });
    }
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
      console.log("POST DATA");
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
