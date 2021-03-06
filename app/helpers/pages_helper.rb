# frozen_string_literal: true

module PagesHelper
  include ConfigHelper

  def page_nav_item(text, path, strict = true)
    selected = current_page?(path) || (!strict && request.path.include?(path))
    klass = selected ? 'active' : nil

    content_tag :li, class: klass do
      link_to text, path
    end
  end

  def ak_report_url(resource_uri)
    resource_id = ak_resource_id(resource_uri)
    report_url = URI(Settings.ak_report_url)
    report_url.query = "page_id=#{resource_id}"
    report_url.to_s
  end

  def ak_resource_id(ak_resource_url)
    # e.g. matches '12345' from 'https://act.example.org/rest/v1/donationpage/12345/'
    match = %r{\/(\d+)\/?$}.match(ak_resource_url)
    return if match.blank?

    match[1]
  end

  def ak_page_type(ak_resource_url)
    # e.g. matches 'donationpage' from 'https://act.example.org/rest/v1/donationpage/12345/'
    match = %r{\/(\w+)\/(\d+)\/?$}.match(ak_resource_url)
    return if match.blank?

    match[1]
  end

  def ak_page_url(resource_uri)
    resource_id = ak_resource_id(resource_uri)
    page_type = ak_page_type(resource_uri)
    "#{Settings.ak_root_url}admin/core/#{page_type}/#{resource_id}/"
  end

  def page_canonical_url(page)
    return page.canonical_url if page.canonical_url.present?

    member_facing_page_url(page)
  end

  def page_description(page)
    return page.meta_description if page.meta_description.present?

    t('branding.description')
  end

  def serialize(data, field)
    hash = HashWithIndifferentAccess.new(data)
    (hash[field].nil? ? {} : hash[field]).to_json.html_safe
  end

  def record_range(page_number, per_page)
    last = page_number * per_page
    first = last - per_page + 1
    "#{first} to #{last}"
  end

  def prefill_link(new_variant)
    new_variant.description = '{LINK}' if new_variant.name == 'twitter'
    new_variant.body = '{LINK}' if new_variant.name == 'email'
    new_variant.text = '{LINK}' if new_variant.name == 'whatsapp'
    new_variant
  end

  def label_with_tooltip(form, field_sym, label_text, tooltip_text)
    tooltip = render partial: 'pages/tooltip', locals: { label_text: label_text, tooltip_text: tooltip_text }
    form.label field_sym do
      "#{label_text} #{tooltip}".html_safe
    end
  end

  def label_tag_with_tooltip(field, label_text, tooltip_text)
    tooltip = render partial: 'pages/tooltip', locals: { label_text: label_text, tooltip_text: tooltip_text }
    label_tag field, "#{label_text} #{tooltip}".html_safe
  end

  def button_group_item(text, path)
    selected = current_page?(path)
    klass = "#{selected ? 'btn-primary' : 'btn-default'} btn".trim
    link_to text, path, class: klass
  end

  def toggle_switch(state, active, label)
    klass = (active == state ? 'btn-primary' : '')
    klass += ' btn toggle-button btn-default'

    content_tag :a, label, class: klass, data: { state: state }
  end

  def plugin_title(plugin)
    detail = plugin.ref.present? ? " - #{plugin.ref}" : ''
    "#{plugin_human_name(plugin)}#{detail}"
  end

  def plugin_human_name(plugin)
    plugin.name.underscore.humanize
  end

  def plugin_section_id(plugin)
    section_id_with_ref = plugin.ref.sub(/[^a-z0-9_]/i) { '_' } if plugin.ref.present?
    detail = plugin.ref.present? ? "_#{section_id_with_ref}" : ''
    "#{plugin.name}#{detail}"
  end

  # given a plugin object, this method returns the name
  # of a font-awesome icon for that plugin, either specific
  # to that plugin or falling back to a generic one.
  def plugin_icon(plugin)
    registered = {
      petition: 'hand-rock-o',
      thermometer: 'neuter',
      survey: 'edit',
      text: 'paragraph',
      fundraiser: 'money',
      email_tool: 'envelope-o',
      email_pension: 'university',
      call_tool: 'phone'
    }
    name = plugin.name.underscore.to_sym
    registered.fetch(name, 'cubes')
  end

  def twitter_meta(page, share_card = {})
    {
      card: 'summary_large_image',
      domain: Settings.home_page_url,
      site: t('share.twitter_handle'),
      creator: t('share.twitter_handle'),
      title: page.title,
      description: truncate(strip_tags(CGI.unescapeHTML(page.content)), length: 140),
      image: page.primary_image.try(:content).try(:url)
    }.merge(share_card) do |_key, v1, v2|
      v2.blank? ? v1 : v2
    end
  end

  def facebook_meta(page, share_card = {})
    share_card.delete_if { |_, v| v.blank? }

    {
      site_name: 'SumOfUs',
      title: page.title,
      description: truncate(strip_tags(CGI.unescapeHTML(page.content)), length: 260),
      url: member_facing_page_url(page),
      type: 'website',
      article: { publisher: Settings.facebook_url },
      image: page.primary_image.try(:content).try(:url)
    }.merge(share_card)
  end

  def share_card(page)
    share = Share::Facebook.where(page_id: page.id).last
    return {} if share.blank?

    {
      title: share.title,
      description: share.description,
      image: share_image_url(share)
    }
  end

  def share_image_url(share)
    Image.find_by(id: share.image_id).try(:content).try(:url)
  end

  def archive_confirm_message(page)
    msg = 'Are you sure you want to archive this page?'
    msg += ' It will also be unpublished making it inaccessible except to logged-in campaigners.' if page.published?
    msg
  end

  def toggle_featured_link(page)
    method = page.featured? ? :delete : :post
    klass = "glyphicon glyphicon-star#{'-empty' unless page.featured?}"

    path = page.featured? ? featured_page_path(page) : featured_pages_path(id: page.id)

    link_to path, method: method, remote: true do
      content_tag :span, '', class: klass
    end
  end

  def share_url(variant)
    if variant.share_progress?
      "http://sumof.us/99/#{variant.button.sp_id}/#{variant.button.share_type}"
    else
      URI.extract(variant.html).first
    end
  end

  def collapse_share_url_form(page)
    page.share_buttons.map(&:url).uniq == [member_facing_page_url(page)]
  end

  def pack_exists?(name, type)
    Webpacker.manifest.lookup("#{name}#{compute_asset_extname(name, type: type)}")
  end

  def page_object(page)
    return {} unless page

    exceptions = %i[content javascript liquid_layout_id compiled_html messages]
    base = page.as_json(except: exceptions)
    base[:language_code] = page.language_code

    layouts_and_plugins = {
      layout: page.liquid_layout.title,
      follow_up_layout: page.follow_up_liquid_layout.try(:title),
      follow_up_url: PageFollower.new_from_page(page).follow_up_path,
      plugins: page.plugins.map { |plugin| plugin.class.name }
    }

    base.merge(layouts_and_plugins)
  end

  def truncate_page_content(content, length = 500)
    Truncato.truncate(content, max_length: length)
  end

  def plugin_supplemental_data(member, url_params)
    # TODO
  end

  def plugins_config(page)
    return {} unless page

    page.plugins.each_with_object({}) do |plugin, hsh|
      return hsh unless plugin.present?

      ref = plugin.ref.present? ? plugin.ref : 'default'
      hsh[plugin.name.underscore.to_sym] = {
        "#{ref}": {
          config: plugin.liquid_data
        }
      }.symbolize_keys
      hsh
    end
  end
end
