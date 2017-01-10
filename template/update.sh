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
SYNC_PROD=0

# If you want to keep htaccess after a core upgrade, set to 1
KEEP_HTACCESS=1

# If you want to keep the robots.txt after a core upgrade, set to 1
KEEP_ROBOTS=1

# Remote git branch that is checked out on this server.
GIT_REMOTE_BRANCH='master'

# Remote git name that is pulled and pushed to.
GIT_REMOTE_NAME='origin'

# Drupal version being updated.
DRUPAL_VERSION=7

# If a site is Drupal 8, it could be managed by Drush as well.
# Otherwise, it is managed with composer and has a different upgrade command.
# This should always be 1 on a Drupal 7 site.
DRUSH_MANAGED=1

# If a site is composer managed, it might havea  different docroot where composer.json
# is located.
COMPOSER_ROOT=''

# What branch on the origin should the PR be opened against? 
# This defined the 'base' option of the hub pull-request command.
GIT_PULL_REQUEST_AGAINST='master'

# Remote git name that is pulled and pushed to.
# The repo on this server should have a remote named this.
GIT_REMOTE_FORK_NAME='maintenance'

# The remote repository name, used when opening pull requests.
GIT_REMOTE_REPO_NAME='Git-Project'


# NO NEED TO EDIT BELOW THIS LINE
###################################

. ./inc/script.sh
