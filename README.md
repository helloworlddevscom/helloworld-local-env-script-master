<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Hello World Local Environment Script](#hello-world-local-environment-script)
- [Prerequisites](#prerequisites)
- [What this script does](#what-this-script-does)
- [Run the script](#run-the-script)
- [Additional manual steps](#additional-manual-steps)
- [Verify the script worked](#verify-the-script-worked)
- [Useful files and directories going forward](#useful-files-and-directories-going-forward)
- [Useful commands going forward](#useful-commands-going-forward)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Hello World Local Environment Script
Script to automatically set up local environment for hosting sites _without_ Lando/Docker.

WARNING: Don't try to run this if you already have a somewhat working local environment. It will probably cause more issues than it will fix.

NOTE: Most Hello World sites can be spun up using Lando/Docker these days, making this script some what useless. That said, none of what this script does should interfere with your ability to use Lando/Docker, and it may be nice to have working local installations of Apache, PHP, MySQL etc. as a fallback.

This script mostly automates this tutorial: https://getgrav.org/blog/macos-catalina-apache-multiple-php-versions


# Prerequisites
* Fresh install of MacOS >= Catalina 10.15
* Access to Hello World GitHub team. You probably already have it if you're reading this.

# What this script does
* Installs XCode Command Line Tools
* Installs [Homebrew](https://brew.sh/)
* Installs Git via Homebrew
* Installs [Oh My Zsh](https://ohmyz.sh/)
  * Sets theme to [Agnoster](https://github.com/agnoster/agnoster-zsh-theme)
* Installs Apache via Homebrew
* Configures hosts and vhosts for test.local
* Installs PHP versions 7.4, 8.1 via Homebrew
* Installs [PHP switcher script](https://gist.github.com/rhukster/f4c04f1bf59e0b74e335ee5d186a98e2)
* Installs [Xdebug toggle on/off script](https://gist.github.com/rhukster/073a2c1270ccb2c6868e7aced92001cf)
* Installs APCU and YAML packages via PECL
* Installs and configures Xdebug via PECL
* Installs MySQL via Homebrew
* Installs [Rbenv](https://github.com/rbenv/rbenv) and Ruby
* Installs [Bundler](https://bundler.io/)
* Installs [Capistrano](https://capistranorb.com/)
* Installs [NVM](https://github.com/nvm-sh/nvm) and Node
* Installs [Composer](https://getcomposer.org/)
* Installs [Drush](https://www.drush.org/latest/)

# Run the script
* Download this repo via the Code button > Download Zip (instead of cloning via `git clone`). When it finishes downloading, open and unzip it. Downloading this way allows the script to install Git for you. However, there should be no issue if you have already installed Git and you want to clone instead.
* Open Terminal.
* cd into `helloworld-local-env-script` whereever you have downloaded it. e.g. `cd ~/Downloads/helloworld-local-env-script`.
* Run `/bin/zsh local-env-script.sh` to start the script.
* The script should start. You'll be asked a few questions right away. Keep an eye on the script because it may ask you for your password multiple times throughout the process.

# Additional manual steps
After running the script, some additional steps are necessary:
* Run `ssh-keygen -t rsa` to create a new public and private SSH key.
* Run `pbcopy < ~/.ssh/id_rsa.pub` to copy your public key.
* Go to GitHub account settings and create a new SSH key by pasting.
* Run `mysql_secure_installation` to set your root user password to "root".
  * Answer the questions in this order:
    * N
    * root
    * Y
    * Y
    * Y
    * Y

# Verify the script worked
To verify the script worked follow these steps:
* Close and reopen Terminal.
* Edit Terminal preferences. Click on Profiles tab. Click on Solarized Dark and then Default.
* Close and reopen Terminal. You should see Terminal looks cooler.
  * If this didn't work, don't worry about it. It was just a bonus. If you care to dig into this further, we were attempting to enable the [Agnoster theme](https://github.com/agnoster/agnoster-zsh-theme).
  * If it did work but you don't like it, change the Terminal profile back to Basic. Edit `~/.zshrc` and set `ZSH_THEME="robbyrussel"`.
* Run `brew services list`. You should see some of the services the script installed via Homebrew running.
  * httpd may say "error". Strangely this does not seem to be an actual problem.
* Run `apachectl configtest`. You should see "Syntax OK".
* Run `which php`. You should see the path returned is `/usr/local/bin/php`.
* Run `php -v`. You should see info about the current PHP version. The current version should be 8.1.
* Run `sphp 7.4`. You should see your PHP version switch to 7.4.
* Run `xdebug off`. Run `php -v`. You should see that Xdebug is NOT mentioned in the returned info.
* Run `xdebug on`. Run `php -v`. You should see that Xdebug is mentioned in the returned info.
* Run `mysql -u root -p`. When prompted for a password enter "root". You should be allowed access to MySQL. Type `exit;` and hit enter.
* Run `nvm list`. You should see that you have a couple versions of Node installed. See https://github.com/nvm-sh/nvm for more info about NVM.
* Run `which node`. You should see the path returned contains `/.nvm/versions/node/`.
* Run `node --version`. You should see you're running one of the versions listed by `nvm list`.
* Run `cap --version`. You should see "Capistrano v2.15.9".
  * If this didn't work, don't worry about it. Capistrano is used on Metal Toad hosted projects for pulling the database. However, most of our Metal Toad hosted projects now run on Lando/Docker, where Capistrano is installed in the container for you.
* Run `composer --version`. You should see you're running >= 1.10.8.
* Run `drush --version`. You should see you're running >= 8.3.6.
  * This may not work, and that may be ok. Drush is a CLI tool for Drupal, and all our Drupal projects now run on Lando/Docker, where drush is installed in the container for you. 
* Open a browser window/tab and go to http://localhost . You should see "My User Web Root".
* Open a browser window/tab and go to http://test.local . You should see "Test Site".
  * If this doesn't work it's likely that `/etc/hosts` was not modified successfully. Open it up in a code/text editor and verify it matches the version in this repo at `/files/hosts`. If it doesn't, change it to match. Then run `sudo apachectl -k restart` to restart Apache. Try to visit the site again. 
* Open a browser window/tab and go to http://localhost/info.php . You should see info about your current PHP version.
* Open Finder. In the left pane under Favorites, click your user name.
  * Click and drag the Sites directory into the sidebar under Factorites. 
  * In the sidebar, click Sites. You should see a `test` directory. This corresponds to the localhost site you just opened. The Sites directory (`~/Sites`) will be where you should Git clone any more sites/projects you want to get running locally.
* If all of this worked, you're good to go! If not, reach out for help. :-)
* Refer back to https://helloworlddevs.atlassian.net/wiki/spaces/HWD/pages/4065814/Onboarding for next steps.

# Useful files and directories going forward
@TODO useful directories

# Useful commands going forward
@TODO useful commands
