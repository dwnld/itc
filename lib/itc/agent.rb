require 'mechanize'
require 'itc/post_data'
require 'itc/response'

module Itc
  class Agent
    include Itc::PostData
    BASE_URI = 'https://itunesconnect.apple.com'

    def get(url, *args)
      @http_client.get(URI.join(BASE_URI, url), *args)
    end

    def post(url, *args)
      Response.new(@http_client.post(URI.join(BASE_URI, url), *args).body)
    rescue Mechanize::ResponseCodeError => e
      Response.new(e.page.body)
    end

    def initialize(username, password)
      @username = username
      @password = password
      @http_client = Mechanize.new
    end

    def login
      # TODO Don't select by name in case apple changes
      login_page = get('/')
      login_form = login_page.form('appleConnectForm')
      login_form.theAccountName = @username
      login_form.theAccountPW = @password
      response = @http_client.submit(login_form)
      unless response.search('h2:contains("Sign In to iTunes Connect")').empty?
        raise "Failed to sign into iTunes Connect"
      end
      @logged_in = true
    end

    def create_app(name, version, bundle_id, vendor_id, company_name)
      login unless @logged_in
      data = create_app_data(name, version, bundle_id, vendor_id, company_name).to_json
      response = post(
        "/WebObjects/iTunesConnect.woa/ra/apps/create/?appType=ios",
        data,
        {'content-type' => 'application/json'}
      )
      response.raise_if_errors
      response.data
    end


    def update_app
      config = AppConfiguration.new
      yield config
      login unless @logged_in
      data = update_app_data(config).to_json
      response = post(
        "/WebObjects/iTunesConnect.woa/ra/apps/version/save/#{config.app_id}",
        data,
        {'content-type' => 'application/json'}
      )
      response.raise_if_errors
      response.data
    end

  end

end
