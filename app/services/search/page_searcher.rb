class Search::PageSearcher

  def initialize(params)
    @queries = params[:search]
    @collection = CampaignPage.all
  end

  def search
    [*@queries].each do |search_type, query|
      case search_type.to_s
        when 'content_search'
          search_by_text(query)
        when 'tags'
          search_by_tags(query)
        when 'language'
          search_by_language(query)
        when 'layout'
          search_by_layout(query)
        when 'campaign'
          search_by_campaign(query)
        when 'plugin_type'
          search_by_plugin_type(query)
      end
    end
    @collection
  end

  private

  def combine_collections(collection1, collection2)
    # get union of unique values in collection1 and collection2
    arr = (collection1 | collection2).uniq
    # map from array back to AR collection
    array_to_relation(CampaignPage, arr)
  end

  def array_to_relation(model, arr)
    model.where(id: arr.map(&:id))
  end

  def search_by_title(query)
    @collection = Search.full_text_search(@collection, 'title', query)
  end

  def search_by_text(query)
    # is 'content' a field in CampaignPages, or is it accessed through @campaign_page.liquid_layout?
    matches_by_content = Search.full_text_search(@collection, 'content', query)
    @collection = combine_collections(search_by_title(query), matches_by_content)
  end

  def search_by_tags(query)
    @collection = @collection.joins(:tags).where(tags: {id: query})
  end

  def search_by_language(query)
    @collection = @collection.where(language_id: query)
  end

  def search_by_campaign(query)
    @collection = @collection.where(campaign_id: query)
  end

  def search_by_layout(query)
    @collection = @collection.where(liquid_layout: query)
  end

  def search_by_plugin_type(plugins)
    matches_by_plugins = []
    plugins.each do |plugin_type|
      plugin_type.constantize.page.each do |plugin|
        # push into the array all records of pages that contain that plugin type
        if plugin.active?
          matches_by_plugins.push(plugin.campaign_page_id)
        end
      end
    end
    # get pages that match ids of pages that contain the plugin type from the collection
    @collection = @collection.where(id: matches_by_plugins)
  end

end
