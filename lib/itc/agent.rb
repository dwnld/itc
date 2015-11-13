require 'mechanize'
require 'set'
require 'httparty'
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

    def post_image(url, body=nil, headers={})
      tries ||= 3
      full_url = URI.join(IMAGE_BASE_URI, url)
      response = HTTParty.post(full_url, body: body, headers: headers, timeout: 60, ssl_version: :TLSv1)
      if response.success?
        return ImageUploadResponse.new(response.body)
      else
        raise "Got error code #{response.code} for #{full_url} -- #{response.body}"
      end
    rescue Timeout::Error
      tries -= 1
      if tries > 0
        retry
      else
        raise
      end
    end

    def initialize(username, password)
      @username = username
      @password = password
      @http_client = Mechanize.new
      @http_client.idle_timeout = 1 # Prevent connection resets from apple
    end

    def service_key
      return @service_key if @service_key
      # We need a service key from a JS file to properly auth
      js = @http_client.get('https://itunesconnect.apple.com/itc/static-resources/controllers/login_cntrl.js')
      @service_key ||= js.body.match(/itcServiceKey = '(.*)'/)[1]
    end

    def login
      data = {
        accountName: @username,
        password:    @password,
        rememberMe:  true
      }
      response = @http_client.post("https://idmsa.apple.com/appleauth/auth/signin?widgetKey=#{service_key}", data.to_json, {'Content-Type' => 'application/json'})
      if response['Set-Cookie'] =~ /myacinfo=(\w+);/
        @http_client.get('https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/wa/route?noext')
        @http_client.get('https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa')
        @logged_in = true
      else
        raise "Failed to sign into iTunes Connect"
      end
    end

    def search_by_sku(sku)
      apps = all_apps
      apps.find { |app| app.sku == sku }
    end

    def all_apps
      login unless @logged_in
      response = get('/WebObjects/iTunesConnect.woa/ra/apps/manageyourapps/summary/v2')
      response.raise_if_errors
      response.data['summaries'].map{ |s| App.new(s) }
    end

    def search_by_app_id(app_id)
      login unless @logged_in
      response = get("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/details")
      unless response.errors
        response.data
      end
    rescue Mechanize::ResponseCodeError => e
      false
    end

    def app_overview(app_id)
      login unless @logged_in
      overview_response = get("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/overview")
      overview_response.raise_if_errors
      overview_response.data
    end

    def localization
      login unless @logged_in
      l10n_resp = get("/WebObjects/iTunesConnect.woa/ra/l10n")
      l10n_resp.raise_if_errors
      ref_resp = get("/WebObjects/iTunesConnect.woa/ra/ref")
      ref_resp.raise_if_errors
      Localization.new(l10n_resp.data, ref_resp.data)
    end

    def find_app_store_url(app_id)
      login unless @logged_in
      overview_response = get("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/overview")
      overview_response.raise_if_errors
      overview_response.data['appStoreUrl']
    end

    def app_details(app_id)
      login unless @logged_in
      response = get("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/details")
      response.raise_if_errors
      response.data
    end

    def app_version_details(app_id)
      login unless @logged_in
      overview_response = get("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/overview")
      overview_response.raise_if_errors
      # Get the live version
      version_id = overview_response.data['platforms'].first['inFlightVersion']['id']

      raise "Unable to get live version id for app_id #{app_id}" unless version_id

      response = get("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/platforms/ios/versions/#{version_id}")
      response.raise_if_errors
      response.data
    end

    def can_update_version?(app_details)
      return true if app_details['liveVersion']['state'] == 'prepareForUpload'
    end

    def can_add_version?(app_details)
      return app_details['canAddVersion']
    end

    def add_version(app_id, version)
      login unless @logged_in
      data = {
        version: {
          value: version
        }
      }.to_json
      post_response = post("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/platforms/ios/versions/create/", data)
      post_response.raise_if_errors
      post_response
    end

    def create_app(name, version, bundle_id, vendor_id, company_name)
      login unless @logged_in
      data = create_app_data(name, version, bundle_id, vendor_id, company_name).to_json
      response = post("/WebObjects/iTunesConnect.woa/ra/apps/create/v2/", data)
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
      data = update_app_data(config, localization).to_json
      response = post("/WebObjects/iTunesConnect.woa/ra/apps/version/save/#{config.app_id}", data)
      response.raise_if_errors
      puts "Finished updating app"
      response.data
    end

    def submit_for_review(app_id)
      puts "Submitting App #{app_id} for Review"
      login unless @logged_in
      config = AppConfiguration.new
      config.app_id = app_id
      app_data = app_details(app_id)
      data = submit_for_review_data(config, app_data['inFlightVersion'].nil?).to_json
      response = post("/WebObjects/iTunesConnect.woa/ra/apps/#{config.app_id}/version/submit/complete", data)
      response.raise_if_errors("Failed to submit for review app with id: #{app_id}")
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

    def candidate_builds(app_id)
      login unless @logged_in
      app_data = get("/WebObjects/iTunesConnect.woa/ra/apps/version/#{app_id}")
      itunes_app_version = app_data.data.fetch('versionId')
      response = get("/WebObjects/iTunesConnect.woa/ra/apps/#{app_id}/versions/#{itunes_app_version}/candidateBuilds")
      response.raise_if_errors
      response.data['builds'].map{|hash| CandidateBuild.new(hash)}
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

    def generate_daily_iad_csv_report(date, publisher_id, parameters=[], referer=nil, headers={})
      login unless @logged_in
      report_url = 'https://iad.apple.com/itcportal/generatecsv?' \
        "pageName=app_homepage&dashboardType=publisher&publisherId=#{publisher_id}&dateRange=oneDay" \
        "&searchTerms=Search%20Apps&adminFlag=false&fromDate=#{date.strftime('%m/%d/%y')}&toDate=&dataType=byName"
      @http_client.get(report_url, parameters, referer, headers)
    end

    def app_status_counts
      apps = all_apps
      status_counts = {}
      apps.each do |app|
        app.versions.each do |version|
          status_count = status_counts.fetch(version.state, 0)
          status_counts[version.state] = status_count + 1
        end
      end
      status_counts
    end
  end

end
