#!/bin/bash
source $HOME/.bash_profile

################################################
# Drupal Automatic Updater + Pull Request Script
# 
# This script will run automatic updates via Drush or composer on a Drupal site,
# and then automatically open a pull request on the remote Github repository used
# for the site.
#
# Also includes the functionality to sync a prod db/filesystem to the current
# installation prior to running updates.
# 
# Requirements:
#  - Properly configured Drush alias for this site and production site.
#      Your should be able to run "@drush <alias> status" and get a normal status.
#  - The 'hub' tool: https://github.com/github/hub, which requires 
#      Go on the server to install.
#      Installing Go: https://golang.org/doc/install#install
#  - The GIT_TOKEN environment variable must be defined in .bash_profile.
#      Example: export GITHUB_TOKEN=<token>
#
# Pausing:
#   Place a file named 'pause' next to this script to make it stop executing. This
#   lets you have it on a cron job without editing the cron task.
#
###############################################

# ENTER SETTINGS BELOW

# The name of the environment this is being run in. Only used for display purposes.
ENVIRONMENT='staging'

# The URL of the environment, inserted into the pull request.
ENVIRONMENT_URL='https://example.com/'

# Site's docroot.
# Example:
# DRUPAL_ROOT='/home/leadmgmt/app/leadmanagement/public_html'
DRUPAL_ROOT='/path/to/drupal'

# Drush alias for this site.
# Example:
# ALIAS='@leads.test'
DRUSH_ALIAS='@none'

# Drush alias for the production site. If provided and SYNC_PROC is 1,
# the production site database and files will be synced after switching to the
# correct branch.
DRUSH_ALIAS_PROD='@none'

# Whether or not to sync the production files and DB prior to update.
# Requires a working production Drush alias from this location.
SYNC_PROD=1

# If you want to keep htaccess after a core upgrade, set to 1
KEEP_HTACCESS=1

# If you want to keep the robots.txt after a core upgrade, set to 1
KEEP_ROBOTS=1

# Remote git branch that is checked out on this server.
GIT_REMOTE_BRANCH='master'

# Remote git name that is pulled and pushed to.
GIT_REMOTE_NAME='origin'

# What branch should the PR be opened against? This defined the 'base' option
# of the hub pull-request command.
GIT_PULL_REQUEST_AGAINST='master'

# Drupal version being updated.
DRUPAL_VERSION=7

# If a site is Drupal 8, it could be managed by Drush as well.
# Otherwise, it is managed with composer and has a different upgrade command.
# This should always be 1 on a Drupal 7 site.
DRUSH_MANAGED=1

# If a site is composer managed, it might have a different docroot where composer.json
# is located.
# Example:
# DRUPAL_ROOT='/home/leadmgmt/app/leadmanagement'
COMPOSER_ROOT=''

# NO NEED TO EDIT BELOW THIS LINE
###################################

# The directory this script is in.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd );

# The info for the Git user we are working as.
MAINTENANCE_NAME="Maintenance User"
MAINTENANCE_EMAIL="martech+maintenance@gfs.com"

# Date format
DATE=`date +"%m/%d/%Y_%I-%M%P"`

# Nice format date to use in areas where English is nice.
FORMATTED_DATE=`date +"%m/%d/%Y at %I:%M%P"`

# The commit message file to build, which usually sits beside the script.
COMMIT_MESSAGE_LOCATION="${DIR}/update-message.md"

# Adds pause functionality for this script by having a 'pause' file in the same directory.
if [ -f "${DIR}/pause" ]; then
	echo 'Drupal update script is paused! Remove/rename the "pause" file beside the script to unpause.'
	exit;
fi

# Go to the site directory
cd $DRUPAL_ROOT

# Make sure this script is acting as the maintenance user.
git config --global user.name $MAINTENANCE_NAME
git config --global user.email $MAINTENANCE_EMAIL
git checkout $GIT_REMOTE_BRANCH
git pull $GIT_REMOTE_NAME $GIT_REMOTE_BRANCH

# Sync the prod database and files.
if [ $SYNC_PROD = 1 ]; then
    echo "Syncing '$DRUSH_ALIAS' from '$DRUSH_ALIAS_PROD'..."
    drush $DRUSH_ALIAS sql-drop -y
    drush sql-sync $DRUSH_ALIAS_PROD $DRUSH_ALIAS -y
    echo "Syncing '$DRUSH_ALIAS' files with '$DRUSH_ALIAS_PROD' via rsync..."
    drush -y rsync $DRUSH_ALIAS_PROD:%files/ $DRUSH_ALIAS:%files
fi

# Clear all the cache
# Drush is applicable for both D8 and D7 even when managed with composer.
if [ $DRUPAL_VERSION = 7 ]; then
	drush $DRUSH_ALIAS cc all
fi

if [ $DRUPAL_VERSION = 8 ]; then
	drush $DRUSH_ALIAS cr
fi

# Update the site with drush or composer.
echo '```\n' &> ${COMMIT_MESSAGE_LOCATION}
if [ $DRUSH_MANAGED = 1 ]; then
	(drush $DRUSH_ALIAS -y up) >> ${COMMIT_MESSAGE_LOCATION}
else
	cd $COMPOSER_ROOT
	# There doesn't seem to be a way to output composer text to the file reliably.
	composer update
	cd $DRUPAL_ROOT
	(drush $DRUSH_ALIAS -y updb) >> ${COMMIT_MESSAGE_LOCATION} 2>&1
fi
echo '\n```' >> ${COMMIT_MESSAGE_LOCATION}

# If the update command actually changed anything, we need to perform the commits
# and do the pull request.
if ! git diff-index --quiet HEAD --; then
	# Remove files if Drupal core was updated.
	if [ $DRUPAL_VERSION = 7 ]; then
		rm -f CHANGELOG.txt
		rm -f COPYRIGHT.txt
		rm -f INSTALL.mysql.txt
		rm -f INSTALL.pgsql.txt
		rm -f INSTALL.sqlite.txt
		rm -f INSTALL.txt
    rm -f LICENSE.txt
		rm -f MAINTAINERS.txt
		rm -f README.txt
		rm -f UPGRADE.txt
	fi

	if [ $DRUPAL_VERSION = 8 ]; then
		rm -f README.txt
		rm -f LICENSE.txt
		rm -f core/UPDATE.txt
		rm -f core/MAINTAINERS.txt
		rm -f core/LICENSE.txt
		rm -f core/INSTALL.txt
		rm -f core/INSTALL.sqlite.txt
		rm -f core/INSTALL.pgsql.txt
		rm -f core/INSTALL.mysql.txt
		rm -f core/COPYRIGHT.txt
		rm -f core/CHANGELOG.txt
	fi

	if [ $KEEP_ROBOTS = 1 ]; then
		git checkout 'robots.txt'
	else
		rm -f robots.txt
	fi

	if [ $KEEP_HTACCESS = 1 ]; then
		git checkout '.htaccess'
	fi

	git checkout -B "${DATE}-updates"
	git add .
	git commit -am "Installed updates automatically for ${FORMATTED_DATE}"
	git push $GIT_REMOTE_NAME "${DATE}-updates"
	echo -e "Drupal Updates for ${FORMATTED_DATE}\n\nThese updates were automatically installed with the Automatic Drupal Updater script in the **${ENVIRONMENT}** environment at ${ENVIRONMENT_URL}. Please review the changes before merging.\n\nOnce merged, you will need to deploy the main branch to the production environment. It is recommended to run updb and cache clear with Drush when deploying.\n\n$(cat ${COMMIT_MESSAGE_LOCATION})" > ${COMMIT_MESSAGE_LOCATION}
	hub pull-request -F ${COMMIT_MESSAGE_LOCATION} -b ${GIT_PULL_REQUEST_AGAINST} "${DATE}-updates"
fi
