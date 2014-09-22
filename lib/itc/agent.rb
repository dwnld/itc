require 'mechanize'
require 'set'
require 'itc/post_data'
require 'itc/response'
require 'itc/models'

module Itc
  class Agent
    include Itc::PostData
    BASE_URI = 'https://itunesconnect.apple.com'
    IMAGE_BASE_URI = 'https://du-itc.itunes.apple.com'

    def get(url, parameters=[], referer=nil, headers={})
      Response.new(@http_client.get(URI.join(BASE_URI, url), parameters, referer, headers).body)
    end

    def post(url, parameters=[], headers={})
      headers = {'Content-Type' => 'application/json'}.merge(headers)
      Response.new(@http_client.post(URI.join(BASE_URI, url), parameters, headers).body)
    rescue Mechanize::ResponseCodeError => e
      Response.new(e.page.body)
    end

    def post_image(url, parameters=[], headers={})
      ImageUploadResponse.new(@http_client.post(URI.join(IMAGE_BASE_URI, url), parameters, headers).body)
    rescue Mechanize::ResponseCodeError => e
      raise Mechanize::ResponseCodeError.new(e.page, e.page.body)
    end

    def initialize(username, password)
      @username = username
      @password = password
      @http_client = Mechanize.new
    end

    def login
      # TODO Don't select by name in case apple changes
      login_page = @http_client.get(BASE_URI)
      login_form = login_page.form('appleConnectForm')
      login_form.theAccountName = @username
      login_form.theAccountPW = @password
      response = @http_client.submit(login_form)
      unless response.search('h2:contains("Sign In to iTunes Connect")').empty?
        raise "Failed to sign into iTunes Connect"
      end
      @logged_in = true
    end

    def search_by_sku(sku)
      apps = all_apps
      apps.find { |app| app.sku == sku }
    end

    def all_apps
      login unless @logged_in
      response = get('/WebObjects/iTunesConnect.woa/ra/apps/manageyourapps/summary')
      response.raise_if_errors
      response.data['summaries'].map{ |s| App.new(s) }
    end

    def search_by_app_id(app_id)
      login unless @logged_in
      response = get("/WebObjects/iTunesConnect.woa/ra/apps/detail/#{app_id}")
      unless response.errors
        response.data
      end
    rescue Mechanize::ResponseCodeError => e
      false
    end

    def find_app_store_url(app_id)
      app_info = search_by_app_id(app_id)
      if app_info
        app_info["appPageMoreLinks"].find{ |h| h["text"] == "ITC.apps.versionLinks.AppStore" }["link"]
      end
    end


    def add_version(app_id, version)
      login unless @logged_in
      response = get("/WebObjects/iTunesConnect.woa/ra/apps/detail/#{app_id}")
      if response.data['canAddVersion']
        data = {version: version}.to_json
        post_response = post("/WebObjects/iTunesConnect.woa/ra/apps/version/create/#{app_id}", data)
        response.raise_if_errors
        response
      else
        raise "Cannot add version"
      end
    end

    def create_app(name, version, bundle_id, vendor_id)
      login unless @logged_in
      data = create_app_data(name, version, bundle_id, vendor_id).to_json
      response = post("/WebObjects/iTunesConnect.woa/ra/apps/create/?appType=ios", data)
      response.raise_if_errors
      response.data
    end


    def update_app(app_id)
      login unless @logged_in
      config = AppConfiguration.new
      config.app_id = app_id
      set_current_screenshots(config)
      yield config

      update_screenshots(config)
      data = update_app_data(config).to_json
      response = post("/WebObjects/iTunesConnect.woa/ra/apps/version/save/#{config.app_id}", data)
      response.raise_if_errors
      response.data
    end

    def developer_reject(sku)
      login unless @logged_in
      app_data = search_by_sku(sku)
      raise "App not found: #{sku}" unless app_data
      app_id = app_data['adamId']
      response = post("/WebObjects/iTunesConnect.woa/ra/apps/version/reject/#{app_id}")
      response.raise_if_errors("Failed to reject #{sku}")
      response
    end

    def set_current_screenshots(config)
      app_data = get("/WebObjects/iTunesConnect.woa/ra/apps/version/#{config.app_id}")
      app_data.data['details']['value'].first['screenshots']['value'].each do |itc_name, screenshots|
        next if itc_name == 'desktop'
        device = ScreenshotContainer::ITC_NAME_TO_DEVICE_NAME.fetch(itc_name)
        screenshots = screenshots['value']
        config.version_info.screenshots.send("#{device}=", screenshots.map{|s| Screenshot.from_itc(s['value'])})
      end
      config.version_info.screenshots.should_update = nil
      app_icon_data = app_data.data['largeAppIcon']['value']
      config.store_info.app_icon = Screenshot.from_itc(app_icon_data)
    end

    def fetch_itc_token
      login unless @logged_in
      response = get("/WebObjects/iTunesConnect.woa/ra/apps/version/ref")
      response.raise_if_errors
      @screenshot_token = response.data['ssoTokenForImage']
    end

    def fetch_content_provider_id
      login unless @logged_in
      response = get("/WebObjects/iTunesConnect.woa/ra/user/detail")
      response.raise_if_errors
      @content_provider_id = response.data['contentProviderId']
    end

    def update_screenshots(config)
      screenshot_config = config.version_info.screenshots
      screenshot_config.should_update.each do |device|
        screenshots = config.version_info.screenshots.send(device)
        screenshots.each_with_index do |screenshot, i|
          upload_screenshot(config, "/upload/app-screenshot-image", screenshot, i + 1)
        end
      end

      if config.store_info.app_icon.kind_of?(String)
        # App icon has been updated, upload
        icon = Screenshot.new
        icon.url = config.store_info.app_icon
        upload_screenshot(config, "/upload/app-icon-image", icon, nil)
        config.store_info.app_icon = icon
      end
    end

    def upload_screenshot(config, remote_url, screenshot, sort_order)
      fetch_itc_token unless @screenshot_token
      fetch_content_provider_id unless @content_provider_id
      correlation_key = "iOS App:AdamId=#{config.app_id}:Version=#{config.version_info.version_number}"

      headers = {
        'Content-Type' => 'image/png',
        'X-Apple-Upload-ContentProviderId' => @content_provider_id,
        'X-Apple-Upload-itctoken' => @screenshot_token,
        'X-Apple-Upload-Correlation-Key' => correlation_key,
        'X-Apple-Upload-AppleId' => config.app_id
      }

      filename = File.basename(screenshot.url)
      response = post_image(
        remote_url,
        File.read(screenshot.url),
        headers.merge('X-Original-Filename' => filename)
      )
      screenshot.asset_token = response.data['token']
      screenshot.full_size_url = nil
      screenshot.sort_order = sort_order
      screenshot.url = nil
    end
  end

end
