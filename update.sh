#!/bin/bash

if [[ `id -u` -eq 0 ]]; then
	echo "Try again, not as root."
	exit 1
fi


brew install git wget mercurial xctool node coreutils postgresql postgis sqlite go gpg carthage md5deep 
brew update
brew upgrade

rvm install jruby-1.7.19
rvm install 1.9.3-p551
rvm install 2.1.5
rvm install 2.2.1
rvm install 2.0.0-p643

rvm alias create default 2.0.0-p643

rvm all do gem update --no-document=ri,rdoc nomad-cli cocoapods bundler rake xcpretty fastlane

pod setup

sudo softwareupdate -l -a
