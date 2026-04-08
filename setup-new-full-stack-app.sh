#!/bin/bash

# Set up variables
SERVER="root.fcc.lol"
USER="fcc"
ADMIN_CONTACT="studio@fcc.lol"
APPS_DIRECTORY="/home/$USER/full-stack-apps"
DEFAULT_DOMAIN_FOR_SUBDOMAINS="fcc.lol"
GITHUB_USER="artemiszephyrfcc"

# Set up formatting for use later
BOLD='\e[1m'
BOLD_RED='\e[1;31m'
BOLD_GREEN='\e[1;32m'
END_COLOR='\e[0m' # This ends formatting

# Function to convert app name to hyphenated app ID
generate_app_id() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

# Parse CLI arguments
CLI_NAME="" CLI_ID="" CLI_DOMAIN="" CLI_ANTHROPIC="" CLI_ANTHROPIC_KEY="" CLI_PRIVATE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --name) CLI_NAME="$2"; shift 2 ;;
    --id) CLI_ID="$2"; shift 2 ;;
    --domain) CLI_DOMAIN="$2"; shift 2 ;;
    --anthropic) CLI_ANTHROPIC="true"; shift ;;
    --anthropic-key) CLI_ANTHROPIC="true"; CLI_ANTHROPIC_KEY="$2"; shift 2 ;;
    --private) CLI_PRIVATE="true"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# App Name: use CLI arg or prompt
if [ -n "$CLI_NAME" ]; then
  APP_NAME="$CLI_NAME"
else
  read -p "App Name (Title Case): " APP_NAME
fi

# App ID: use CLI arg, auto-derive if name was given via CLI, or prompt
if [ -n "$CLI_ID" ]; then
  APP_ID="$CLI_ID"
else
  DEFAULT_APP_ID=$(generate_app_id "$APP_NAME")
  if [ -n "$CLI_NAME" ]; then
    APP_ID="$DEFAULT_APP_ID"
  else
    read -p "App ID (Default: "${DEFAULT_APP_ID}"): " APP_ID
    APP_ID=${APP_ID:-$DEFAULT_APP_ID}
  fi
fi

# Domain: use CLI arg, auto-derive if any CLI args were given, or prompt
if [ -n "$CLI_DOMAIN" ]; then
  DOMAIN_NAME="$CLI_DOMAIN"
else
  DEFAULT_DOMAIN_NAME="$APP_ID.$DEFAULT_DOMAIN_FOR_SUBDOMAINS"
  if [ -n "$CLI_NAME" ] || [ -n "$CLI_ID" ]; then
    DOMAIN_NAME="$DEFAULT_DOMAIN_NAME"
  else
    read -p "URL (Default: "${DEFAULT_DOMAIN_NAME}"): " DOMAIN_NAME
    DOMAIN_NAME=${DOMAIN_NAME:-$DEFAULT_DOMAIN_NAME}
  fi
fi

# Anthropic API: use CLI flag or prompt
if [ -n "$CLI_ANTHROPIC" ]; then
  ENABLE_ANTHROPIC="true"
else
  if [ -n "$CLI_NAME" ] || [ -n "$CLI_ID" ]; then
    ENABLE_ANTHROPIC="false"
  else
    read -p "Enable Anthropic API access? (y/n): " ANTHROPIC_ANSWER
    if [[ "$ANTHROPIC_ANSWER" =~ ^[Yy] ]]; then
      ENABLE_ANTHROPIC="true"
    else
      ENABLE_ANTHROPIC="false"
    fi
  fi
fi

# Anthropic API key: use CLI arg > env var > interactive prompt
ANTHROPIC_KEY=""
if [ "$ENABLE_ANTHROPIC" = "true" ]; then
  if [ -n "$CLI_ANTHROPIC_KEY" ]; then
    ANTHROPIC_KEY="$CLI_ANTHROPIC_KEY"
  elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    ANTHROPIC_KEY="$ANTHROPIC_API_KEY"
  else
    read -s -p "Enter Anthropic API key: " ANTHROPIC_KEY
    echo
  fi
fi

# GitHub repo visibility: use CLI flag or prompt
if [ -n "$CLI_PRIVATE" ]; then
  GITHUB_PRIVATE="true"
else
  if [ -n "$CLI_NAME" ] || [ -n "$CLI_ID" ]; then
    GITHUB_PRIVATE="false"
  else
    read -p "Make GitHub repo private? (y/n, Default: n): " PRIVATE_ANSWER
    if [[ "$PRIVATE_ANSWER" =~ ^[Yy] ]]; then
      GITHUB_PRIVATE="true"
    else
      GITHUB_PRIVATE="false"
    fi
  fi
fi

echo " "

# Display the collected information
echo "App Name: $APP_NAME"
echo "App ID: $APP_ID"
echo "URL: https://$DOMAIN_NAME"

# Find an available port
find_available_port() {
    local port=3100  # Start with a default port
    while netstat -tna | grep -q :$port; do
        port=$((port+1))
    done
    echo $port
}

PORT=$(find_available_port)
echo "Host: localhost:$PORT"

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
if echo "$SUDO_PASSWORD" | sudo -S mkdir -p "$APPS_DIRECTORY/$APP_ID"; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created root directory at $APPS_DIRECTORY/$APP_ID"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create root directory at $APPS_DIRECTORY/$APP_ID"
fi

# Change permissions for app directory to specified user
if echo "$SUDO_PASSWORD" | sudo -S chown -R "$USER" "$APPS_DIRECTORY/$APP_ID"; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Changed permissions to $USER"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot change permissions to $USER"
fi

# Create src directory for app
if sudo mkdir $APPS_DIRECTORY/$APP_ID/src; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created src directory at $APPS_DIRECTORY/$APP_ID/src"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create src directory at $APPS_DIRECTORY/$APP_ID/src"
fi

# Create .prettierrc file
sudo touch $APPS_DIRECTORY/$APP_ID/.prettierrc
if echo '{
  "bracketSameLine": true,
  "trailingComma": "all",
  "singleQuote": true
}
' | sudo tee $APPS_DIRECTORY/$APP_ID/.prettierrc > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created .prettierrc file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create .prettierrc file"
fi

# Create server.js
sudo touch $APPS_DIRECTORY/$APP_ID/server.js
SERVER_JS_EXTRA_IMPORTS=""
SERVER_JS_EXTRA_INIT=""
if [ "$ENABLE_ANTHROPIC" = "true" ]; then
  SERVER_JS_EXTRA_IMPORTS='import '"'"'dotenv/config'"'"';
import Anthropic from "@anthropic-ai/sdk";
'
  SERVER_JS_EXTRA_INIT='
const anthropic = new Anthropic();
'
fi
if echo "${SERVER_JS_EXTRA_IMPORTS}"'import express from "express";
import Database from "better-sqlite3";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const port = '"$PORT"';'"${SERVER_JS_EXTRA_INIT}"'

// SQLite setup
const db = new Database(join(__dirname, "data.sqlite"));
db.pragma("journal_mode = WAL");

app.use(express.json());

// Serve static files from dist
app.use(express.static(join(__dirname, "dist")));

// API endpoint for SQLite queries
app.post("/api/query", (req, res) => {
  try {
    const { sql, params = [] } = req.body;
    const stmt = db.prepare(sql);
    if (stmt.reader) {
      const rows = stmt.all(...params);
      res.json({ rows });
    } else {
      const result = stmt.run(...params);
      res.json({ result });
    }
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// SPA fallback
app.get("*", (req, res) => {
  res.sendFile(join(__dirname, "dist", "index.html"));
});

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});
' | sudo tee $APPS_DIRECTORY/$APP_ID/server.js > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created server.js file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create server.js file"
fi

# Create .env file if Anthropic is enabled
if [ "$ENABLE_ANTHROPIC" = "true" ]; then
    sudo touch $APPS_DIRECTORY/$APP_ID/.env
    if echo "ANTHROPIC_API_KEY=$ANTHROPIC_KEY" | sudo tee $APPS_DIRECTORY/$APP_ID/.env > /dev/null; then
        echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created .env file with Anthropic API key"
    else
        echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create .env file"
    fi
fi

# Create a basic src/App.jsx file
sudo touch $APPS_DIRECTORY/$APP_ID/src/App.jsx
if echo "import React from \"react\";
import styled from \"styled-components\";

const Page = styled.div\`
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  font-size: 24px;
  color: #333;
\`;

function App() {
  return <Page>Hello from $APP_NAME!</Page>;
}

export default App;
" | sudo tee $APPS_DIRECTORY/$APP_ID/src/App.jsx > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic src/App.jsx file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic src/App.jsx file"
fi

# Create a basic src/index.css
sudo touch $APPS_DIRECTORY/$APP_ID/src/index.css
if echo "body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", \"Roboto\", \"Oxygen\",
    \"Ubuntu\", \"Cantarell\", \"Fira Sans\", \"Droid Sans\", \"Helvetica Neue\",
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, \"Courier New\",
    monospace;
}
" | sudo tee $APPS_DIRECTORY/$APP_ID/src/index.css > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic src/index.css file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic src/index.css file"
fi

# Create a basic src/main.jsx
sudo touch $APPS_DIRECTORY/$APP_ID/src/main.jsx
if echo "import React from \"react\";
import ReactDOM from \"react-dom/client\";
import \"./index.css\";
import App from \"./App.jsx\";

ReactDOM.createRoot(document.getElementById(\"root\")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
" | sudo tee $APPS_DIRECTORY/$APP_ID/src/main.jsx > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic src/main.jsx file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic src/main.jsx file"
fi

# Create a basic index.html
sudo touch $APPS_DIRECTORY/$APP_ID/index.html
if echo "<!DOCTYPE html>
<html lang=\"en\">
  <head>
    <meta charset=\"UTF-8\" />
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
    <title>$APP_NAME</title>
  </head>
  <body>
    <div id=\"root\"></div>
    <script type=\"module\" src=\"/src/main.jsx\"></script>
  </body>
</html>
" | sudo tee $APPS_DIRECTORY/$APP_ID/index.html > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic index.html file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic index.html file"
fi

# Create vite.config.js
sudo touch $APPS_DIRECTORY/$APP_ID/vite.config.js
if echo "import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
});
" | sudo tee $APPS_DIRECTORY/$APP_ID/vite.config.js > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created vite.config.js file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create vite.config.js file"
fi

# Create basic package.json file
ANTHROPIC_DEPS=""
if [ "$ENABLE_ANTHROPIC" = "true" ]; then
  ANTHROPIC_DEPS='
    "@anthropic-ai/sdk": "^0.39.0",
    "dotenv": "^16.4.7",'
fi
sudo touch $APPS_DIRECTORY/$APP_ID/package.json
if echo "{
  \"name\": \"$APP_ID\",
  \"version\": \"0.1.0\",
  \"private\": true,
  \"type\": \"module\",
  \"scripts\": {
    \"dev\": \"vite\",
    \"build\": \"vite build\",
    \"preview\": \"vite preview\",
    \"start\": \"node server.js\"
  },
  \"dependencies\": {$ANTHROPIC_DEPS
    \"react\": \"^18.3.1\",
    \"react-dom\": \"^18.3.1\",
    \"styled-components\": \"^6.1.11\",
    \"express\": \"^4.19.2\",
    \"better-sqlite3\": \"^11.0.0\"
  },
  \"devDependencies\": {
    \"@vitejs/plugin-react\": \"^4.3.4\",
    \"vite\": \"^6.0.0\"
  }
}
" | sudo tee $APPS_DIRECTORY/$APP_ID/package.json > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic package.json file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic package.json file"
fi

# Create a basic README.md
sudo touch $APPS_DIRECTORY/$APP_ID/README.md
if echo "# $APP_NAME

Identifier: $APP_ID

Created: $(date)" | sudo tee $APPS_DIRECTORY/$APP_ID/README.md > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic README.md file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic README.md file"
fi

# Create a setup-log.json
sudo touch $APPS_DIRECTORY/$APP_ID/setup-log.json
if echo "{
  \"app_id\": \"$APP_ID\",
  \"app_name\": \"$APP_NAME\",
  \"domain\": \"https://$DOMAIN_NAME\",
  \"host\": \"localhost\",
  \"port\": \"$PORT\",
  \"author\": \"$USER\",
  \"anthropic\": $ENABLE_ANTHROPIC,
  \"created_on\": \"$(date)\"
}" | sudo tee $APPS_DIRECTORY/$APP_ID/setup-log.json > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created setup-log.json file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create setup-log.json file"
fi

# Create basic gitignore file
sudo touch $APPS_DIRECTORY/$APP_ID/.gitignore
if echo 'node_modules/
dist/
.env
*.sqlite
.DS_Store
' | sudo tee $APPS_DIRECTORY/$APP_ID/.gitignore > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created basic gitignore file"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create basic gitignore file"
fi

# Change permissions for app directory to specified user
if sudo chown -R $USER $APPS_DIRECTORY/$APP_ID; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Changed permissions to set $USER as owner"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot change permissions to set $USER as owner"
fi

# Install node modules
if cd $APPS_DIRECTORY/$APP_ID && npm install --no-save; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Installed node modules"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot install node modules"
fi

# Build app for production
if cd $APPS_DIRECTORY/$APP_ID && npm run build; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Built app for production"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot build app for production"
fi

# Start node process via PM2
if cd "$APPS_DIRECTORY/$APP_ID" && pm2 start --name "$APP_ID" server.js && pm2 save; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Started $APP_ID via PM2"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot start $APP_ID via PM2"
fi

# Create a VirtualHost config file that proxies requests to node
sudo touch /etc/apache2/sites-available/$DOMAIN_NAME.conf
if echo "<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME
    ServerAdmin $ADMIN_CONTACT

    # Redirect HTTP to HTTPS
    Redirect permanent / https://$DOMAIN_NAME/

    ErrorLog /var/log/apache2/$DOMAIN_NAME-error.log
    CustomLog /var/log/apache2/$DOMAIN_NAME-access.log combined
</VirtualHost>

<VirtualHost *:443>
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME
    ServerAdmin $ADMIN_CONTACT

    # SSL Configuration using Cloudflare Origin CA
    SSLEngine on
    SSLCertificateFile /etc/ssl/cloudflare/fcc.lol.pem
    SSLCertificateKeyFile /etc/ssl/cloudflare/fcc.lol.key

    # SSL Security Settings
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!aNULL:!MD5:!DSS
    SSLHonorCipherOrder on

    # Proxy Configuration
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyVia Full
    <Proxy *>
        Require all granted
    </Proxy>

    ProxyPass / http://127.0.0.1:$PORT/
    ProxyPassReverse / http://127.0.0.1:$PORT/

    ErrorLog /var/log/apache2/$DOMAIN_NAME-ssl-error.log
    CustomLog /var/log/apache2/$DOMAIN_NAME-ssl-access.log combined
</VirtualHost>" | sudo tee /etc/apache2/sites-available/$DOMAIN_NAME.conf > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created Apache config file at /etc/apache2/sites-available/$DOMAIN_NAME.conf"

    # Enable SSL module if not already enabled
    sudo a2enmod ssl
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Enabled SSL module"

else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create Apache config file at /etc/apache2/sites-available/$DOMAIN_NAME.conf"
fi

# Enable site in Apache
if sudo a2ensite $DOMAIN_NAME > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Enabled site in Apache"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot enable site in Apache"
fi

# Reload Apache
if sudo service apache2 reload; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Reloaded Apache"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot reload Apache"
fi

# Initialize Git repository
if cd $APPS_DIRECTORY/$APP_ID && \
    git init && \
    git checkout -b main && \
    git config receive.denyCurrentBranch updateInstead > /dev/null 2>&1; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created git repository"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create git repository"
fi

# Commit basic code
if git add . && git commit -m "Adding basic template" > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Committed initial code to repository"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot commit initial code to repository"
fi

# Change permissions for all files in app directory to specified user
if sudo chown -R $USER $APPS_DIRECTORY/$APP_ID; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Changed permissions to set $USER as owner"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot change permissions to set $USER as owner"
fi

# Set up a hook that deploys any commits made to this repo
sudo touch $APPS_DIRECTORY/$APP_ID/.git/hooks/post-receive
sudo chmod +x $APPS_DIRECTORY/$APP_ID/.git/hooks/post-receive
sudo chown $USER $APPS_DIRECTORY/$APP_ID/.git/hooks/post-receive

if echo '#!/bin/bash

cd '"$APPS_DIRECTORY/$APP_ID"' || { echo "Failed to change directory"; exit 1; }

echo "Installing dependencies"
npm install --no-save || { echo "npm install failed"; exit 1; }

echo "Building app for production"
npm run build || { echo "Build failed"; exit 1; }

echo "Restarting via PM2"
if pm2 restart '"$APP_ID"'; then
    pm2 save >/dev/null 2>&1
    echo -e "\e[1;32mSUCCESS\e[0m Deployed '"$APP_ID"'"
else
    echo "Failed to restart process with pm2"
    exit 1
fi' | sudo tee $APPS_DIRECTORY/$APP_ID/.git/hooks/post-receive > /dev/null; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created post-receive hook"
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create post-receive hook"
fi

# Set up GitHub repository
DEPLOY_KEY_PATH="${GITHUB_DEPLOY_KEY_PATH:-$HOME/.ssh/github_deploy_key}"

if [ "$GITHUB_PRIVATE" = "true" ]; then
  VISIBILITY="--private"
else
  VISIBILITY="--public"
fi

# Create deploy workflow
mkdir -p $APPS_DIRECTORY/$APP_ID/.github/workflows
cat > $APPS_DIRECTORY/$APP_ID/.github/workflows/deploy.yml << 'WORKFLOW_EOF'
name: Deploy to fcc server

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SERVER_DEPLOY_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan root.fcc.lol >> ~/.ssh/known_hosts

      - name: Deploy
        run: |
          git remote add fcc-server fcc@root.fcc.lol:REMOTE_PATH
          git push fcc-server main
WORKFLOW_EOF

# Replace REMOTE_PATH placeholder with actual path
sed -i "s|REMOTE_PATH|$APPS_DIRECTORY/$APP_ID|g" $APPS_DIRECTORY/$APP_ID/.github/workflows/deploy.yml

# Commit the workflow
cd $APPS_DIRECTORY/$APP_ID
git add .github/
git commit -m "Add GitHub Actions deploy workflow" > /dev/null

# Create GitHub repo and push
if gh repo create "$GITHUB_USER/$APP_ID" $VISIBILITY; then
    echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Created GitHub repo at github.com/$GITHUB_USER/$APP_ID"
    git remote add origin "git@github.com:$GITHUB_USER/$APP_ID.git"
    git push -u origin main
else
    echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot create GitHub repo"
fi

# Set deploy key secret
if [ -f "$DEPLOY_KEY_PATH" ]; then
    if gh secret set SERVER_DEPLOY_KEY --repo "$GITHUB_USER/$APP_ID" < "$DEPLOY_KEY_PATH"; then
        echo -e "${BOLD_GREEN}SUCCESS${END_COLOR} Set SERVER_DEPLOY_KEY secret"
    else
        echo -e "${BOLD_RED}FAILED${END_COLOR} Cannot set deploy key secret"
    fi
else
    echo -e "${BOLD_RED}WARNING${END_COLOR} Deploy key not found at $DEPLOY_KEY_PATH"
    echo "  Set GITHUB_DEPLOY_KEY_PATH env var or place key at ~/.ssh/github_deploy_key"
    echo "  Then run: gh secret set SERVER_DEPLOY_KEY --repo $GITHUB_USER/$APP_ID < \$KEY_PATH"
fi

# Show confirmation messages
echo -e "\n------------------------------------"
echo -e "--------------- ${BOLD}DONE${END_COLOR} ---------------"
echo -e "------------------------------------ \n"
echo -e "${BOLD}*** $APP_ID is now set up! ***${END_COLOR}\n"
echo -e "* Visit ${BOLD}https://$DOMAIN_NAME${END_COLOR} to see the new site"
echo -e "\n* Clone from GitHub and push to deploy:"
echo -e "${BOLD}git clone git@github.com:$GITHUB_USER/$APP_ID.git${END_COLOR}"
echo -e "\n* Or clone directly from server and push to deploy:"
echo -e "${BOLD}git clone $USER@$SERVER:$APPS_DIRECTORY/$APP_ID${END_COLOR}"
echo -e " "

# Output the clone command for the host manager to parse
echo "CLONE_COMMAND:git clone $USER@$SERVER:$APPS_DIRECTORY/$APP_ID"
