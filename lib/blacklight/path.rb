module Blacklight
  # This class encapsulates the search state as represented by the query
  # parameters namely: :f, :q, :page, :per_page and, :sort
  class Path
    include Blacklight::Facet
    attr_reader :blacklight_config # Must be called blacklight_config, because Blacklight::Facet calls blacklight_config.
    attr_reader :params

    def initialize(params, blacklight_config)
      @params = params
      @blacklight_config = blacklight_config
    end

    def url_for_document(doc, options = {})
      if respond_to?(:blacklight_config) and
          blacklight_config.show.route and
          (!doc.respond_to?(:to_model) or doc.to_model.is_a? SolrDocument)
        route = blacklight_config.show.route.merge(action: :show, id: doc).merge(options)
        route[:controller] = params[:controller] if route[:controller] == :current
        route
      else
        doc
      end
    end

    # adds the value and/or field to params[:f]
    # Does NOT remove request keys and otherwise ensure that the hash
    # is suitable for a redirect. See
    # add_facet_params_and_redirect
    def add_facet_params(field, item, source_params=params)

      if item.respond_to? :field
        field = item.field
      end

      facet_config = facet_configuration_for_field(field)

      url_field = facet_config.key

      value = facet_value_for_facet_item(item)

      p = reset_search_params(source_params)
      p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$
      p[:f][url_field] = (p[:f][url_field] || []).dup

      if facet_config.single and not p[:f][url_field].empty?
        p[:f][url_field] = []
      end

      p[:f][url_field].push(value)

      if item and item.respond_to?(:fq) and item.fq
        Array(item.fq).each do |f,v|
          p = add_facet_params(f, v, p)
        end
      end

      p
    end

    # Used in catalog/facet action, facets.rb view, for a click
    # on a facet value. Add on the facet params to existing
    # search constraints. Remove any paginator-specific request
    # params, or other request params that should be removed
    # for a 'fresh' display.
    # Change the action to 'index' to send them back to
    # catalog/index with their new facet choice.
    def add_facet_params_and_redirect(field, item)
      new_params = add_facet_params(field, item)

      # Delete any request params from facet-specific action, needed
      # to redir to index action properly.
      request_keys = blacklight_config.facet_paginator_class.request_keys
      new_params.except! *request_keys.values

      new_params
    end

    # copies the current params (or whatever is passed in as the 3rd arg)
    # removes the field value from params[:f]
    # removes the field if there are no more values in params[:f][field]
    # removes additional params (page, id, etc..)
    def remove_facet_params(field, item)
      if item.respond_to? :field
        field = item.field
      end

      facet_config = facet_configuration_for_field(field)

      url_field = facet_config.key

      value = facet_value_for_facet_item(item)

      p = reset_search_params(params)
      # need to dup the facet values too,
      # if the values aren't dup'd, then the values
      # from the session will get remove in the show view...
      p[:f] = (p[:f] || {}).dup
      p[:f][url_field] = (p[:f][url_field] || []).dup
      p[:f][url_field] = p[:f][url_field] - [value]
      p[:f].delete(url_field) if p[:f][url_field].size == 0
      p.delete(:f) if p[:f].empty?
      p
    end

    # Merge the source params with the params_to_merge hash
    # @param [Hash] params_to_merge to merge into above
    # @return the current search parameters after being sanitized by Blacklight::Parameters.sanitize
    # @yield [params] The merged parameters hash before being sanitized
    def params_for_search(params_to_merge={}, &block)
      # params hash we'll return
      my_params = params.dup.merge(params_to_merge.dup)

      if block_given?
        yield my_params
      end

      if my_params[:page] and (my_params[:per_page] != params[:per_page] or my_params[:sort] != params[:sort] )
        my_params[:page] = 1
      end

      Parameters.sanitize(my_params)
    end

    private

      ##
      # Reset any search parameters that store search context
      # and need to be reset when e.g. constraints change
      def reset_search_params source_params
        Parameters.sanitize(source_params).except(:page, :counter).with_indifferent_access
      end

      # TODO: this code is duplicated in Blacklight::FacetsHelperBehavior
      def facet_value_for_facet_item item
        if item.respond_to? :value
          item.value
        else
          item
        end
      end
  end
end
