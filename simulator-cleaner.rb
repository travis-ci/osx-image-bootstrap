#!/usr/bin/env ruby
## from: https://gist.github.com/cabeca/3ff77007204e5479f7af
## Usage:
## ./simulator-cleaner.rb
##
## note from solarce: this does result in a few "Incompatible device" errors, so
## we may want to work on adding some more logic to skip those combos and save time
#
require 'JSON'

device_types = JSON.parse `xcrun simctl list -j devicetypes`
runtimes = JSON.parse `xcrun simctl list -j runtimes`
devices = JSON.parse `xcrun simctl list -j devices`

devices['devices'].each do |runtime, runtime_devices|
  runtime_devices.each do |device|
    puts "Removing device #{device['name']} (#{device['udid']})"
    `xcrun simctl delete #{device['udid']}`
  end
end

device_types['devicetypes'].each do |device_type|
  runtimes['runtimes'].select{|runtime| runtime['availability'] == '(available)'}.each do |runtime|
    puts "Creating #{device_type['name']} with #{runtime['name']}"
    command = "xcrun simctl create '#{device_type['name']}' #{device_type['identifier']} #{runtime['identifier']}"
    puts command
    command_output = `#{command}`
    sleep 0.5
  end
end
