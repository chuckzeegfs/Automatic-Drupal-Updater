# Use this script to generate a set of keys for deployment/maintenance on staging.

# Example: ./staging-keygen.sh Annual-Meeting-Drupal

# Runs a ssh-keygen command in the following format:
# ssh-keygen -t rsa -b 4096 -N '' -C "repo-name+purpose_github-com" -f repo-name+purpose_github-com.key
if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Please supply the repository name to generate the correct key(s)."
  else
    ssh-keygen -t rsa -b 4096 -N '' -C "$1+sit_github-com" -f ~/.ssh/$1+sit_github-com.key
    ssh-keygen -t rsa -b 4096 -N '' -C "$1+maintenance_github-com" -f ~/.ssh/$1+maintenance_github-com.key

cat <<EOT >> ~/.ssh/config
Host github.com
  Hostname github.com
  IdentityFile ~/.ssh/$1+sit-deployment_github-com.key
  IdentitiesOnly yes
Host github.com-maintenance
  Hostname github.com
  IdentityFile ~/.ssh/$1+maintenance_github-com.key
  IdentitiesOnly yes
EOT
    echo ""
    echo "------------------------------------------"
    echo "FURTHER INSTRUCTIONS:"
    echo "------------------------------------------"
    echo "1. Navigate to https://github.com/gfs-maintenance/$1/settings/keys"
    echo "2. Click 'Add deploy key' at the top right"
    echo "Enter 'Maintenance' in the Title field"
    echo "4. In the 'Key' field, paste the following public key text from the generated public key file, ~/.ssh/$1+maintenance_github-com.key.pub:"
    echo ""
    cat ~/.ssh/$1+maintenance_github-com.key.pub
    echo ""
    echo "5. DO Check the 'Allow write access' checkbox"
    echo "6. Click 'Add key'"
    echo "7. The public key is now added to GitHub"
    echo "------------------------------------------"
    echo "Add the maintenance remote to your Git repository:"
    echo "git remote add maintenance git@github.com-maintenance:gfs-maintenance/$1.git"
    echo "------------------------------------------"
    echo ""

fi
