ITC Ruby api
============

## Installation

Add this line to your application's Gemfile:

    gem 'itc'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install itc

## Usage

### Creating an App

```ruby
> require 'itc'

> agent = Itc::Agent.new("username", "password")

# Register "bundle_id" in developer portal first
> app_data = agent.create_app("name", "version", "bundle_id", "vendor_id", "company_name")

# app_id is Apple's unique identifier for the app
> app_id = app_data['newApp']['adamId']
```

### Updating an app

```ruby
> require 'itc'

> agent = Itc::Agent.new("username", "password")
> agent.update_app(app_id) do |config|
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

#### Updating app screenshots / icon
```ruby
> require 'itc'

> agent = Itc::Agent.new("username", "password")
> agent.update_app(app_id) do |config|
    if config.version_info.screenshots.ipad.length != 2
        config.version_info.screenshots.ipad = ["/path/to/ipad1.jpg", "/path/to/ipad2.jpg"]
    end
    if config.version_info.screenshots.iphone5_5.length != 3
        config.version_info.screenshots.iphone5_5 = ["/path/to/iphone5_5_1.jpg", "/path/to/iphone5_5_2.jpg", "/path/to/iphone5_5_3.jpg"]
    end
    if config.store_info.app_icon.empty?
        config.store_info.app_icon = '/path/to/icon.jpg'
    end
  end
```

## Contributing

1. Fork it ( https://github.com/dwnld/itc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License:

The code is available at github [project][home] under [MIT license][license].

[home]: https://github.com/dwnld/itc
[license]: https://github.com/dwnld/itc/blob/master/LICENSE.txt

