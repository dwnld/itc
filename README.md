ITC Ruby api
============

## Creating an App

```ruby
> require 'itc'

> agent = Itc::Agent.new("username", "password")

# Register "bundle_id" in developer portal first
> app_data = agent.create_app("name", "version", "bundle_id", "vendor_id", "company_name")

# new_app_id is Apple's unique identifier for the app
> new_app_id = app_data['newApp']['adamId']
```

## Updating an app

```ruby
> require 'itc'

> agent = Itc::Agent.new("username", "password")
> agent.update_app do |config|
    config.app_id = new_app_id

    # Set review info
    config.review_info.email_address = "me@example.com"
    config.review_info.review_notes = "This is my app"

    # Set app store info
    config.store_info.description = "The best app ever!"


    # Set ratings
    config.ratings.unrestricted_web_access = true
    config.ratings.gambling_contests = false
    config.ratings.cartoon_fantasy_violence = Itc::Ratings::FREQUENT
    config.ratings.realistic_violence = Itc::Ratings::NONE
  end
```

## License :

The code is available at github [project][home] under [MIT license][license].

[home]: https://github.com/dwnld/itc
[license]: http://revolunet.mit-license.org

