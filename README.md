# Drupal Automatic Updater

## Usage

Copy the `update.sh` script within the templates folder to the root level of this repository, then configure it
to your site properly.

Set up a cronjob to run the script at a desired interval.

*Example Cron*
```
(/home/leadmgmt/app/Automatic-Drupal-Updater/update.sh &> /home/leadmgmt/app/Automatic-Drupal-Updater/log.log 2>&1)
```
