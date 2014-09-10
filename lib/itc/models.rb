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
    attr_accessor :app_icon, :verion, :primary_category, :secondary_category, :copyright
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
        define_method(a) do
          a_val = instance_variable_get("@#{a}")
          if a_val && a_val != "ITC.apps.ratings.level.NO"
            "ITC.apps.ratings.level.YES"
          else
            "ITC.apps.ratings.level.NO"
          end
        end
      end
    end

    attr_accessor *NON_BOOLEAN_RATINGS
    boolean_attr_accessor *BOOLEAN_RATINGS

  end

  class LocalizedVersionInfo
    attr_accessor :description, :keywords, :name, :release_notes, :screenshots, :version_number, :language
    attr_accessor :support_url, :privacy_url, :marketing_url
  end

end
