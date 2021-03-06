// This file handles the behaviour for managing form building.
//
// Dependencies:
//
//   jQuery.ui.sortable: https://jqueryui.com/sortable/
//   - Allows form fields to be dragged and re-oredered
//
//   Twitter's typeahead: http://twitter.github.io/typeahead.js/
//   - Use for autocompleting for setting the field's name value
import $ from 'jquery';
import ee from '../../shared/pub_sub';
import setupOnce from './setup_once';
import ErrorDisplay from '../../shared/show_errors';
import GlobalEvents from '../../shared/global_events';

const CollectionEditor = Backbone.View.extend({
  whitelist: [
    // Permitted fields provided by ActionKit
    'address1',
    'address2',
    'city',
    'country',
    'email',
    'first_name',
    'last_name',
    'middle_name',
    'mobile_phone',
    'name',
    'phone',
    'plus4',
    'postal',
    'prefix',
    'region',
    'state',
    'suffix',
    'zip',

    // Common custom fields used by campaigners
    'customer',
    'employee',
    'shareholder',
    'investor',
  ],

  events: {
    'ajax:success #new_collection_element': 'newElementAdded',
    'ajax:success #change-form-template': 'templateChanged',
    'ajax:error a[data-method=delete]': 'deleteFailed',
    'sortupdate .list-group': 'updateSort',
  },

  globalEvents: {
    'survey:form_added': 'autoComplete',
  },

  initialize: function() {
    this.makeSortable();
    this.autoComplete();
    this.$el.on('ajax:success', 'a[data-method=delete]', function() {
      $(this)
        .parents('.list-group-item')
        .fadeOut();
    });
    GlobalEvents.bindEvents(this);
  },

  deleteFailed: function(e, xhr) {
    const message = this.deleteErrorMessage(xhr);
    alert(message);
  },

  deleteErrorMessage(xhr) {
    const errors = xhr && xhr.responseJSON && xhr.responseJSON.errors;
    if (!errors || Object.keys(errors).length < 1)
      return 'That element could not be deleted';
    const firstKey = Object.keys(errors)[0];
    return `That element ${errors[firstKey]}`;
  },

  substringMatcher: function(strs) {
    return function findMatches(q, cb) {
      const matches = [];
      const substrRegex = new RegExp(q, 'i');

      // Iterate through the pool of strings and for any string that
      // contains the substring `q`, add it to the `matches` array
      $.each(strs, function(i, str) {
        if (substrRegex.test(str)) {
          matches.push(str);
        }
      });
      cb(matches);
    };
  },

  autoComplete: function() {
    const $fields = this.$('.typeahead.typeahead--uninitialized');
    $fields.removeClass('typeahead--uninitialized');
    $fields.typeahead(
      {
        hint: true,
        highlight: true,
        minLength: 1,
      },
      {
        name: 'fields',
        source: this.substringMatcher(this.whitelist),
      }
    );
  },

  makeSortable: function() {
    this.$('.list-group.sortable').sortable();
  },

  updateSort: function(event, ui, a, b) {
    const ids = ui.item
      .parent()
      .children()
      .map(function(i, el) {
        return $(el).data('id');
      })
      .get()
      .join();
    const $form = ui.item
      .parent()
      .parent()
      .find('form#sort-collection-elements');
    $form.find('#form_element_ids').val(ids);
    $form.submit();
  },

  newElementAdded: function(e, resp, c) {
    let $listGroup = this.$(e.target)
      .parents('.form-customization')
      .find('.list-group');
    $listGroup = $listGroup.length ? $listGroup : this.$('.list-group');
    $listGroup.append(resp);
    this.$('#form_element_label, #form_element_name').val('');
    ErrorDisplay.clearErrors(this.$('form#new_collection_element'));
    Backbone.trigger('collection:element_added');
    this.makeSortable();
  },

  templateChanged: function(e, resp) {
    this.$('.forms-edit').html(resp.html);
    this.makeSortable();

    // Updates the inline form's action URL with the new form ID.
    this.$('#sort-collection-elements, #new_collection_element').each(function(
      i,
      el
    ) {
      const action = $(el)
        .attr('action')
        .replace(/\d+/, resp.form_id);
      $(el).attr('action', action);
    });
  },
});

ee.on('collection:edit:loaded', function() {
  setupOnce('.collection-editor', CollectionEditor);
});
