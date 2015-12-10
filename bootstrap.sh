#!/bin/bash

if [[ `id -u` -eq 0 ]]; then
	echo "Try again, not as root."
	exit 1
fi

mkdir -p ~/.ssh
chmod 0700 ~/.ssh
cat >> ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEe8yPui0lLZpgaRNghw1H/2SGrpWV7Frw5FkftKGvMjkCL/FP6FeNZOUfWk5qISlhgkjZPu78nioZrUndTjOnSS8pWbecTrQCLKijufOS7A4n212bsdLpMwNuUE8lI1T0i9GcMRYfyK2jm/mosJkED2MomVzBi45NkEjG9IK/OncDcw+i15PDZcwONKZujc04KfNevhCIEt1sGJ0/mffwmQW5KVeKl5RjkKBxlmjo4ZSEVJV0CfzFQaua3c3cSswl3i5RX1wP6ciGfJlI/OZlXdQO4AwtcNFumklJFa2wf6BbRzXsaAieBnc1O2z885rEpXeeOsNzI/z6A+jLwEte2jZgMDh2x5fN3b4Au/iZt7ZhD7241QxN2quz3ej1zjr9MDJizQyzCrOvjvdNWE6CyAjoyF7aYptHCXuSjUbe7i+xx1PQk/MA+lEWAAzW+N4v4nSkHhVcyHnCzZB1WOlmSDNh19CvpF7zwnzs95D25goAH/veImF3RUMzKT5VTETqDgzF1CneAPq16//cIE/fnxtej0e5ZVPbj7oAgPEt0ERIgUo852iLjCHhD2n4juV564yGhs4Gf8eu3aGV+6kzzt8jBZlsiATF1WIwXJQy9Ga8F36v/GZmWVv+NIyRVw0aW1n8xaUzpVBdiNR8u+LvpOX9St6B4Z1iB6m0nhV2Sw== travis@mac
EOF
chmod 0600 ~/.ssh/authorized_keys

sudo tee /etc/sshd_config <<EOF
SyslogFacility AUTHPRIV
LogLevel VERBOSE
PubkeyAuthentication yes
AuthorizedKeysFile	.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
UseDNS no
PermitEmptyPasswords no
LoginGraceTime 1m
PermitRootLogin no
UsePrivilegeSeparation sandbox
Subsystem sftp /usr/libexec/sftp-server
EOF

cat > ~/.bashrc <<EOF
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export TRAVIS=true
export CI=true
EOF

cat > ~/.profile <<EOF
[[ -s "\$HOME/.bashrc" ]] && source "\$HOME/.bashrc"
EOF

cat > ~/.bash_profile <<EOF
[[ -s "\$HOME/.profile" ]] && source "\$HOME/.profile"
[[ -s "\$HOME/.rvm/scripts/rvm" ]] && source "\$HOME/.rvm/scripts/rvm"
EOF

sudo softwareupdate --schedule off

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install git wget mercurial xctool node coreutils postgresql postgis sqlite go gpg

brew install caskroom/cask/brew-cask

brew cask install xquartz
brew cask install java
brew cask install oclint
brew cask install rubymotion

brew install maven

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source "$HOME/.rvm/scripts/rvm"
rvm install jruby-1.7.19
rvm install 1.9.3-p551
rvm install 2.1.5
rvm install 2.2.1
rvm install 2.0.0-p643

rvm alias create default 2.0.0-p643

rvm all do gem install --no-rdoc --no-ri nomad-cli cocoapods bundler rake xcpretty fastlane

pod setup

sudo tee /etc/launchd.conf <<EOF
setenv CI true
setenv TRAVIS true
EOF

# To prevent RubyMotion permission errors because `sudo motion update` created
# this
mkdir -p ~/Library/RubyMotion

cat > ~/runner.rb <<EOF
#!/usr/bin/env ruby

require "pty"
require "socket"

server = TCPServer.new("127.0.0.1", 15782)
socket = server.accept

PTY.open do |io, file|
  pid = Process.spawn({"TERM" => "xterm"}, "/bin/bash", "--login", "/Users/travis/build.sh", [:out, :err] => file)
  pipe_thread = Thread.new do
    loop do
      socket.print(io.read(1))
    end
  end

  _, exit_status = Process.wait2(pid)
  pipe_thread.kill

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

launchctl load ~/Library/LaunchAgents/com.travis-ci.runner.plist
