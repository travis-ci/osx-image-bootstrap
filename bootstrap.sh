#!/bin/bash

if [[ `id -u` -eq 0 ]]; then
	echo "Try again, not as root."
	exit 1
fi


declare -a RUBIES=('2.0' '2.1.10' '2.2.5' '2.3' 'jruby-1.7' 'jruby')
DEFAULT_RUBY="2.0.0-p648"
declare -a BREW_PKGS=('git' 'wget' 'mercurial' 'xctool' 'node' \
  'coreutils' 'postgresql' 'postgis' 'sqlite' 'go' 'gpg' 'carthage' \
  'md5deep' 'pyenv' 'tmate' 'cmake' 'swiftlint')
declare -a PIP_PKGS=('virtualenv' 'numpy' 'scipy' 'tox')
declare -a NODE_VERSIONS=('6' '5' '4' '0.12' '0.10' '0.8' 'iojs')
export NVM_VERSION="v0.31.1"

TRAVIS_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEe8yPui0lLZpgaRNghw1H/2SGrpWV7Frw5FkftKGvMjkCL/FP6FeNZOUfWk5qISlhgkjZPu78nioZrUndTjOnSS8pWbecTrQCLKijufOS7A4n212bsdLpMwNuUE8lI1T0i9GcMRYfyK2jm/mosJkED2MomVzBi45NkEjG9IK/OncDcw+i15PDZcwONKZujc04KfNevhCIEt1sGJ0/mffwmQW5KVeKl5RjkKBxlmjo4ZSEVJV0CfzFQaua3c3cSswl3i5RX1wP6ciGfJlI/OZlXdQO4AwtcNFumklJFa2wf6BbRzXsaAieBnc1O2z885rEpXeeOsNzI/z6A+jLwEte2jZgMDh2x5fN3b4Au/iZt7ZhD7241QxN2quz3ej1zjr9MDJizQyzCrOvjvdNWE6CyAjoyF7aYptHCXuSjUbe7i+xx1PQk/MA+lEWAAzW+N4v4nSkHhVcyHnCzZB1WOlmSDNh19CvpF7zwnzs95D25goAH/veImF3RUMzKT5VTETqDgzF1CneAPq16//cIE/fnxtej0e5ZVPbj7oAgPEt0ERIgUo852iLjCHhD2n4juV564yGhs4Gf8eu3aGV+6kzzt8jBZlsiATF1WIwXJQy9Ga8F36v/GZmWVv+NIyRVw0aW1n8xaUzpVBdiNR8u+LvpOX9St6B4Z1iB6m0nhV2Sw== travis@mac"


echo "Rubies: $RUBIES"
echo "brew pkgs: $BREW_PKGS"
echo "node versions: $NODE_VERSIONS"
echo "nvm version: $NVM_VERSION"

bootstrap() {
  echo "--- setting system preferences."
  sudo systemsetup -settimezone GMT
  sudo systemsetup -setsleep Off
  sudo systemsetup -setcomputersleep Off
  sudo systemsetup -setdisplaysleep Off
  sudo systemsetup -setharddisksleep Off
  sudo systemsetup -setremotelogin on
  defaults write NSGlobalDomain NSAppSleepDisabled -bool YES

  echo "--- make .ssh/ && set permissions."
  mkdir -p ~/.ssh
  chmod 0700 ~/.ssh

  echo "--- Add Travis SSH key to authorized_keys && set permissions."
  echo "$TRAVIS_SSH_KEY" > ~/.ssh/authorized_keys
  chmod 0600 ~/.ssh/authorized_keys
  
  echo "--- Enable passwordless sudo for travis"
  echo 'travis ALL = (ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/travis
  sudo chmod 600 /etc/sudoers.d/travis

  echo "--- Put hardened sshd config in place"
  sudo tee /etc/ssh/sshd_config <<EOF
SyslogFacility AUTHPRIV
LogLevel VERBOSE
PubkeyAuthentication yes
AuthorizedKeysFile	.ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
KerberosAuthentication no
ChallengeResponseAuthentication no
GSSAPIAuthentication no
UsePAM no
UseDNS no
PermitEmptyPasswords no
LoginGraceTime 1m
PermitRootLogin no
UsePrivilegeSeparation sandbox
Subsystem sftp /usr/libexec/sftp-server
EOF
  
  echo "--- Overwrite .bashrc with our own."
  cat > ~/.bashrc <<EOF
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export TRAVIS=true
export CI=true
EOF
  
  echo "--- Ensure that ~/.profile loads ~/.bashrc"
  cat > ~/.profile <<EOF
[[ -s "\$HOME/.bashrc" ]] && source "\$HOME/.bashrc"
EOF
  
  echo "--- Ensure that ~/.bash_profile contents are correct"
  cat > ~/.bash_profile <<EOF
[[ -s "\$HOME/.profile" ]] && source "\$HOME/.profile"
[[ -s "\$HOME/.rvm/scripts/rvm" ]] && source "\$HOME/.rvm/scripts/rvm"
export NVM_DIR="\$HOME/.nvm"
[[ -s "\$NVM_DIR/nvm.sh" ]] && source "\$NVM_DIR/nvm.sh"
EOF
  
  echo "--- add 'gem: --no-document' so gem installs don't include documentation"
  cat > ~/.gemrc <<EOF
gem: --no-document
EOF
  
  echo "--- Turn off automatic software updating"
  sudo softwareupdate --schedule off
  
  echo "--- Install/upgrade brew."
  brew upgrade || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install) </dev/null"
  
  echo "--- Install tools with brew"
  ## homebrew fun
  brew update
  
  for PKG in "${BREW_PKGS[@]}"; do
    if [[ ! $(brew list | grep $PKG) ]]; then
      brew install $PKG
    else 
     echo "$PKG present"
    fi
  done

  echo "--- Install brew-cask"
  brew install caskroom/cask/brew-cask
  
  echo "--- Install tools with brew-cask"
  brew cask install xquartz
  brew cask install java
  brew cask install oclint
  brew cask install rubymotion
  # To prevent RubyMotion permission errors because `sudo motion update` created
  # this
  mkdir -p ~/Library/RubyMotion

  
  echo "--- Install Maven now that we have Java."
  brew install maven
  ## brew fun end
  
  brew cleanup

  echo "--- Update RubyMotion"
  sudo motion update

  # pip installs should be idempotent.
  for PKG in "${PIP_PKGS[@]}"; do
      pip install $PKG
  done

  # nvm
  echo "--- Install nvm"
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
  # end nvm

  echo "--- Install rvm"
  if [[ ! -d $HOME/.rvm ]]; then
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | bash -s stable
  fi
  source "$HOME/.rvm/scripts/rvm"

  echo "--- Install rubies with rvm"
  for RUBY in "${RUBIES[@]}"; do
    if [[ ! $(rvm list | grep $RUBY) ]]; then
      rvm install $RUBY
    else
      echo "$RUBY fine"
    fi
  done

  rvm alias create default $DEFAULT_RUBY

  
  # 'do' is 'quoted' because otherwise vim syntax highlighting is v unhappy
  echo "--- Install gems for all rubies"
  rvm all 'do' gem install nomad-cli cocoapods bundler rake xcpretty fastlane

  # end rvm
  
  echo "--- pod setup"
  pod setup

  echo '--- set $CI, $TRAVIS to true'
  sudo tee /etc/launchd.conf <<EOF
setenv CI true
setenv TRAVIS true
EOF

  
  cat > ~/runner.rb <<EOF
#!/usr/bin/env ruby

require "pty"
require "socket"

server = TCPServer.new("127.0.0.1", 15782)
socket = server.accept

PTY.spawn("/usr/bin/env", "TERM=xterm", "/bin/bash", "--login", "/Users/travis/build.sh") do |stdout, stdin, pid|
  IO.copy_stream(stdout, socket)

  _, exit_status = Process.wait2(pid)
  File.open("/Users/travis/build.sh.exit", "w") { |f| f.print((exit_status.exitstatus || 127).to_s) }
end

socket.close
EOF
  
  chmod +x ~/runner.rb
  
  mkdir -p ~/Library/LaunchAgents
  
  cat > ~/Library/LaunchAgents/com.travis-ci.runner.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.travis-ci.runner</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/travis/runner.rb</string>
    </array>
    <key>StandardOutPath</key>
    <string>/Users/travis/runner.rb.out</string>
    <key>StandardErrorPath</key>
    <string>/Users/travis/runner.rb.err</string>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
  
  sudo launchctl load ~/Library/LaunchAgents/com.travis-ci.runner.plist


  echo "You may want to install the following:"
  sudo softwareupdate -l -a
}

echo "Have you installed Xcode? (If you have, check xcode-select.)"
xcodebuild --help > /dev/null && bootstrap
