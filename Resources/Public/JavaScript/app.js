(function() {
  var TYPO3, convertToSimpleObject, cssFile, _i, _len, _ref, _ref2, _ref3, _ref4,
    _this = this,
    __hasProp = Object.prototype.hasOwnProperty;

  TYPO3 = window.TYPO3 || {};

  window.TYPO3 = TYPO3;

  window.onbeforeunload = function(e) {
    var text;
    if (!TYPO3.FormBuilder.Model.Form.get('unsavedContent')) return;
    e = e || window.event;
    text = 'There is unsaved content. Are you sure that you want to close the browser?';
    if (e) e.returnValue = text;
    return text;
  };

  TYPO3.FormBuilder = Ember.Application.create({
    rootElement: 'body',
    save: function() {
      var formDefinition, _ref,
        _this = this;
      formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
      return $.post(TYPO3.FormBuilder.Configuration.endpoints.saveForm, {
        formPersistenceIdentifier: (_ref = TYPO3.FormBuilder.Configuration) != null ? _ref.formPersistenceIdentifier : void 0,
        formDefinition: formDefinition
      }, function(data, textStatus, jqXHR) {
        return TYPO3.FormBuilder.Model.Form.set('unsavedContent', false);
      });
    }
  });

  TYPO3.FormBuilder.Configuration = window.FORMBUILDER_CONFIGURATION;

  if ((_ref = TYPO3.FormBuilder.Configuration) != null ? _ref.cssFiles : void 0) {
    _ref2 = TYPO3.FormBuilder.Configuration.cssFiles;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      cssFile = _ref2[_i];
      $('head').append($('<link rel="stylesheet" />').attr('href', cssFile));
    }
  }

  if ((_ref3 = TYPO3.FormBuilder.Configuration) != null ? _ref3.formPersistenceIdentifier : void 0) {
    $.getJSON(TYPO3.FormBuilder.Configuration.endpoints.loadForm, {
      formPersistenceIdentifier: (_ref4 = TYPO3.FormBuilder.Configuration) != null ? _ref4.formPersistenceIdentifier : void 0
    }, function(data, textStatus, jqXHR) {
      return TYPO3.FormBuilder.Model.Form.set('formDefinition', TYPO3.FormBuilder.Model.Renderable.create(data));
    });
  }

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

  TYPO3.FormBuilder.Model.Form = Ember.Object.create({
    formDefinition: null,
    unsavedContent: false,
    currentlySelectedRenderable: null,
    onFormDefinitionChange: (function() {
      if (!this.get('formDefinition')) return;
      return this.set('currentlySelectedRenderable', this.get('formDefinition'));
    }).observes('formDefinition'),
    setUnsavedContentFalseWhenLoadingFormDefinition: (function() {
      return this.set('unsavedContent', false);
    }).observes('formDefinition'),
    contentChanged: (function() {
      return this.set('unsavedContent', true);
    }).observes('formDefinition.__nestedPropertyChange')
  });

  TYPO3.FormBuilder.Model.Renderable = Ember.Object.extend({
    parentRenderable: null,
    renderables: null,
    __nestedPropertyChange: 0,
    type: null,
    typeDefinition: (function() {
      var formElementTypeName;
      formElementTypeName = this.get('type');
      if (!formElementTypeName) return null;
      return TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
    }).property('type').cacheable(),
    init: function() {
      this.renderables = [];
      return this.renderables.addArrayObserver(this);
    },
    setUnknownProperty: function(k, v) {
      this[k] = v;
      this.addObserver(k, this, 'somePropertyChanged');
      return this.somePropertyChanged(this, k);
    },
    setPathRecursively: function(path, v) {
      var currentObject, firstPartOfPath;
      currentObject = this;
      while (path.indexOf('.') > 0) {
        firstPartOfPath = path.slice(0, path.indexOf('.'));
        path = path.slice(firstPartOfPath.length + 1);
        if (!currentObject[firstPartOfPath]) currentObject[firstPartOfPath] = {};
        currentObject = currentObject[firstPartOfPath];
      }
      return currentObject[path] = v;
    },
    somePropertyChanged: function(theInstance, propertyName) {
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables." + (this.parentRenderable.get('renderables').indexOf(this)) + "." + propertyName);
      }
    },
    arrayWillChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref5, _results;
      _results = [];
      for (i = startIndex, _ref5 = startIndex + removeCount; startIndex <= _ref5 ? i < _ref5 : i > _ref5; startIndex <= _ref5 ? i++ : i--) {
        _results.push(subArray.objectAt(i).set('parentRenderable', null));
      }
      return _results;
    },
    arrayDidChange: function(subArray, startIndex, removeCount, addCount) {
      var i, _ref5;
      for (i = startIndex, _ref5 = startIndex + addCount; startIndex <= _ref5 ? i < _ref5 : i > _ref5; startIndex <= _ref5 ? i++ : i--) {
        subArray.objectAt(i).set('parentRenderable', this);
      }
      this.set('__nestedPropertyChange', this.get('__nestedPropertyChange') + 1);
      if (this.parentRenderable) {
        return this.parentRenderable.somePropertyChanged(this.parentRenderable, "renderables." + (this.parentRenderable.get('renderables').indexOf(this)) + ".renderables");
      }
    },
    _path: (function() {
      if (this.parentRenderable) {
        return "" + (this.parentRenderable.get('_path')) + ".renderables." + (this.parentRenderable.get('renderables').indexOf(this));
      } else {
        return '';
      }
    }).property(),
    findEnclosingPage: function() {
      var referenceRenderable;
      referenceRenderable = this;
      while (referenceRenderable.getPath('parentRenderable.parentRenderable') !== null) {
        referenceRenderable = referenceRenderable.get('parentRenderable');
      }
      return referenceRenderable;
    }
  });

  TYPO3.FormBuilder.Model.Renderable.reopenClass({
    create: function(obj) {
      var childRenderable, childRenderables, k, renderable, v, _j, _len2;
      childRenderables = obj.renderables;
      delete obj.renderables;
      renderable = Ember.Object.create.call(TYPO3.FormBuilder.Model.Renderable, obj);
      for (k in obj) {
        v = obj[k];
        renderable.addObserver(k, renderable, 'somePropertyChanged');
      }
      if (childRenderables) {
        for (_j = 0, _len2 = childRenderables.length; _j < _len2; _j++) {
          childRenderable = childRenderables[_j];
          renderable.get('renderables').pushObject(TYPO3.FormBuilder.Model.Renderable.create(childRenderable));
        }
      }
      return renderable;
    }
  });

  TYPO3.FormBuilder.Model.FormElementType = Ember.Object.extend({
    type: null,
    __cssClassNames: (function() {
      return "formbuilder-group-" + (this.getPath('formBuilder.group')) + " formbuilder-type-" + (this.get('type').toLowerCase().replace(/[^a-z0-9]/g, '-'));
    }).property('formBuilder.group', 'type').cacheable()
  });

  TYPO3.FormBuilder.Model.FormElementTypes = Ember.Object.create({
    allTypeNames: [],
    init: function() {
      var typeConfiguration, typeName, _ref5, _ref6, _results;
      if (((_ref5 = TYPO3.FormBuilder.Configuration) != null ? _ref5.formElementTypes : void 0) == null) {
        return;
      }
      _ref6 = TYPO3.FormBuilder.Configuration.formElementTypes;
      _results = [];
      for (typeName in _ref6) {
        typeConfiguration = _ref6[typeName];
        typeConfiguration.type = typeName;
        this.allTypeNames.push(typeName);
        _results.push(this.set(typeName, TYPO3.FormBuilder.Model.FormElementType.create(typeConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.Model.FormElementGroups = Ember.Object.create({
    allGroupNames: [],
    init: function() {
      var groupConfiguration, groupName, _ref5, _ref6, _results;
      if (((_ref5 = TYPO3.FormBuilder.Configuration) != null ? _ref5.formElementGroups : void 0) == null) {
        return;
      }
      _ref6 = TYPO3.FormBuilder.Configuration.formElementGroups;
      _results = [];
      for (groupName in _ref6) {
        groupConfiguration = _ref6[groupName];
        this.allGroupNames.push(groupName);
        _results.push(this.set(groupName, Ember.Object.create(groupConfiguration)));
      }
      return _results;
    }
  });

  TYPO3.FormBuilder.View = {};

  TYPO3.FormBuilder.View.FormPageView = Ember.View.extend({
    formPagesBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition.renderables',
    currentPageIndex: (function() {
      var currentlySelectedRenderable, enclosingPage;
      currentlySelectedRenderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable');
      if (!currentlySelectedRenderable) return 0;
      enclosingPage = currentlySelectedRenderable.findEnclosingPage();
      if (!enclosingPage) return 0;
      if (!enclosingPage.getPath('parentRenderable.renderables')) return 0;
      return enclosingPage.getPath('parentRenderable.renderables').indexOf(enclosingPage);
    }).property('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable').cacheable(),
    page: Ember.computed(function() {
      var _ref5;
      return (_ref5 = this.get('formPages')) != null ? _ref5.get(this.get('currentPageIndex')) : void 0;
    }).property('formPages', 'currentPageIndex').cacheable(),
    currentAjaxRequest: null,
    renderPageIfPageObjectChanges: (function() {
      var _this = this;
      if (!TYPO3.FormBuilder.Model.Form.getPath('formDefinition.identifier')) {
        return;
      }
      if (this.currentAjaxRequest) this.currentAjaxRequest.abort();
      if (this.timeout) window.clearTimeout(this.timeout);
      return this.timeout = window.setTimeout(function() {
        var formDefinition;
        formDefinition = TYPO3.FormBuilder.Utility.convertToSimpleObject(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
        return _this.currentAjaxRequest = $.post(TYPO3.FormBuilder.Configuration.endpoints.formPageRenderer, {
          formDefinition: formDefinition,
          currentPageIndex: _this.get('currentPageIndex')
        }, function(data, textStatus, jqXHR) {
          if (_this.currentAjaxRequest !== jqXHR) return;
          _this.$().html(data);
          return _this.postProcessRenderedPage();
        });
      }, 300);
    }).observes('page', 'page.__nestedPropertyChange'),
    postProcessRenderedPage: function() {
      var _this = this;
      this.onCurrentElementChanges();
      return this.$().find('[data-element]').parent().addClass('typo3-form-sortable').sortable({
        revert: 'true',
        update: function(e, o) {
          var movedRenderable, nextElement, nextElementPath, pathOfMovedElement, previousElement, previousElementPath, referenceElementIndex;
          pathOfMovedElement = $(o.item.context).attr('data-element');
          movedRenderable = _this.findRenderableForPath(pathOfMovedElement);
          movedRenderable.getPath('parentRenderable.renderables').removeObject(movedRenderable);
          nextElementPath = $(o.item.context).nextAll('[data-element]').first().attr('data-element');
          if (nextElementPath) {
            nextElement = _this.findRenderableForPath(nextElementPath);
          }
          previousElementPath = $(o.item.context).prevAll('[data-element]').first().attr('data-element');
          if (previousElementPath) {
            previousElement = _this.findRenderableForPath(previousElementPath);
          }
          if (nextElement) {
            referenceElementIndex = nextElement.getPath('parentRenderable.renderables').indexOf(nextElement);
            return nextElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex, movedRenderable);
          } else if (previousElement) {
            referenceElementIndex = previousElement.getPath('parentRenderable.renderables').indexOf(previousElement);
            return previousElement.getPath('parentRenderable.renderables').insertAt(referenceElementIndex + 1, movedRenderable);
          } else {
            throw 'Next Element or Previous Element need to be set. Should not happen...';
          }
        }
      });
    },
    onCurrentElementChanges: (function() {
      var identifierPath, renderable;
      renderable = TYPO3.FormBuilder.Model.Form.get('currentlySelectedRenderable');
      if (!renderable) return;
      this.$().find('.formbuilder-form-element-selected').removeClass('formbuilder-form-element-selected');
      identifierPath = renderable.identifier;
      while (renderable = renderable.parentRenderable) {
        identifierPath = renderable.identifier + '/' + identifierPath;
      }
      return this.$().find('[data-element="' + identifierPath + '"]').addClass('formbuilder-form-element-selected');
    }).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'),
    click: function(e) {
      var pathToClickedElement;
      pathToClickedElement = $(e.target).closest('[data-element]').attr('data-element');
      if (!pathToClickedElement) return;
      return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', this.findRenderableForPath(pathToClickedElement));
    },
    findRenderableForPath: function(path) {
      var currentRenderable, expandedPathToClickedElement, pathPart, renderable, _j, _k, _len2, _len3, _ref5;
      expandedPathToClickedElement = path.split('/');
      expandedPathToClickedElement.shift();
      expandedPathToClickedElement.shift();
      currentRenderable = this.get('page');
      for (_j = 0, _len2 = expandedPathToClickedElement.length; _j < _len2; _j++) {
        pathPart = expandedPathToClickedElement[_j];
        _ref5 = currentRenderable.get('renderables');
        for (_k = 0, _len3 = _ref5.length; _k < _len3; _k++) {
          renderable = _ref5[_k];
          if (renderable.identifier === pathPart) {
            currentRenderable = renderable;
            break;
          }
        }
      }
      return currentRenderable;
    }
  });

  TYPO3.FormBuilder.View.ContainerView = Ember.ContainerView.extend({
    instanciatedViews: null,
    onInstanciatedViewsChange: (function() {
      var view, _j, _len2, _ref5, _results;
      this.removeAllChildren();
      _ref5 = this.get('instanciatedViews');
      _results = [];
      for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
        view = _ref5[_j];
        _results.push(this.get('childViews').pushObject(view));
      }
      return _results;
    }).observes('instanciatedViews')
  });

  TYPO3.FormBuilder.View.Select = Ember.Select.extend({
    attributeBindings: ['disabled']
  });

  TYPO3.FormBuilder.View.AvailableFormElementsView = Ember.View.extend({
    classNames: ['availableFormElements'],
    templateName: 'AvailableFormElements',
    allFormElementTypesBinding: 'TYPO3.FormBuilder.Model.FormElementTypes.allTypeNames',
    formElementsGrouped: (function() {
      var formElementType, formElementTypeName, formElementsByGroup, formGroup, formGroupName, formGroups, _j, _k, _len2, _len3, _ref5, _ref6, _ref7, _ref8;
      formElementsByGroup = {};
      _ref5 = this.get('allFormElementTypes');
      for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
        formElementTypeName = _ref5[_j];
        formElementType = TYPO3.FormBuilder.Model.FormElementTypes.get(formElementTypeName);
        if (((_ref6 = formElementType.formBuilder) != null ? _ref6.group : void 0) == null) {
          continue;
        }
        if (!formElementsByGroup[formElementType.formBuilder.group]) {
          formElementsByGroup[formElementType.formBuilder.group] = [];
        }
        formElementType.set('key', formElementTypeName);
        formElementsByGroup[formElementType.formBuilder.group].push(formElementType);
      }
      formGroups = [];
      _ref7 = TYPO3.FormBuilder.Model.FormElementGroups.get('allGroupNames');
      for (_k = 0, _len3 = _ref7.length; _k < _len3; _k++) {
        formGroupName = _ref7[_k];
        formGroup = TYPO3.FormBuilder.Model.FormElementGroups.get(formGroupName);
        formGroup.set('key', formGroupName);
        if ((_ref8 = formElementsByGroup[formGroupName]) != null) {
          _ref8.sort(function(a, b) {
            return a.formBuilder.sorting - b.formBuilder.sorting;
          });
        }
        formGroup.set('elements', formElementsByGroup[formGroupName]);
        formGroups.push(formGroup);
      }
      formGroups.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return formGroups;
    }).property('allFormElementTypes').cacheable()
  });

  TYPO3.FormBuilder.View.AvailableFormElementsElement = Ember.View.extend({
    currentlySelectedElementBinding: 'TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable',
    content: null,
    formElementTypeBinding: 'content',
    didInsertElement: function() {
      this.$().html(this.getPath('formElementType.formBuilder.label'));
      this.$().attr('title', this.getPath('formElementType.key'));
      return this.$().addClass(this.getPath('formElementType.__cssClassNames'));
    },
    classNameBindings: ['enabled:formbuilder-enabled'],
    enabled: (function() {
      var currentlySelectedRenderable;
      if (this.getPath('formElementType.formBuilder._isTopLevel')) return true;
      currentlySelectedRenderable = this.get('currentlySelectedElement');
      if (!currentlySelectedRenderable) return false;
      if (currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isTopLevel') && !currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')) {
        return false;
      }
      return true;
    }).property('formElementType', 'currentlySelectedElement').cacheable(),
    getNextFreeIdentifier: function() {
      var i, isIdentifierUsed, prefix, type;
      type = this.getPath('formElementType.key');
      prefix = type.split(':')[1];
      prefix = prefix.toLowerCase();
      isIdentifierUsed = function(identifier) {
        var checkIdentifier, identifierFound;
        identifierFound = false;
        checkIdentifier = function(renderable) {
          var childRenderable, _j, _len2, _ref5, _results;
          if (renderable.get('identifier') === identifier) identifierFound = true;
          if (!identifierFound) {
            _ref5 = renderable.get('renderables');
            _results = [];
            for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
              childRenderable = _ref5[_j];
              _results.push(checkIdentifier(childRenderable));
            }
            return _results;
          }
        };
        checkIdentifier(TYPO3.FormBuilder.Model.Form.get('formDefinition'));
        return identifierFound;
      };
      i = 1;
      while (isIdentifierUsed(prefix + i)) {
        i++;
      }
      return prefix + i;
    },
    click: function() {
      var currentlySelectedRenderable, defaultValues, identifier, indexInParent, newRenderable, parentRenderablesArray, referenceRenderable;
      currentlySelectedRenderable = this.get('currentlySelectedElement');
      if (!currentlySelectedRenderable) return;
      if (!this.get('enabled')) return;
      defaultValues = this.getPath('formElementType.formBuilder.predefinedDefaults') || {};
      identifier = this.getNextFreeIdentifier();
      newRenderable = TYPO3.FormBuilder.Model.Renderable.create($.extend({
        type: this.getPath('formElementType.key'),
        identifier: identifier,
        label: identifier
      }, defaultValues));
      if (!this.getPath('formElementType.formBuilder._isTopLevel') && currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')) {
        currentlySelectedRenderable.get('renderables').pushObject(newRenderable);
      } else {
        referenceRenderable = currentlySelectedRenderable;
        if (referenceRenderable === TYPO3.FormBuilder.Model.Form.get('formDefinition')) {
          referenceRenderable = referenceRenderable.getPath('renderables.0');
        } else if (this.getPath('formElementType.formBuilder._isTopLevel') && !currentlySelectedRenderable.getPath('typeDefinition.formBuilder._isTopLevel')) {
          referenceRenderable = referenceRenderable.findEnclosingPage();
        }
        parentRenderablesArray = referenceRenderable.getPath('parentRenderable.renderables');
        indexInParent = parentRenderablesArray.indexOf(referenceRenderable);
        parentRenderablesArray.replace(indexInParent + 1, 0, [newRenderable]);
      }
      return this.set('currentlySelectedElement', newRenderable);
    }
  });

  TYPO3.FormBuilder.View.AvailableFormElementsCollection = Ember.CollectionView.extend({
    itemViewClass: TYPO3.FormBuilder.View.AvailableFormElementsElement
  });

  TYPO3.FormBuilder.View.FormTree = Ember.View.extend({
    formDefinitionBinding: 'TYPO3.FormBuilder.Model.Form.formDefinition',
    templateName: 'FormTree',
    _tree: null,
    didInsertElement: function() {
      this._tree = this.$().find('.tree');
      this._tree.dynatree({
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
            targetNodeIsCompositeRenderable = targetNode.data.formRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable');
            if (sourceNode.getLevel() === 1) {
              if (targetNode.getLevel() === 1) {
                return ['before', 'after'];
              } else {
                return false;
              }
            } else {
              if (targetNode.getLevel() === 1) {
                if (targetNode.data.formRenderable.getPath('typeDefinition.formBuilder._isCompositeRenderable')) {
                  return ['over'];
                } else {
                  return false;
                }
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
              targetRenderable.get('renderables').pushObject(sourceRenderable);
            } else {
              indexOfTargetRenderable = targetRenderable.getPath('parentRenderable.renderables').indexOf(targetRenderable);
              if (hitMode === 'before') {
                targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable, sourceRenderable);
              } else {
                targetRenderable.getPath('parentRenderable.renderables').insertAt(indexOfTargetRenderable + 1, sourceRenderable);
              }
            }
            TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', null);
            return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', sourceRenderable);
          }
        }
      });
      this.updateTreeStateFromModel(this._tree.dynatree('getRoot'), this.getPath('formDefinition.renderables'));
      return this.initializeContextMenu();
    },
    initializeContextMenu: function() {
      return $.contextMenu({
        selector: '#leftSidebar .tree a.dynatree-title',
        appendTo: '#leftSidebar',
        items: {
          'delete': {
            name: 'Delete',
            callback: function() {
              var dynaTreeNode, renderableToRemove;
              dynaTreeNode = $(this).closest('li')[0].dtnode;
              if (!dynaTreeNode) return;
              renderableToRemove = dynaTreeNode.data.formRenderable;
              if (!renderableToRemove) return;
              return $('<div>Remove Element?</div>').dialog({
                modal: true,
                resizable: false,
                buttons: {
                  'Delete': function() {
                    renderableToRemove.getPath('parentRenderable.renderables').removeObject(renderableToRemove);
                    return $(this).dialog('close');
                  },
                  'Cancel': function() {
                    return $(this).dialog('close');
                  }
                }
              });
            }
          }
        }
      });
    },
    updateTree: (function() {
      var activeNodePath, expandedNodePath, expandedNodePaths, _base, _j, _len2, _ref5, _ref6, _ref7, _ref8;
      if (!((_ref5 = this._tree) != null ? _ref5.dynatree('getTree').visit : void 0)) {
        return;
      }
      expandedNodePaths = [];
      this._tree.dynatree('getTree').visit(function(node) {
        if (node.isExpanded()) return expandedNodePaths.push(node.data.key);
      });
      activeNodePath = (_ref6 = this._tree.dynatree('getActiveNode')) != null ? _ref6.data.key : void 0;
      if (typeof (_base = this._tree.dynatree('getRoot')).removeChildren === "function") {
        _base.removeChildren();
      }
      this.updateTreeStateFromModel(this._tree.dynatree('getRoot'), this.getPath('formDefinition.renderables'), expandedNodePaths.length === 0);
      for (_j = 0, _len2 = expandedNodePaths.length; _j < _len2; _j++) {
        expandedNodePath = expandedNodePaths[_j];
        if ((_ref7 = this._tree.dynatree('getTree').getNodeByKey(expandedNodePath)) != null) {
          _ref7.expand(true);
        }
      }
      return (_ref8 = this._tree.dynatree('getTree').getNodeByKey(activeNodePath)) != null ? _ref8.activate(true) : void 0;
    }).observes('formDefinition.__nestedPropertyChange'),
    updateTreeStateFromModel: function(dynaTreeParentNode, currentListOfSubRenderables, expandFirstNode) {
      var i, newNode, nodeOptions, subRenderable, _len2, _results;
      if (expandFirstNode == null) expandFirstNode = false;
      if (!currentListOfSubRenderables) return;
      _results = [];
      for (i = 0, _len2 = currentListOfSubRenderables.length; i < _len2; i++) {
        subRenderable = currentListOfSubRenderables[i];
        nodeOptions = {
          key: subRenderable.get('_path'),
          title: "" + (subRenderable.label ? subRenderable.label : subRenderable.identifier) + " (" + (subRenderable.getPath('typeDefinition.formBuilder.label')) + ")",
          formRenderable: subRenderable,
          addClass: subRenderable.getPath('typeDefinition.__cssClassNames')
        };
        if (expandFirstNode && i === 0) nodeOptions.expand = true;
        newNode = dynaTreeParentNode.addChild(nodeOptions);
        _results.push(this.updateTreeStateFromModel(newNode, subRenderable.getPath('renderables')));
      }
      return _results;
    },
    updateCurrentlySelectedNode: (function() {
      var activeNodePath, _base, _ref5;
      activeNodePath = TYPO3.FormBuilder.Model.Form.getPath('currentlySelectedRenderable._path');
      return typeof (_base = this._tree.dynatree('getTree')).getNodeByKey === "function" ? (_ref5 = _base.getNodeByKey(activeNodePath)) != null ? _ref5.activate(true) : void 0 : void 0;
    }).observes('TYPO3.FormBuilder.Model.Form.currentlySelectedRenderable'),
    showFormOptions: function() {
      return TYPO3.FormBuilder.Model.Form.set('currentlySelectedRenderable', TYPO3.FormBuilder.Model.Form.get('formDefinition'));
    }
  });

  TYPO3.FormBuilder.View.FormElementInspector = Ember.ContainerView.extend({
    formElement: null,
    orderedFormFieldEditors: (function() {
      var formFieldEditors, k, orderedFormFieldEditors, v;
      formFieldEditors = $.extend({}, this.getPath('formElement.typeDefinition.formBuilder.editors'));
      orderedFormFieldEditors = [];
      for (k in formFieldEditors) {
        v = formFieldEditors[k];
        if (!v) continue;
        v['key'] = k;
        orderedFormFieldEditors.push(v);
      }
      orderedFormFieldEditors.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return orderedFormFieldEditors;
    }).property('formElement.typeDefinition').cacheable(),
    onFormElementChange: (function() {
      var formFieldEditor, subView, subViewClass, subViewOptions, _j, _len2, _ref5, _results;
      this.removeAllChildren();
      if (!this.formElement) return;
      _ref5 = this.get('orderedFormFieldEditors');
      _results = [];
      for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
        formFieldEditor = _ref5[_j];
        subViewClass = Ember.getPath(formFieldEditor.viewName);
        if (!subViewClass) {
          throw "Editor class '" + formFieldEditor.viewName + "' not found";
        }
        subViewOptions = $.extend({}, formFieldEditor, {
          formElement: this.formElement
        });
        subView = subViewClass.create(subViewOptions);
        _results.push(this.get('childViews').pushObject(subView));
      }
      return _results;
    }).observes('formElement')
  });

  TYPO3.FormBuilder.View.Editor = {};

  TYPO3.FormBuilder.View.Editor.AbstractEditor = Ember.View.extend({
    classNames: ['form-editor'],
    formElement: null
  });

  TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({
    propertyPath: null,
    defaultValue: '',
    valueChanged: function() {
      var _base;
      return typeof (_base = this.get('formElement')).somePropertyChanged === "function" ? _base.somePropertyChanged(this.formElement, this.get('propertyPath')) : void 0;
    },
    value: (function(k, v) {
      var value;
      if (v !== void 0) {
        this.formElement.setPath(this.get('propertyPath'), v);
        return v;
      } else {
        value = this.formElement.getPath(this.get('propertyPath'));
        if (value === void 0) {
          this.formElement.setPathRecursively(this.get('propertyPath'), this.get('defaultValue'));
          value = this.formElement.getPath(this.get('propertyPath'));
        }
        return value;
      }
    }).property('propertyPath', 'formElement').cacheable()
  });

  TYPO3.FormBuilder.View.Editor.TextOutput = TYPO3.FormBuilder.View.Editor.AbstractEditor.extend({});

  TYPO3.FormBuilder.View.Editor.IdentifierEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    templateName: 'IdentifierEditor',
    propertyPath: 'identifier',
    editMode: false,
    click: function() {
      return this.set('editMode', true);
    }
  });

  TYPO3.FormBuilder.View.Editor.IdentifierEditor.TextField = Ember.TextField.extend({
    insertNewline: function() {
      return this.setPath('parentView.editMode', false);
    },
    cancel: function() {
      return this.setPath('parentView.editMode', false);
    },
    focusOut: function() {
      return this.setPath('parentView.editMode', false);
    },
    didInsertElement: function() {
      return this.$().select();
    }
  });

  TYPO3.FormBuilder.View.Editor.TextEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    label: null,
    onValueChange: (function() {
      return this.valueChanged();
    }).observes('value'),
    templateName: 'TextEditor'
  });

  TYPO3.FormBuilder.View.Editor.PropertyGrid = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    columns: null,
    isSortable: false,
    enableAddRow: false,
    enableContextMenu: false,
    shouldShowPreselectedValueColumn: false,
    templateName: 'PropertyGridEditor',
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    options: (function() {
      return {
        enableColumnReorder: false,
        autoHeight: true,
        editable: true,
        enableAddRow: this.get('enableAddRow'),
        enableCellNavigation: true,
        asyncEditorLoading: false,
        forceFitColumns: true
      };
    }).property('enableAddRow').cacheable(),
    columnDefinition: (function() {
      var column, columns, _j, _len2, _ref5;
      columns = [];
      if (this.get('isSortable')) {
        columns.push({
          id: "#",
          name: "",
          width: 40,
          behavior: "selectAndMove",
          selectable: false,
          resizable: false,
          cssClass: "cell-reorder dnd",
          focusable: false
        });
      }
      _ref5 = this.get('columns');
      for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
        column = _ref5[_j];
        column = $.extend({}, column);
        column.id = column.field;
        column.editor = Ember.getPath(column.editor);
        columns.push(column);
      }
      if (this.get('shouldShowPreselectedValueColumn')) {
        columns.push({
          id: '__preselectedValues',
          field: '__isPreselected',
          name: 'Selected',
          selectable: false,
          resizable: false,
          formatter: YesNoCellFormatter,
          editor: YesNoCheckboxCellEditor
        });
      }
      return columns;
    }).property('columns', 'isSortable').cacheable(),
    tableRowModel: null,
    buildTableRowModel: (function() {
      var defaultValue, isPreselected, originalRow, tableRowModel, v, _j, _k, _len2, _len3, _ref5, _results;
      if (!this.get('tableRowModel')) this.set('tableRowModel', []);
      tableRowModel = this.get('tableRowModel');
      if (tableRowModel.get('length') > 0) {
        tableRowModel.removeAt(0, tableRowModel.get('length'));
      }
      if (this.get('shouldShowPreselectedValueColumn') === 'multiple') {
        defaultValue = this.getPath('formElement.defaultValue') || [];
      } else if (this.get('shouldShowPreselectedValueColumn') === 'single' && this.getPath('formElement.defaultValue')) {
        defaultValue = [this.getPath('formElement.defaultValue')];
      } else {
        defaultValue = [];
      }
      _ref5 = this.get('value');
      _results = [];
      for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
        originalRow = _ref5[_j];
        isPreselected = false;
        for (_k = 0, _len3 = defaultValue.length; _k < _len3; _k++) {
          v = defaultValue[_k];
          if (v === originalRow._key) isPreselected = true;
        }
        _results.push(tableRowModel.push($.extend({
          __isPreselected: isPreselected
        }, originalRow)));
      }
      return _results;
    }),
    valueChanged: function() {
      var defaultValue, i, oldDefaultValue, rows, tableRowModelRow, tmp, v, _j, _len2, _len3, _ref5;
      rows = [];
      defaultValue = [];
      _ref5 = this.get('tableRowModel');
      for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
        tableRowModelRow = _ref5[_j];
        if (tableRowModelRow.__isPreselected) {
          defaultValue.push(tableRowModelRow._key);
        }
        tmp = $.extend({}, tableRowModelRow);
        delete tmp.__isPreselected;
        rows.push(tmp);
      }
      if (this.get('shouldShowPreselectedValueColumn') === 'multiple') {
        this.setPath('formElement.defaultValue', defaultValue);
        this.set('value', rows);
      } else if (this.get('shouldShowPreselectedValueColumn') === 'single') {
        this.set('value', rows);
        if (defaultValue.length === 0) {
          this.setPath('formElement.defaultValue', null);
        } else {
          oldDefaultValue = this.getPath('formElement.defaultValue');
          for (i = 0, _len3 = defaultValue.length; i < _len3; i++) {
            v = defaultValue[i];
            if (v !== oldDefaultValue) this.setPath('formElement.defaultValue', v);
          }
        }
        this.buildTableRowModel();
        this.grid.invalidateAllRows();
        this.grid.render();
      } else {
        this.set('value', rows);
      }
      return this._super();
    },
    grid: null,
    init: function() {
      this.classNames.push('PropertyGrid');
      return this._super();
    },
    didInsertElement: function() {
      var moveRowsPlugin,
        _this = this;
      this.buildTableRowModel();
      this.grid = new Slick.Grid(this.$().find('.grid'), this.get('tableRowModel'), this.get('columnDefinition'), this.get('options'));
      this.$().find('.slick-viewport').css('overflow-x', 'hidden');
      this.$().find('.slick-viewport').css('overflow-y', 'hidden');
      this.grid.setSelectionModel(new Slick.RowSelectionModel());
      this.grid.onDragInit.subscribe(function() {
        return _this.grid.getEditorLock().commitCurrentEdit();
      });
      this.grid.onCellChange.subscribe(function(e, args) {
        _this.get('tableRowModel').replace(args.row, 1, args.item);
        return _this.valueChanged();
      });
      this.grid.onAddNewRow.subscribe(function(e, args) {
        var columnDefinition, newItem, _j, _len2, _ref5;
        _this.grid.invalidateRow(_this.get('tableRowModel').length);
        newItem = {};
        _ref5 = _this.columns;
        for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
          columnDefinition = _ref5[_j];
          newItem[columnDefinition.field] = '';
        }
        $.extend(newItem, args.item);
        _this.get('tableRowModel').pushObject(newItem);
        _this.grid.updateRowCount();
        _this.grid.render();
        return _this.valueChanged();
      });
      moveRowsPlugin = new Slick.RowMoveManager();
      this.grid.registerPlugin(moveRowsPlugin);
      moveRowsPlugin.onBeforeMoveRows.subscribe(function(e, data) {
        var i, _ref5;
        for (i = 0, _ref5 = data.rows.length; 0 <= _ref5 ? i < _ref5 : i > _ref5; 0 <= _ref5 ? i++ : i--) {
          if (data.rows[i] === data.insertBefore || data.rows[i] === data.insertBefore - 1) {
            e.stopPropagation();
            return false;
          }
        }
        return true;
      });
      moveRowsPlugin.onMoveRows.subscribe(function(e, args) {
        var arrayRowToBeMoved, movedRowIndex;
        movedRowIndex = args.rows[0];
        arrayRowToBeMoved = _this.get('tableRowModel').objectAt(movedRowIndex);
        _this.get('tableRowModel').removeAt(movedRowIndex, 1);
        if (movedRowIndex < args.insertBefore) args.insertBefore--;
        _this.get('tableRowModel').insertAt(args.insertBefore, arrayRowToBeMoved);
        _this.valueChanged();
        _this.grid.invalidateAllRows();
        return _this.grid.render();
      });
      if (this.get('enableContextMenu')) return this.initializeContextMenu();
    },
    initializeContextMenu: function() {
      var that;
      that = this;
      return $.contextMenu({
        selector: '#rightSidebar .slick-row',
        appendTo: '#rightSidebarInner',
        items: {
          'delete': {
            name: 'Delete',
            callback: function() {
              var rowToBeDeletedIndex;
              rowToBeDeletedIndex = $(this).attr('row');
              if (rowToBeDeletedIndex >= that.getPath('tableRowModel.length')) {
                return;
              }
              that.get('tableRowModel').removeAt(parseInt(rowToBeDeletedIndex), 1);
              that.grid.invalidateAllRows();
              that.grid.render();
              return that.valueChanged();
            }
          }
        },
        position: function(opt) {
          return opt.$menu.css('display', 'block').position({
            my: "center top",
            at: "center bottom",
            of: this,
            offset: "0 5",
            collision: "fit"
          }).css('display', 'none');
        }
      });
    }
  });

  TYPO3.FormBuilder.View.Editor.PropertyGrid.TextCellEditor = function(args) {
    var retVal;
    retVal = window.TextCellEditor.apply(this, arguments);
    $(args.container).children('.editor-text').focusout(function() {
      return Slick.GlobalEditorLock.commitCurrentEdit();
    });
    return retVal;
  };

  TYPO3.FormBuilder.View.Editor.RequiredValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    templateName: 'RequiredValidatorEditor',
    propertyPath: 'validators',
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    isRequiredValidatorConfigured: (function(k, v) {
      var a, notEmptyValidatorClassName, val;
      notEmptyValidatorClassName = 'TYPO3\\FLOW3\\Validation\\Validator\\NotEmptyValidator';
      if (v !== void 0) {
        a = this.get('value').filter(function(validatorConfiguration) {
          return validatorConfiguration.name !== notEmptyValidatorClassName;
        });
        this.set('value', a);
        if (v === true) {
          this.get('value').push({
            name: notEmptyValidatorClassName
          });
        }
        this.valueChanged();
        return v;
      } else {
        val = !!this.get('value').some(function(validatorConfiguration) {
          return validatorConfiguration.name === notEmptyValidatorClassName;
        });
        return val;
      }
    }).property('value').cacheable()
  });

  TYPO3.FormBuilder.View.Editor.ValidatorEditor = TYPO3.FormBuilder.View.Editor.AbstractPropertyEditor.extend({
    availableValidators: null,
    templateName: 'ValidatorEditor',
    propertyPath: 'validators',
    defaultValue: (function() {
      return [];
    }).property().cacheable(),
    isVisible: (function() {
      var validatorEditorViewsFound, validatorsAvailable;
      validatorsAvailable = !this.get('noValidatorsAvailable');
      validatorEditorViewsFound = this.get('validatorEditorViews').length > 0;
      return validatorsAvailable || validatorEditorViewsFound;
    }).property('validatorEditorViews', 'noValidatorsAvailable').cacheable(),
    validatorEditorViews: null,
    init: function() {
      this._super();
      this.set('validatorEditorViews', []);
      return this.updateValidatorEditorViews();
    },
    sortedAvailableValidators: (function() {
      var key, validatorTemplate, validatorsArray, _ref5;
      validatorsArray = [];
      _ref5 = this.get('availableValidators');
      for (key in _ref5) {
        validatorTemplate = _ref5[key];
        if (this.isValidatorTemplateFoundInValidatorList(validatorTemplate)) {
          continue;
        }
        validatorsArray.push($.extend({
          key: key
        }, validatorTemplate));
      }
      validatorsArray.sort(function(a, b) {
        return a.sorting - b.sorting;
      });
      return validatorsArray;
    }).property('availableValidators', 'formElement.__nestedPropertyChange').cacheable(),
    noValidatorsAvailable: (function() {
      return this.get('sortedAvailableValidators').length === 0;
    }).property('sortedAvailableValidators').cacheable(),
    addValidatorSelection: null,
    addValidator: (function() {
      var validatorToBeAdded;
      validatorToBeAdded = this.get('addValidatorSelection');
      if (!validatorToBeAdded) return;
      this.get('value').push({
        name: validatorToBeAdded.name,
        options: validatorToBeAdded.options || {}
      });
      this.valueChanged();
      this.updateValidatorEditorViews();
      return this.set('addValidatorSelection', null);
    }).observes('addValidatorSelection'),
    updateValidatorEditorViews: (function() {
      var availableValidators, i, key, validator, validatorEditor, validatorEditorOptions, validatorTemplate, validatorViews, validators, _len2,
        _this = this;
      this.addRequiredValidatorsIfNeededToValidatorList();
      validators = this.get('value');
      availableValidators = this.get('availableValidators');
      validatorViews = [];
      for (i = 0, _len2 = validators.length; i < _len2; i++) {
        validator = validators[i];
        for (key in availableValidators) {
          validatorTemplate = availableValidators[key];
          if (validatorTemplate.name === validator.name) {
            validatorEditor = Ember.getPath(validatorTemplate.viewName || 'TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor');
            if (!validatorEditor) {
              throw "Validator Editor class '" + validatorTemplate.viewName + "' not found";
            }
            validatorEditorOptions = $.extend({
              validatorIndex: i,
              valueChanged: function() {
                return _this.valueChanged();
              },
              updateValidatorEditorViews: function() {
                return _this.updateValidatorEditorViews();
              },
              validators: this.get('value')
            }, validatorTemplate);
            validatorViews.push(validatorEditor.create(validatorEditorOptions));
            break;
          }
        }
      }
      return this.set('validatorEditorViews', validatorViews);
    }).observes('value'),
    addRequiredValidatorsIfNeededToValidatorList: function() {
      var availableValidators, key, requiredAndMissingValidators, validatorTemplate, validatorTemplateName, validators, _j, _len2, _results;
      validators = this.get('value');
      availableValidators = this.get('availableValidators');
      requiredAndMissingValidators = [];
      for (key in availableValidators) {
        validatorTemplate = availableValidators[key];
        if (!validatorTemplate.required) continue;
        if (!this.isValidatorTemplateFoundInValidatorList(validatorTemplate)) {
          requiredAndMissingValidators.push(key);
        }
      }
      _results = [];
      for (_j = 0, _len2 = requiredAndMissingValidators.length; _j < _len2; _j++) {
        validatorTemplateName = requiredAndMissingValidators[_j];
        _results.push(validators.push({
          name: availableValidators[validatorTemplateName].name,
          options: $.extend({}, availableValidators[validatorTemplateName].options)
        }));
      }
      return _results;
    },
    isValidatorTemplateFoundInValidatorList: function(validatorTemplate) {
      var validator, validators, _j, _len2;
      validators = this.get('value');
      for (_j = 0, _len2 = validators.length; _j < _len2; _j++) {
        validator = validators[_j];
        if (validatorTemplate.name === validator.name) return true;
      }
      return false;
    }
  });

  TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor = Ember.View.extend({
    classNames: ['formbuilder-validator-editor'],
    templateName: 'ValidatorEditor-Default',
    required: false,
    validators: null,
    validatorIndex: null,
    validator: (function() {
      return this.get('validators').get(this.get('validatorIndex'));
    }).property('validators', 'validatorIndex'),
    valueChanged: Ember.K,
    notRequired: (function() {
      return !this.get('required');
    }).property('required').cacheable(),
    remove: function() {
      this.get('validators').removeAt(this.get('validatorIndex'));
      this.valueChanged();
      return this.updateValidatorEditorViews();
    }
  });

  TYPO3.FormBuilder.View.Editor.ValidatorEditor.MinimumMaximumValidatorEditor = TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor.extend({
    templateName: 'ValidatorEditor-MinimumMaximum',
    pathToMinimumOption: 'validator.options.minimum',
    pathToMaximumOption: 'validator.options.maximum',
    minimum: (function(k, v) {
      if (v !== void 0) {
        this.setPath(this.get('pathToMinimumOption'), v);
        this.valueChanged();
        return v;
      } else {
        return this.getPath(this.get('pathToMinimumOption'));
      }
    }).property('pathToMinimumOption').cacheable(),
    maximum: (function(k, v) {
      if (v !== void 0) {
        this.setPath(this.get('pathToMaximumOption'), v);
        this.valueChanged();
        return v;
      } else {
        return this.getPath(this.get('pathToMaximumOption'));
      }
    }).property('pathToMaximumOption').cacheable()
  });

  TYPO3.FormBuilder.View.Editor.ValidatorEditor.SimpleValueValidatorEditor = TYPO3.FormBuilder.View.Editor.ValidatorEditor.DefaultValidatorEditor.extend({
    templateName: 'ValidatorEditor-SimpleValue',
    pathToEditedValue: 'validator.options.TODO',
    label: 'Label',
    value: (function(k, v) {
      if (v !== void 0) {
        this.setPath(this.get('pathToEditedValue'), v);
        this.valueChanged();
        return v;
      } else {
        return this.getPath(this.get('pathToEditedValue'));
      }
    }).property('pathToEditedValue').cacheable()
  });

}).call(this);
