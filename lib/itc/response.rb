require 'active_support/all'

module Itc
  class Response
    attr_reader :data
    def initialize(body)
      @json = JSON.parse(body)
      @data = @json['data']
    end

    def raise_if_errors(message=nil)
      error_messages = errors
      raise ItunesError, "#{message} #{error_messages}" if error_messages.present?
    end

    def errors
      error_messages = []
      sectionErrorKeys = @data.try(:[], 'sectionErrorKeys').presence
      error_messages << sectionErrorKeys if sectionErrorKeys
      return if sectionErrorKeys.try(:first) =~ /You haven't made any changes./
      return if sectionErrorKeys.try(:first) =~ /App Review has rejected this app/
      error_messages << @json['messages']['error'] if @json['messages'].try(:[], 'error').presence
      if error_messages.presence
        error_messages << sectionErrors
        error_messages
      end
    end

    def sectionErrors
      errors = {}
      return errors unless data
      data.each_with_parent do |parent, k, v|
        if k == 'errorKeys' && v.present?
          errors[parent] = v
        end
      end
      errors
    end

  end

  class ImageUploadResponse
    attr_reader :data
    def initialize(body)
      @data = JSON.parse(body)
    end
  end

  class ItunesError < StandardError; end
  class App
    def initialize(itc_data)
      @data = itc_data
      @versions = (itc_data['versions'] || itc_data['versionSets']).map{|v| AppVersion.new(v) }
    end

    def id
      @data['adamId']
    end

    def name
      @data['name']
    end

    def bundle_id
      @data['bundleId']
    end

    def icon_url
      @data['iconURL']
    end

    def last_modified
      @data['lastModifiedDate']
    end

    def sku
      @data['vendorId']
    end

    alias_method :vendor_id, :sku

    def versions
      @versions
    end
  end

  class AppVersion
    include Comparable
    def initialize(itc_data)
      @data = itc_data
    end

    def version
      @data['version'] || @data['deliverableVersion'].try(:[], 'version')
    end

    def state
      @data['stateKey'] || @data['deliverableVersion'].try(:[], 'stateKey')
    end

    def <=>(other)
      return 0 if self.version == other.version
      return -1 unless Gem::Version.correct?(self.version)
      return 1 unless Gem::Version.correct?(other.version)
      Gem::Version.new(self.version) <=> Gem::Version.new(other.version)
    end
  end

  class CandidateBuild
    def initialize(data)
      @data = data
    end

    def build_version
      @data['buildVersion']
    end

    def train_version
      @data['trainVersion']
    end

    def upload_timestamp
      @data['upload_timestamp']
    end

    def icon_url
      @data['iconUrl']
    end

    def app_name
      @data['app_name']
    end

    def state
      @data['state']
    end
  end

  class Localization
    def initialize(l10n, ref_data)
      if ref_data
        @l10n = l10n.keep_if{ |k, v| k.in?(ref_data['iosgenres'])}
      else
        @l10n = l10n
      end
    end

    def inverse
      @inverse ||= Localization.new(@l10n.invert, nil)
    end

    def [](key)
      raise ArgumentError, "No such key #{key}" unless @l10n[key].present?
      @l10n[key]
    end
  end
end
