# Sets up Favorite Apps in Dash - Run after installed apps

echo "Configuring GNOME dash favorites..."

# Set favorite apps in the dash (only Ghostty and Brave)
# Note: Desktop file names may vary depending on installation method
gsettings set org.gnome.shell favorite-apps "['com.mitchellh.ghostty.desktop', 'brave-browser.desktop']"

echo "Dash favorites configured: Ghostty and Brave"
