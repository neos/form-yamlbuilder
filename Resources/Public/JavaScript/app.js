(function() {
  var TYPO3;

  TYPO3 = window.TYPO3 || {};

  window.TYPO3 = TYPO3;

  TYPO3.FormBuilder = Ember.Application.create({
    rootElement: 'body'
  });

  TYPO3.FormBuilder.FormElements = Ember.ArrayController.create();

  TYPO3.FormBuilder.FormElementsView = Ember.CollectionView.extend({
    contentBinding: 'TYPO3.FormBuilder.FormElements.content',
    click: function() {
      return console.log('click');
    },
    itemViewClass: Ember.View.extend({
      templateName: 'item',
      didInsertElement: function() {
        return this.$().draggable({
          connectToSortable: '#main',
          helper: function() {
            return $('<div>' + $(this).html() + '</div>');
          },
          revert: 'invalid'
        });
      }
    })
  });

  $('#main').sortable({
    revert: true
  });

  window.setTimeout((function() {
    return TYPO3.FormBuilder.FormElements.set('content', [
      {
        type: 'TYPO3.Form:Textbox',
        label: 'Text Box'
      }, {
        type: 'TYPO3.Form:Textfield',
        label: 'Text Field'
      }
    ]);
  }), 2000);

}).call(this);
