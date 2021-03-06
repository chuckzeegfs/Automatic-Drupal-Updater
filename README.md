# Drupal Automatic Updater

This script will run automatic updates via Drush or composer on a Drupal site, and then automatically open a pull request on the remote Github repository used for the site.

## Usage

Copy the `update.sh` script within the templates folder to the root level of this repository, then configure it
to your site properly.

Set up a cronjob to run the script at a desired interval.

*Example Cron*
```
(/home/leadmgmt/app/Automatic-Drupal-Updater/update.sh &> /home/leadmgmt/app/Automatic-Drupal-Updater/log.log 2>&1)
```

*Cron Setup*
The best way to inherit the normal interactive shell's PATH settings so drush doesn't fail is to run `env` in a terminal and copy the "PATH=" line. When using `crontab -e`, place the entire line above the cronjob.

## Requirements

- Properly configured Drush alias
- The 'hub' tool: https://github.com/github/hub, which requires Go on the server to install. Installing Go: https://golang.org/doc/install#install
- The GIT_TOKEN environment variable must be defined in .bash_profile. Example: `export GITHUB_TOKEN=<token>`
- The environment you run the script on must have a write level Github deploy key for the repository. See https://confluence.gfs.com/confluence/display/CORPISMARTECH/Connecting+to+source+control for instructions on setting up the keys.

## Helpers

Use the `helpers/staging-keygen.sh` file on the staging environment to generate an appropriate key for the maintenance and deployment tasks. Example: `./staging-keygen.sh My-Repo-Name`

## Pausing

Place a file named 'pause' next to this script to make it stop executing. This lets you have it on a cron job without editing the cron task.

## Notes

- the `hub` tool's `pull-request` command only operates on the `origin` remote, thus if you're using something like `upstream` you might run into some problems.