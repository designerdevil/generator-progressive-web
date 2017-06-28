#!/bin/bash
set -o pipefail

MYDIR=$(pwd)
# SCAFFOLD_VERSION_OR_BRANCH="master"
SCAFFOLD_VERSION_OR_BRANCH="temp-debrand-automation"
SCAFFOLD_URL="https://github.com/mobify/platform-scaffold/archive/$SCAFFOLD_VERSION_OR_BRANCH.zip"

# Prompt license and do not proceed unless user has accepted
read -p"--> We have a license you must read and agree to. Read license? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    exit 1
fi

curl -s -O -L https://raw.githubusercontent.com/mobify/platform-scaffold/master/LICENSE
trap 'rm -f LICENSE' EXIT
less LICENSE

read -p"--> I have read, understand, and accept the terms and conditions stated in the license above. (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    exit 1
fi

# Get the project slug from the user
read -p'--> What is your project slug? (should match slug on Mobify Cloud) ' project_slug

# Get the project url from the user
read -p'--> What is the project url? ' project_url

# Get the site name from the user
read -p'--> What is the project name? ' project_name

# Prepare new project directory
project_dir="$MYDIR/$project_slug"
echo "Setting up new project in $project_dir"
mkdir "$project_dir"
cd "$project_dir" || exit

printf "\nDownloading Progressive Web project scaffold\n"
WORKING_DIR=$(mktemp -d /tmp/platform-scaffold.XXXXX)
trap 'rm -rf "$WORKING_DIR"' EXIT
curl --progress-bar -L "$SCAFFOLD_URL" -o "$WORKING_DIR/platform-scaffold-$SCAFFOLD_VERSION_OR_BRANCH.zip"
cd "$WORKING_DIR" || exit
unzip -q "$WORKING_DIR/platform-scaffold-$SCAFFOLD_VERSION_OR_BRANCH.zip"
cp -R $WORKING_DIR/platform-scaffold-$SCAFFOLD_VERSION_OR_BRANCH/. "$project_dir"
cd "$project_dir" || exit

# Remove files that are specific to the scaffold but not to projects
rm CONTRIBUTING.md ROADMAP.md web/DEVELOPING.md web/CHANGELOG.md

# To replace title in header-title
sed -i -e "s/Merlin's Potions/$project_name/g" web/app/containers/header/partials/header-title.jsx
# To replace start_url in the manifest.json
sed -i -e "s/https:\/\/www.merlinspotions.com\//$project_url/g" web/app/static/manifest.json
# To replace name in the manifest.json
sed -i -e "s/Merlin's Potions/$project_name/g" web/app/static/manifest.json
# To replace short_name in the manifest.json
sed -i -e "s/Merlin's/$project_name/g" web/app/static/manifest.json
# To replace variable values in _variable.scss with their respective ui_kit_value
sed -i '' -e "s/\:.*ui_kit_value//g" web/app/styles/_variables.scss

# This is about the web
cd web || exit

# Replace "progressive-web-scaffold" with $project_slug inside of files.
egrep -lR "progressive-web-scaffold" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/progressive-web-scaffold/$project_slug/g" 2>/dev/null

# Set site url
egrep -lR "siteUrl" . | tr '\n' '\0' | xargs -0 -n1 sed -i '' "s/\"siteUrl\": \"\"/\"siteUrl\": \"$project_url\"/g" 2>/dev/null

printf "\nInstalling project dependencies\n"
npm install

# Make first commit
cd "$project_dir" || exit
git init
git add .
git commit -am 'Your first Progressive Web commit - Congrats! 🌟 👍🏽'

echo "Your project is now ready to go."
echo "Follow the steps in README.md to run the app."
echo "You must still set up a remote for Git: https://help.github.com/articles/adding-a-remote/"
