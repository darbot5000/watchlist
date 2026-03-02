ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
require "bundler/setup"
require "bootsnap/setup" if File.exist?("#{__dir__}/../vendor/bundle/ruby/*/gems/bootsnap-*/lib/bootsnap/setup.rb")
