require 'itc/models'

module Itc
  module PostData
    def create_app_data(name, version, bundle_id, vendor_id, company_name)
      {
        sectionErrorKeys: [],
        sectionInfoKeys: [],
        sectionWarningKeys: [],
        companyName: v(company_name, false, false),
        versionString: nil,
        appRegInfo: nil,
        bundleIds: {},
        enabledPlatformsForCreation: v(['ios'], true, true),
        name: nil,
        primaryLanguage: v(nil, true, true),
        bundleId: v(nil, true, true),
        bundleIdSuffix: v(nil, true, true),
        vendorId: nil,
        initialPlatform: 'ios',
        adamId: nil,
        newApp: {
          sectionErrorKeys: [],
          sectionInfoKeys: [],
          sectionWarningKeys: [],
          bundleId: v(bundle_id, true, true),
          bundleIdSuffix: v(nil, true, true),
          vendorId: {
            value: vendor_id
          },
          adamId: nil,
          appType: 'ios',
          name: {
            value: name
          },
          liveVersion: nil,
          inFlightVersion: nil,
          primaryLanguage: v('English', true, true),
          canAddVersion: false,
          appPageSectionLinks: nil,
          appPageMoreLinks: nil,
          appPageActionLinks: nil,
          appTransferState: nil,
          isDeleted: false,
          bundleSummaryInfo: nil
        }
      }
    end

    def update_app_data(config, localization)
      review = config.review_info
      store = config.store_info
      version = config.version_info
      build = config.build_version
      app_data = {
        sectionErrorKeys: [],
        sectionInfoKeys: [],
        sectionWarningKeys: [],
        name: v(version.name, true, true),
        primaryLanguage: v('English', true, true),
        version: v(version.version_number, true, true),
        copyright: v(store.copyright),
        primaryCategory: v(localization.inverse[store.primary_category]),
        primaryFirstSubCategory: v(nil),
        primarySecondSubCategory: v(nil),
        secondaryCategory: v(store.secondary_category.present? ? localization.inverse[store.secondary_category] : nil),
        secondaryFirstSubCategory: v(nil),
        secondarySecondSubCategory: v(nil),
        submittableAddOns: nil,
        newsstand: {
          isEnabled: false,
          isEditable: true,
          errorKeys: nil,
          isRequired: false,
          picture: {
            value: {
              assetToken: nil,
              url: nil,
              thumbNailUrl: nil,
              sortOrder: nil,
              originalFileName: nil
            },
            isEditable: true,
            isRequired: false,
            errorKeys: nil
          },
          pictureEmptyValue: true,
          isEmptyValue: false
        },
        gameCenterSummary: {
          leaderboards: {
            value: [],
            isEditable: false,
            isRequired: false,
            errorKeys: nil
          },
          displaySets: {
            value: [],
            isEditable: false,
            isRequired: false,
            errorKeys: nil
          },
          achievements: {
            value: [],
            isEditable: false,
            isRequired: false,
            errorKeys: nil
          },
          versionCompatibility: {
            value: [],
            isEditable: true,
            isRequired: false,
            errorKeys: nil
          },
          usedLeaderboards: 0,
          maxLeaderboards: 100,
          usedLeaderboardSets: 0,
          maxLeaderboardSets: 100,
          usedAchievementPoints: 0,
          maxAchievementPoints: 1000,
          isEnabled: false,
          isEditable: false,
          errorKeys: [],
          isRequired: false,
          isEmptyValue: false
        },
        canSendVersionLive: false,
        canPrepareForUpload: true,
        canRejectVersion: false,
        status: 'prepareForUpload',
        appType: 'iOS App',
        platform: 'ios',
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
          ageBand: nil,
          allRatingLevels: [
            'ITC.apps.ratings.level.YES',
            'ITC.apps.ratings.level.NO',
            'ITC.apps.ratings.level.NONE',
            'ITC.apps.ratings.level.INFREQUENT_MILD',
            'ITC.apps.ratings.level.FREQUENT_INTENSE'
          ],
          rating: nil,
          isEditable: true,
          isRequired: false,
          errorKeys: nil,
          countryRatings: {},
          isEmptyValue: false
        },
        details: {
          value: [
            {
              sectionErrorKeys: [],
              sectionInfoKeys: [],
              sectionWarningKeys: [],
              description: v(version.description),
              language: version.language,
              releaseNotes: v(version.release_notes, false, false),
              keywords: v(version.keywords),
              name: v(version.name, true, true),
              screenshots: v(screenshot_data(config)),
              appTrailers: {
                value: {
                  iphone4: v(nil),
                  watch: v(nil),
                  iphone35: v(nil),
                  iphone6: v(nil),
                  ipad: v(nil),
                  iphone6Plus: v(nil)
                },
                isEditable: true,
                isRequired: false,
                errorKeys: nil
              },
              supportURL: v(version.support_url),
              marketingURL: v(version.marketing_url),
              privacyURL: v(version.privacy_url),
              pageLanguageValue: version.language
            }
          ],
          isEditable: true,
          isRequired: true,
          errorKeys: nil
        },
        transitAppFile: v(nil),
        eula: {
          countries: [],
          isEditable: true,
          isRequired: false,
          errorKeys: nil,
          isEmptyValue: true,
          EULAText: nil
        },
        largeAppIcon: v(store.app_icon.to_itc_hash),
        watchAppIcon: {
          value: {
            assetToken: nil,
            url: nil,
            thumbNailUrl: nil,
            sortOrder: nil,
            originalFileName: nil
          },
          isEditable: true,
          isRequired: false,
          errorKeys: nil
        },
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
          shouldDisplayInStore: v(store.should_display_in_store),
          appRegInfo: nil
        },
        appVersionPageLinks: { },
        preReleaseBuildVersionString: v(nil),
        preReleaseBuildTrainVersionString: nil,
        preReleaseBuildIconUrl: nil,
        preReleaseBuildUploadDate: 0,
        preReleaseBuildsAreAvailable: false,
        preReleaseBuildIsLegacy: false,
        canBetaTest: true,
        isSaveError: false,
        validationError: false,
        releaseOnApproval: v(true),
        bundleInfo: {
          supportsAppleWatch: false
        },
        autoReleaseDate: v(nil)
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

    def submit_for_review_data(config, first_submit)
      puts "first_submit: #{first_submit}"
      submit_data = {
        versionInfo: nil,
        exportCompliance: {
          sectionErrorKeys: [],
          sectionInfoKeys: [],
          sectionWarningKeys: [],
          usesEncryption: v(''),
          encryptionUpdated: v(false),
          isExempt: v(''),
          containsProprietaryCryptography: v(''),
          containsThirdPartyCryptography: v(''),
          availableOnFrenchStore: v(''),
          ccatFile: v(nil),
          appType: 'iOS App',
          platform: 'ios',
          exportComplianceRequired: true
        },
        contentRights: {
          containsThirdPartyContent: {
            value: 'true'
          },
          hasRights: {
            value: 'true'
          }
        },
        adIdInfo: {
          sectionErrorKeys: [],
          sectionInfoKeys: [],
          sectionWarningKeys: [],
          usesIdfa: v('true', false, true),
          servesAds: v(nil, false, false),
          tracksInstall: v(true, false, false),
          tracksAction: v(nil, false, false),
          limitsTracking: v(true, false, false)
        },
        previousPurchaseRestrictions: {
          significantIssue: v(nil, false, true),
          previousVersions: []
        }
      }
      if first_submit
        submit_data[:exportCompliance][:usesEncryption] = v('false')
        submit_data[:exportCompliance][:encryptionUpdated] = nil
        submit_data[:contentRights][:containsThirdPartyContent] = v('true')
        submit_data[:contentRights][:hasRights] = v('true')
        submit_data[:previousPurchaseRestrictions] = nil
      end
      submit_data
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

    def v(value, is_editable = true, is_required = false)
      {
        value: value,
        isEditable: is_editable,
        isRequired: is_required,
        errorKeys: nil
      }
    end
  end
end
