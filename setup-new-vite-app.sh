#!/bin/bash

# Set up variables
SERVER="root.fcc.lol"
USER="fcc"
ADMIN_CONTACT="studio@fcc.lol"
APPS_DIRECTORY="/home/$USER/vite-apps"
DEFAULT_DOMAIN_FOR_SUBDOMAINS="fcc.lol"

# Set up formatting for use later
BOLD='\e[1m'
BOLD_RED='\e[1;31m'
BOLD_GREEN='\e[1;32m'
END_COLOR='\e[0m' # This ends formatting

# Function to convert app name to hyphenated app ID
generate_app_id() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

# Prompt for the app name and generate the default app ID
read -p "App Name (Title Case): " APP_NAME
DEFAULT_APP_ID=$(generate_app_id "$APP_NAME")

# Prompt for the app ID with the default value
read -p "App ID (Default: "${DEFAULT_APP_ID}"): " APP_ID
APP_ID=${APP_ID:-$DEFAULT_APP_ID}

# Prompt for the domain name with the default value
DEFAULT_DOMAIN_NAME="$APP_ID.$DEFAULT_DOMAIN_FOR_SUBDOMAINS"
read -p "URL (Default: "${DEFAULT_DOMAIN_NAME}"): " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-$DEFAULT_DOMAIN_NAME}

echo " "

# Display the collected information
echo "App Name: $APP_NAME"
echo "App ID: $APP_ID"
echo "URL: https://$DOMAIN_NAME"

echo " "

# Prompt for sudo password
read -s -p "Enter sudo password: " SUDO_PASSWORD
echo

# Function to keep sudo session alive
keep_sudo_alive() {
    while true; do
        echo "$SUDO_PASSWORD" | sudo -S -v > /dev/null 2>&1
        sleep 60
    done
}

echo " "

# Initial check to see if the provided password is correct
if ! echo "$SUDO_PASSWORD" | sudo -kS echo > /dev/null 2>&1; then
    echo -e "${BOLD_RED}FAILED${END_COLOR} Password incorrect"
    echo " "
    exit 1
fi

# Start the keep-alive function in the background
keep_sudo_alive &
SUDO_KEEP_ALIVE_PID=$!

# Make sure to kill the keep-alive process on exit
trap 'kill $SUDO_KEEP_ALIVE_PID' EXIT

echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Password correct"

# Create root directory for app
if sudo mkdir $APPS_DIRECTORY/$APP_ID; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created root directory at $APPS_DIRECTORY/$APP_ID"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create root directory at $APPS_DIRECTORY/$APP_ID"
fi

# Create src directory for app
if sudo mkdir $APPS_DIRECTORY/$APP_ID/src; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created src directory at $APPS_DIRECTORY/$APP_ID/src"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create src directory at $APPS_DIRECTORY/$APP_ID/src"
fi

# Create public directory for app
if sudo mkdir $APPS_DIRECTORY/$APP_ID/public; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created public directory at $APPS_DIRECTORY/$APP_ID/public"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create public directory at $APPS_DIRECTORY/$APP_ID/public"
fi

# Create a basic src/main.jsx file
sudo touch $APPS_DIRECTORY/$APP_ID/src/main.jsx
if echo "import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
" | sudo tee $APPS_DIRECTORY/$APP_ID/src/main.jsx > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic src/main.jsx file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic src/main.jsx file"
fi

# Create a basic src/App.jsx file
sudo touch $APPS_DIRECTORY/$APP_ID/src/App.jsx
if echo "import { useState } from 'react'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className=\"App\">
      <h1>$APP_NAME</h1>
      <div className=\"card\">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.jsx</code> and save to test HMR
        </p>
      </div>
      <p className=\"read-the-docs\">
        Click on the Vite and React logos to learn more
      </p>
    </div>
  )
}

export default App
" | sudo tee $APPS_DIRECTORY/$APP_ID/src/App.jsx > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic src/App.jsx file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic src/App.jsx file"
fi

