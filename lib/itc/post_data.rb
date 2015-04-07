require 'itc/models'

module Itc
  module PostData
    def create_app_data(name, version, bundle_id, vendor_id)
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
      }
    end

    def update_app_data(config, localization)
      review = config.review_info
      store = config.store_info
      version = config.version_info
      build = config.build_version
      app_data =
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
              screenshots: v(screenshot_data(config)),
              appTrailers: {}
            }
          ]
        },
        gameCenterSummary: {},
        name: v(version.name),
        primaryCategory: v(localization.inverse[store.primary_category]),
        secondaryCategory: v(store.secondary_category.present? ? localization.inverse[store.secondary_category] : nil),
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
        releaseOnApproval: v(true),
        primaryLanguage: v(version.language),
        preReleaseBuildVersionString: v(nil),
        newsstand: v(nil),
        copyright: v(store.copyright),
        appVersionPageLinks: {},
        largeAppIcon: v(store.app_icon.to_itc_hash),

        eula: {
          EULATEXT: nil,
          countries: [],
          errorKeys: [],
          isEditable: true,
          isEmptyValue: true,
          isRequired: false
        },
      }
      if build
        app_data = app_data.merge({
          preReleaseBuildVersionString: v(build.build_version),
          preReleaseBuildTrainVersionString: build.train_version,
          preReleaseBuildIconUrl: build.icon_url,
          preReleaseBuildUploadDate: build.upload_timestamp
        })
      end
      app_data
    end

    def submit_for_review_data(config)
      submit_review_data =
      {
        exportCompliance: {
          sectionErrorKeys: [],
          sectionInfoKeys: [],
          sectionWarningKeys: [],
          usesEncryption: nil,
          encryptionUpdated: nil,
          isExempt: nil,
          containsProprietaryCryptography: nil,
          containsThirdPartyCryptography: nil,
          availableOnFrenchStore: nil,
          ccatFile: nil,
          appType: 'iOS App',
          exportComplianceRequired: false
        },
        contentRights: {
          containsThirdPartyContent: {
            value: 'false'
          }
        },
        adIdInfo: {
          sectionErrorKeys: [],
          sectionInfoKeys: [],
          sectionWarningKeys: [],
          usesIdfa: {
            value: 'false',
            isEditable: false,
            isRequired: true,
            errorKeys: nil
          },
          servesAds: {
            value: nil,
            isEditable: false,
            isRequired: false,
            errorKeys: nil
          },
          tracksInstall: {
            value: nil,
            isEditable: false,
            isRequired: false,
            errorKeys: nil
          },
          tracksAction: {
            value: nil,
            isEditable: false,
            isRequired: false,
            errorKeys: nil
          },
          limitsTracking: {
            value: nil,
            isEditable: false,
            isRequired: false,
            errorKeys: nil
          }
        },
        previousPurchaseRestrictions: {
          significantIssue: {
            value: nil,
            isEditable: false,
            isRequired: true,
            errorKeys: nil
          },
          previousVersions: []
        }
      }
      submit_review_data
    end

    def screenshot_data(config)
      screenshots = {}
      ScreenshotContainer::DEVICE_TYPES.each do |device|
        itc_name = ScreenshotContainer::DEVICE_NAME_TO_ITC_NAME.fetch(device.to_s)
        screenshots[itc_name] = v(config.version_info.screenshots.send(device).map{ |ss| v(ss.to_itc_hash) })
      end
      screenshots
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
        value: value,
        isEditable: true,
        isRequired: false,
        errorKeys: nil
      }
    end

  end
end
