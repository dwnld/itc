require 'itc/models'

module Itc
  module PostData
    def create_app_data(name, version, bundle_id, vendor_id, company_name)
      {
        newApp: {
          appType: 'iOS App',
          bundleId: v(bundle_id),
          bundleIdSuffix: v(nil),
          name: v(name),
          primaryLanguage: v('English'),
          vendorId: v(vendor_id),
        },
        versionString: v(version),
        companyName: v(company_name)
      }
    end


    def update_app_data(config)
      review = config.review_info
      store = config.store_info
      version = config.version_info
      {
        appType: 'iOS App',
        appReviewInfo: {
          emailAddress: v(review.email_address),
          entitlementUsages: v(review.entitlement_usages),
          firstName: v(review.first_name),
          lastName: v(review.last_name),
          phoneNumber: v(review.phone_number),
          reviewNotes: v(review.review_notes),
          userName: v(review.username),
          password: v(review.password),
        },
        appStoreInfo: {
          addressLine1: v(store.address_line1),
          addressLine2: v(store.address_line2),
          addressLine3: v(store.address_line3),
          cityName: v(store.city_name),
          state: v(store.state),
          country: v(store.country),
          postalCode: v(store.postal_code),
          emailAddress: v(store.email_address),
          firstName: v(store.first_name),
          lastName: v(store.last_name),
          phoneNumber: v(store.phone_number),
          tradeName: v(store.trade_name),
          shouldDisplayInStore: v(store.should_display_in_store)
        },
        details: {
          isRequired: true,
          isEditable: true,
          value: [
            {
              description: v(version.description),
              keywords: v(version.keywords),
              releaseNotes: v(version.release_notes),
              name: v(version.name),
              language: version.language,
              pageLanguageValue: version.language,
              supportURL: v(version.support_url),
              marketingURL: v(version.marketing_url),
              privacyURL: v(version.privacy_url),
              screenshots: v({}),
              appTrailers: {}
            }
          ]
        },
        gameCenterSummary: {},
        name: v(version.name),
        primaryCategory: v(store.primary_category),
        secondaryCategory: v(store.secondary_category),
        version: v(version.version_number),
        ratings: {
          booleanDescriptors: (
            Ratings::BOOLEAN_RATINGS.map do |rating|
              rating_hash(rating, config.ratings.send(rating))
            end
          ),
          nonBooleanDescriptors: (
            Ratings::NON_BOOLEAN_RATINGS.map do |rating|
              rating_hash(rating, config.ratings.send(rating))
            end
          ),
          isEditable: true
        },

        secondaryFirstSubCategory: v(nil),
        secondarySecondSubCategory: v(nil),
        primaryFirstSubCategory: v(nil),
        primarySecondSubCategory: v(nil),
        releaseOnApproval: v(nil),
        primaryLanguage: v(version.language),
        preReleaseBuildVersionString: v(nil),
        newsstand: v(nil),
        copyright: v(nil),
        appVersionPageLinks: {},
        largeAppIcon: {},

        eula: {
          EULATEXT: nil,
          countries: [],
          errorKeys: [],
          isEditable: true,
          isEmptyValue: true,
          isRequired: false
        },
      }
    end

    def rating_hash(name, level)
      {
        name: "ITC.apps.ratings.descriptor.#{name.upcase}",
        level: level,
        rank: nil
      }
    end

    def v(value)
      {
        value: value
      }
    end

  end
end
