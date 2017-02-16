# Use this script to generate a set of keys for deployment/maintenance on staging.

# Example: ./staging-keygen.sh Annual-Meeting-Drupal

# Runs a ssh-keygen command in the following format:
# ssh-keygen -t rsa -b 4096 -N '' -C "repo-name+purpose_github-com" -f repo-name+purpose_github-com.key
if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Please supply the repository name to generate the correct key(s)."
  else
    ssh-keygen -t rsa -b 4096 -N '' -C "~/.ssh/$1+sit_github-com" -f ~/.ssh/$1+sit_github-com.key
    ssh-keygen -t rsa -b 4096 -N '' -C "~/.ssh/$1+maintenance_github-com" -f ~/.ssh/$1+maintenance_github-com.key
fi
