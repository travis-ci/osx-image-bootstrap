#!/bin/bash

if [[ `id -u` -eq 0 ]]; then
	echo "Try again, not as root."
	exit 1
fi

# versions and things to install
declare -a RUBIES=('2.0' '2.1.10' '2.2.5' '2.3' 'jruby-1.7' 'jruby')
declare -a BREW_PKGS=('git' 'wget' 'mercurial' 'xctool' 'node' \
  'coreutils' 'postgresql' 'postgis' 'sqlite' 'go' 'gpg' 'carthage' \
  'md5deep')
declare -a NODE_VERSIONS=('6' '5' '4' '0.12' '0.10' '0.8' 'iojs')
export NVM_VERSION="v0.31.1"

## homebrew fun
brew update

for PKG in "${BREW_PKGS[@]}"; do
  if [[ ! $(brew list | grep $PKG) ]]; then
    brew install $PKG
  else 
   echo "$PKG present"
  fi
done

brew upgrade
## brew fun end

# nvm fun
if [[ ! -d $HOME/.nvm ]]; then
  wget -qO- "https://raw.githubusercontent.com/creationix/nvm/$NVM_VERSION/install.sh" | bash
fi

source $HOME/.nvm/nvm.sh

for VER in "${NODE_VERSIONS[@]}"; do
  if [[ ! $(nvm list | grep $VER) ]]; then
    nvm install $VER
  else
    echo "$VER present"
  fi
done

nvm list
## end nvm fun

# rvm fun
rvm get head

for RUBY in "${RUBIES[@]}"; do
  if [[ ! $(rvm list | grep $RUBY) ]]; then
    rvm install $RUBY
  else
    echo "$RUBY fine"
  fi
done

rvm alias create default 2.0

rvm all do gem install bundler rake 
rvm 2.0,2.1.10,2.2.5,2.3 do gem install xcpretty cocoapods fastlane nomad-cli
rvm get stable

echo -e "\n"
## end rvm fun

# cocoapods
pod setup

# update rubymotion
echo "Updating RubyMotion"
sudo motion update

# checking for system updates
echo "Updates you *may* want to install:"
sudo softwareupdate -l -a
