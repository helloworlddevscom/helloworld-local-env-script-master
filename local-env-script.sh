#!/bin/zsh

# This script mostly automates this tutorial: https://getgrav.org/blog/macos-catalina-apache-multiple-php-versions

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
WHITE=$(tput setaf 255)
BLACK=$(tput setaf 232)
PINK=$(tput setaf 207)
GREEN=$(tput setaf 34)
PURPLE=$(tput setaf 93)
WHITEBG=$(tput setab 255)
GRAYBG=$(tput setab 236)
NONEBG=$(tput setab sgr0)

# Welcome user.
echo
echo "${GRAYBG}${WHITE}<  Welcome to ${GREEN}Hello${PINK}World${PURPLE};)${WHITE}! Lets get your local environment set up!  />${PINK}${NORMAL}"
echo

# Confirm user really wants to do this.
echo "${PINK}${BOLD}This script will work best on a clean install of MacOS >= Catalina 10.15. Please verify your version by clicking the Apple icon in menu bar > About This Mac before proceeding.${NORMAL}"
echo
echo -n "Are you ready to setup your local environment? (y/n):"
echo
read REPLY
if [[ $REPLY =~ ^[Nn]$ ]]
then
	echo "Maybe next time..."
  exit 1
fi

# Check whether one of our pre modified files exists.
if [[ ! -f "$DIR"/files/httpd.conf ]]
then
	echo "${PINK}${BOLD}Can't find necessary files directory. Please ensure there is a files directory in the same directory as this script.${NORMAL}"
  exit 1
fi
echo "${GREEN}${BOLD}Looks good...${NORMAL}"

# Store password so we can use it for sudo later.
# @TODO: This is not working. User is still being prompted for password multiple times.
echo "${GREEN}${BOLD}Asking for root password...${NORMAL}"
read -rs PW\?"[sudo] Enter password for user root:"
echo


# Install XCode Command Line Tools.
echo "${GREEN}${BOLD}Installing XCode Command Line Tools...${NORMAL}"
xcode-select --install

# The default shell in MacOS 10.15 Catalina is zsh, so lets make it pretty.
# Install Oh My Zsh.
echo "${GREEN}${BOLD}Installing Oh My Zsh...${NORMAL}"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# By this point ~/.zshrc should exist. It either should have come along with MacOS (not sure on this),
# or been created by Oh My Zsh. Lets verify, because otherwise we'll have to create it ourselves.
echo "${GREEN}${BOLD}Checking for ~/.zshrc...${NORMAL}"
if [[ ! -f ~/.zshrc ]]
then
  # If it doesn't exist, copy default version from Oh My Zsh.
	cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
fi
# Set theme to agnoster. The default is robbyrussell.
sed -i '' "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g" ~/.zshrc
# Install powerline fonts necessary for agnoster.
# See: https://github.com/powerline/fonts
# See: https://github.com/agnoster/agnoster-zsh-theme
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts
source ~/.zshrc

# Install Homebrew.
echo "${GREEN}${BOLD}Installing Homebrew...${NORMAL}"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
echo "${GREEN}${BOLD}Setting path to Homebrew in ~/.zshrc...${NORMAL}"
# See: https://unix.stackexchange.com/questions/52131/sed-on-osx-insert-at-a-certain-line
sed -i '' -e '$a\
export PATH=/usr/local/bin:/usr/local/sbin:$PATH' ~/.zshrc
source ~/.zshrc

# Install MacOS Catalina required libraries (according to tutorial).
echo "${GREEN}${BOLD}Installing some required libraries...${NORMAL}"
brew install openldap libiconv
# Install libffi which is necessary for PHP 7.4 to work.
# See: https://stackoverflow.com/questions/44706311/how-to-install-libffi-dev-on-mac-os-x
brew install libffi
ln -s /usr/local/opt/libffi/lib/libffi.dylib /usr/local/opt/libffi/lib/libffi.7.dylib

# Install Git.
echo "${GREEN}${BOLD}Install Git...${NORMAL}"
brew install git

# Stop and unload MacOS installed Apache.
echo "${GREEN}${BOLD}Stopping MacOS Apache...${NORMAL}"
echo $PW | sudo apachectl stop
echo $PW | sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null

# Install Homebrew Apache.
echo "${GREEN}${BOLD}Installing Homebrew Apache...${NORMAL}"
brew install httpd
echo $PW | sudo brew services start httpd

# Replace default httpd.conf with our pre modified one.
echo "${GREEN}${BOLD}Replacing httpd.conf...${NORMAL}"
cp "$DIR"/files/httpd.conf /usr/local/etc/httpd/httpd.conf

# Edit httpd.conf and change some user specific settings.
echo "${GREEN}${BOLD}Editing httpd.conf...${NORMAL}"
# sed -i '' "s/Listen 8080/Listen *:80/g" "/usr/local/etc/httpd/httpd.conf"
sed -i '' "s/DocumentRoot \"\/usr\/local\/var\/www\"/DocumentRoot \"\/Users\/$USER\/Sites\"/g" "/usr/local/etc/httpd/httpd.conf"
sed -i '' "s/<Directory \"\/usr\/local\/var\/www\">/<Directory \"\/Users\/$USER\/Sites\">/g" "/usr/local/etc/httpd/httpd.conf"
sed -i '' "s/User _www/User $USER/g" "/usr/local/etc/httpd/httpd.conf"

# perl -0777 -pi -e 's/#   AllowOverride FileInfo AuthConfig Limit\n#\n  AllowOverride None/#   AllowOverride FileInfo AuthConfig Limit\n#\n  AllowOverride All/igs' /usr/local/etc/httpd/httpd.conf

# awk '/AllowOverride None/{c++;if(c==2){sub("AllowOverride None","AllowOverride All");}}1' /usr/local/etc/httpd/httpd.conf

# sed  -i '' '0,/AllowOverride None/! {0,/AllowOverride None/ s/AllowOverride None/AllowOverride All/}' "/usr/local/etc/httpd/httpd.conf"

# sed -i '' '/^a test$/{$!{N;s/^#   AllowOverride FileInfo AuthConfig Limit\n#\n  AllowOverride None$/#   AllowOverride FileInfo AuthConfig Limit\n#\n  AllowOverride All/;ty;P;D;:y}}' "/usr/local/etc/httpd/httpd.conf"

echo "${GREEN}${BOLD}Creating Sites directory...${NORMAL}"
mkdir ~/Sites
echo "<h1>My User Web Root</h1>" > ~/Sites/index.html

# Replace default httpd-vhosts.conf with our pre modified one.
echo "${GREEN}${BOLD}Replacing httpd-vhosts.conf...${NORMAL}"
cp "$DIR"/files/httpd-vhosts.conf /usr/local/etc/httpd/extra/httpd-vhosts.conf
echo "${GREEN}${BOLD}Editing httpd-vhosts.conf...${NORMAL}"
sed -i '' "s/your_user/$USER/g" "/usr/local/etc/httpd/extra/httpd-vhosts.conf"

# Create test site.
echo "${GREEN}${BOLD}Creating test site...${NORMAL}"
mkdir ~/Sites/test
echo "<h1>Test Site</h1>" > ~/Sites/test/index.html

# Install DNS Masq.
# @TODO: Not working. Edit hosts file instead.
# echo "${GREEN}${BOLD}Installing DNS Masq...${NORMAL}"
# brew install dnsmasq
# echo 'address=/.local/127.0.0.1' > /usr/local/etc/dnsmasq.conf
# echo $PW | sudo brew services start dnsmasq
# echo $PW | sudo mkdir -v /etc/resolver
# echo $PW | sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/local'

# Replace hosts file with pre modified one.
echo "${GREEN}${BOLD}Replacing hosts file...${NORMAL}"
echo $PW | sudo cp "$DIR"/hosts /etc/hosts

# Install PHP versions.
echo "${GREEN}${BOLD}Installing PHP versions 7.4, 8.1...${NORMAL}"
brew install php@7.4
brew install php
# Homebrew installs the latest PHP version into /usr/local/opt/php. We need a symlink
# so that the switcher script will work. When the latest version of
# PHP is not 8.1 this will need to be updated.
ln -s /usr/local/opt/php /usr/local/opt/php@8.1/
brew link php@8.1

echo "${GREEN}${BOLD}Creating PHP info file at http://localhost/info.php...${NORMAL}"
echo "<?php phpinfo();" > ~/Sites/info.php

# Install PHP switcher script.
echo "${GREEN}${BOLD}Installing PHP switcher script...${NORMAL}"
curl -L https://gist.githubusercontent.com/rhukster/f4c04f1bf59e0b74e335ee5d186a98e2/raw > /usr/local/bin/sphp
chmod +x /usr/local/bin/sphp

# Install APCU.
echo "${GREEN}${BOLD}Installing APCU package...${NORMAL}"

sphp 7.4
pecl uninstall -r apcu
printf "\n" | pecl install apcu

sphp 8.1
pecl uninstall -r apcu
printf "\n" | pecl install apcu

# Install YAML.
echo "${GREEN}${BOLD}Installing YAML package...${NORMAL}"
brew install libyaml

sphp 7.4
pecl uninstall -r yaml
printf "\n" | pecl install yaml

sphp 8.1
pecl uninstall -r yaml
printf "\n" | pecl install yaml

# Install Xdebug.
echo "${GREEN}${BOLD}Installing Xdebug package...${NORMAL}"

sphp 7.4
pecl uninstall -r xdebug
printf "\n" | pecl install xdebug
sed -i '' "s/zend_extension=\"xdebug.so\"//g" "/usr/local/etc/php/7.4/php.ini"
cp "$DIR"/files/ext-xdebug-3.ini /usr/local/etc/php/7.4/conf.d/ext-xdebug.ini

sphp 8.1
pecl uninstall -r xdebug
printf "\n" | pecl install xdebug
sed -i '' "s/zend_extension=\"xdebug.so\"//g" "/usr/local/etc/php/8.1/php.ini"
cp "$DIR"/files/ext-xdebug-3.ini /usr/local/etc/php/8.1/conf.d/ext-xdebug.ini

# Install Xdebug switcher script.
echo "${GREEN}${BOLD}Installing Xdebug switcher script...${NORMAL}"
curl -L https://gist.githubusercontent.com/rhukster/073a2c1270ccb2c6868e7aced92001cf/raw > /usr/local/bin/xdebug
chmod +x /usr/local/bin/xdebug

echo "${GREEN}${BOLD}Restarting Apache...${NORMAL}"
echo $PW | sudo apachectl -k restart


# Install Homebrew MySQL 5.7.
echo "${GREEN}${BOLD}Installing Homebrew MySQL 5.7...${NORMAL}"
brew install mysql@5.7
brew link mysql@5.7 --force
brew services start mysql@5.7

# Run secure installation script. It seems this sometimes doesn't exist?
# @TODO: If this doesn't exist, not sure what to tell user about how to set their root password.
# if [[ -f /usr/local/bin/mysql_secure_installation ]]
# then
	# Notify user they will need to answer questions.
	# @TODO: Answer questions automatically.
	# osascript -e 'display notification "We have some questions for you :-)" with title "Please check terminal"';
	# echo "You'll be asked some questions in order to configure MySQL.\n
	# We recommend you answer in this order:\n
	# Enter password for user root: root\n
	# Change the password for root: y\n
	# Remove anonymous users?: y\n
	# Disallow root login remotely?: y\n
	# Remove test database and access to it?: y\n
	# Reload privilege tables now?: y"
	# # echo $PW | sudo /usr/local/bin/mysql_secure_installation
	# printf "$PW\nn\nroot\ny\ny\ny\ny\ny\n" | sudo /usr/local/bin/mysql_secure_installation

	# This supposedly does the same thing as running /usr/local/bin/mysql_secure_installation
	# But the user will not need to answer prompts.
	# See: https://stackoverflow.com/a/27759061/1401823
	# Make sure that NOBODY can access the server without a password
	mysql -e "UPDATE mysql.user SET Password = PASSWORD('root') WHERE User = 'root'"
	# Kill the anonymous users
	mysql -e "DROP USER ''@'localhost'"
	# Because our hostname varies we'll use some Bash magic here.
	mysql -e "DROP USER ''@'$(hostname)'"
	# Kill off the demo database
	mysql -e "DROP DATABASE test"
	# Disallow remote access
	mysql -e "DELETE FROM mysql.user WHERE User = 'root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
	# Make our changes take effect
	mysql -e "FLUSH PRIVILEGES"
	# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param
# fi


# Install Rbenv and Ruby.
echo "${GREEN}${BOLD}Installing Rbenv and Ruby...${NORMAL}"
brew install rbenv
rbenv init
export PATH="$HOME/.rbenv/shims:$PATH"
source ~/.zshrc
rbenv install 2.4.0
rbenv rehash
rbenv global 2.4.0

# Install Bundler.
echo "${GREEN}${BOLD}Installing Bundler...${NORMAL}"
gem install bundler

# Install Capistrano.
echo "${GREEN}${BOLD}Installing Capistrano...${NORMAL}"
gem install capistrano -v 2.15.9

# Install NVM and Node.
echo "${GREEN}${BOLD}Installing NVM and a couple Node versions...${NORMAL}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm" [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 15.2.0
nvm install 12.0.0
nvm install 8.12.0

# Install Composer.
# See: https://tecadmin.net/install-composer-on-macos/
echo "${GREEN}${BOLD}Installing Composer...${NORMAL}"
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Install Drush.
echo "${GREEN}${BOLD}Installing Drush...${NORMAL}"
composer global require drush/drush:dev-master
# See: https://unix.stackexchange.com/questions/52131/sed-on-osx-insert-at-a-certain-line
sed -i '' -e '$a\
export PATH=$HOME/.composer/vendor/bin:$PATH' ~/.zshrc

# Restart Apache one last time.
echo "${GREEN}${BOLD}Restarting Apache...${NORMAL}"
echo $PW | sudo apachectl -k restart
brew services restart httpd

# Resource .zshrc one last time.
source ~/.zshrc

# Notify that we're done.
osascript -e 'display notification "Please review documentation to verify." with title "Local environment is ready!"';
echo "${GREEN}${BOLD}All done! Please review the documentation to verify everything was successful.${NORMAL}"
