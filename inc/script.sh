# THESE ARE THE GUTS OF THE AUTOMATIC UPDATER
# THIS FILE IS VERSION CONTROLLED.
###################################

# Date format
DATE=`date +"%m/%d/%Y_%I-%M%P"`

# What branch on the origin should the PR be opened against? 
# This defined the 'base' option of the hub pull-request command.
GIT_PULL_REQUEST_HEAD="gfs-maintenance/${GIT_REMOTE_REPO_NAME}:${DATE}-updates"

# The info for the Git user we are working as.
MAINTENANCE_NAME="Maintenance User"
MAINTENANCE_EMAIL="martech+maintenance@gfs.com"

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

  git checkout '.gitignore'

  git checkout -B "${DATE}-updates"
  git add .
  git commit -am "Installed updates automatically for ${FORMATTED_DATE}"
  git push $GIT_REMOTE_FORK_NAME "${DATE}-updates"
  echo -e "Drupal Updates for ${FORMATTED_DATE}\n\nThese updates were automatically installed with the Automatic Drupal Updater script in the **${ENVIRONMENT}** environment at ${ENVIRONMENT_URL}. Please review the changes before merging.\n\nOnce merged, you will need to deploy the main branch to the production environment. It is recommended to run updb and cache clear with Drush when deploying.\n\n$(cat ${COMMIT_MESSAGE_LOCATION})" > ${COMMIT_MESSAGE_LOCATION}
  echo "${GIT_PULL_REQUEST_HEAD}"
  hub pull-request -F ${COMMIT_MESSAGE_LOCATION} -b ${GIT_PULL_REQUEST_AGAINST} -h "${GIT_PULL_REQUEST_HEAD}" "${DATE}-updates"

  # Clear all the cache
  # Drush is applicable for both D8 and D7 even when managed with composer.
  if [ $DRUPAL_VERSION = 7 ]; then
    drush $DRUSH_ALIAS cc all
  fi

  if [ $DRUPAL_VERSION = 8 ]; then
    drush $DRUSH_ALIAS cr
  fi

fi
