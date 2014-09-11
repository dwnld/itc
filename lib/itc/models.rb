module Itc
  class AppConfiguration
    attr_accessor :review_info, :store_info, :version_info, :ratings, :app_id

    def initialize
      @review_info = AppReviewInfo.new
      @store_info = AppStoreInfo.new
      @version_info = LocalizedVersionInfo.new
      @ratings = Ratings.new
    end
  end

  class AppReviewInfo
    attr_accessor :email_address, :entitlement_usages, :first_name, :last_name
    attr_accessor :phone_number, :review_notes, :username, :password

    def entitlement_usages
      @entitlement_usages ||= []
    end
  end

  class AppStoreInfo
    attr_accessor :app_icon, :primary_category, :secondary_category, :copyright
    attr_accessor :address_line1, :address_line2, :address_line3, :city_name, :state ,:country, :postal_code
    attr_accessor :email_address, :first_name, :last_name, :phone_number, :trade_name
    attr_accessor :should_display_in_store

    def should_display_in_store
      @should_display_in_store ||= false
    end

  end

  class Ratings
    NONE = "ITC.apps.ratings.level.NONE"
    INFREQUENT = "ITC.apps.ratings.level.INFREQUENT_MILD"
    MILD = "ITC.apps.ratings.level.INFREQUENT_MILD"
    FREQUENT = "ITC.apps.ratings.level.FREQUENT_INTENSE"
    INTENSE = "ITC.apps.ratings.level.FREQUENT_INTENSE"

    BOOLEAN_RATINGS = [:unrestricted_web_access, :gambling_contests]
    NON_BOOLEAN_RATINGS = [
      :cartoon_fantasy_violence, :realistic_violence, :prolonged_graphic_sadistic_realistic_violence,
      :profanity_crude_humor, :mature_suggestive, :horror, :medical_treatment_info,
      :alcohol_tobacco_drugs, :gambling, :sexual_content_nudity, :graphic_sexual_content_nudity
    ]

    # Like attr_accessor, but returns "ITC.apps.ratings.level.NO" for falsey values
    # (or "ITC.apps.ratings.level.NO" itself), others will be "ITC.apps.ratings.level.YES"
    def self.boolean_attr_accessor(*attrs)
      attrs.each do |a|
        attr_writer a
        class_eval <<-EOF
          def #{a}
            if @#{a} && @#{a} != "ITC.apps.ratings.level.NO"
              "ITC.apps.ratings.level.YES"
            else
              "ITC.apps.ratings.level.NO"
            end
          end
        EOF
      end
    end

    attr_accessor *NON_BOOLEAN_RATINGS
    boolean_attr_accessor *BOOLEAN_RATINGS

    def set_all_ratings_to(rating)
      NON_BOOLEAN_RATINGS.each do |category|
        send("#{category}=", rating)
      end
    end
  end

  class LocalizedVersionInfo
    attr_accessor :description, :keywords, :name, :release_notes, :screenshots, :version_number, :language
    attr_accessor :support_url, :privacy_url, :marketing_url

    def screenshots
      @screenshots ||= ScreenshotContainer.new
    end
  end

  class ScreenshotContainer
    DEVICE_TYPES = [:iphone4_7, :iphone5_5, :iphone4, :iphone3_5, :ipad]
    attr_reader *DEVICE_TYPES
    attr_accessor :should_update

    ITC_NAME_TO_DEVICE_NAME = {
      '5.5-Inch' => 'iphone5_5',
      '4.7-Inch' => 'iphone4_7',
      'ipad' => 'ipad',
      'iphone35' => 'iphone3_5',
      'iphone4' => 'iphone4'
    }

    DEVICE_NAME_TO_ITC_NAME = ITC_NAME_TO_DEVICE_NAME.invert

    DEVICE_TYPES.each do |device|
      define_method("#{device}=") do |screenshots|
        raise ArgumentError, "Must be an array" unless screenshots.kind_of?(Array)
        screenshots =
          if screenshots.all?{ |f| f.kind_of?(String) }
            screenshots.map{ |s| Screenshot.new(nil, nil, nil, s) }
          elsif screenshots.all?{ |f| f.kind_of?(Screenshot) }
            screenshots
          else
            raise ArgumentError, "Cannot set screenshots, array must all be Strings or Screenshots"
          end
        instance_variable_set("@#{device}", screenshots)
        self.should_update << device
      end
    end

    def should_update
      @should_update ||= Set.new
    end
  end

  Screenshot = Struct.new(:asset_token, :full_size_url, :sort_order, :url) do
    def self.from_itc(hash)
      struct = self.new
      struct.asset_token = hash['assetToken']
      struct.full_size_url = hash['fullSizeUrl']
      struct.sort_order = hash['sortOrder']
      struct.url = hash['url']
      struct
    end

    def to_itc_hash
      {
        assetToken: asset_token,
        fullSizeUrl: nil,
        sortOrder: sort_order,
        url: url
      }
    end

    def empty?
      asset_token.empty?
    end

  end

end
