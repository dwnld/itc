require "bundler/gem_tasks"
require 'itc'

namespace :itc do
  task :reject_apps_by_sku do
    agent = Itc::Agent.new(ENV['USERNAME'], ENV['PASSWORD'])
    ENV['APPS'].split(",").each do |sku|
      agent.developer_reject(sku)
    end
  end
end
