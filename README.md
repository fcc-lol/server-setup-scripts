# Server Setup Scripts

## [host-manager.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/host-manager.sh)
#### An interactive TUI for managing your server instances.
This script provides a menu-driven interface to run the other setup, removal, and maintenance scripts on a remote server via SSH.
- Create new React, Vite, Express, or Full Stack instances.
- Remove existing React, Vite, Express, or Full Stack instances.
- Rebuild/reload existing React, Vite, Express, or Full Stack instances.
- View git remote URLs (GitHub origin when available) for all instances.

## [setup-new-domain.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-domain.sh)
#### Setup an Apache VirtualHost for a domain or subdomain serving PHP or HTML

This script is not included in this repository.
1. Create root directory for domain
2. Create public html directory
3. Change permissions for domain directory to specified user
4. If an index.html file doesn't exist, create a placeholder one
5. Optional: Pick PHP version
6. Create a VirtualHost config file that points to the domain directory
7. Reload Apache
8. If Git, set up a hook that deploys any commits made to this repo 
9. Optional: Set up a bare Git repository in the domain directory

## [setup-new-express-server.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-express-server.sh)
#### Setup an Express server accessible from a Apache VirtualHost subdomain

1. Find an available port
2. Create root directory for domain
3. Change permissions for domain directory to specified user
4. Create a basic server
5. Create a basic README.md
6. Create basic package.json file
7. Install node modules
8. Start node process
9. Create a VirtualHost config file that proxies requests to node
10. Enable site in Apache
11. Reload Apache
12. Initialize Git repository
13. Create basic gitignore file
14. Commit basic code
15. Set up a hook that deploys any commits made to this repo
16. Create a GitHub Actions deploy workflow
17. Create a GitHub repo under fcc-lol and push
18. Set the SERVER_DEPLOY_KEY secret so pushes to main on GitHub deploy automatically

## [restart-express-server.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/restart-express-server.sh)
#### Restart an Express server created by [setup-new-express-server.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-express-server.sh)

1. Stop node process
2. Install node modules
3. Start node process
4. Reload Apache

## [remove-express-server.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/remove-express-server.sh)
#### Decommission an Express server created by [setup-new-express-server.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-express-server.sh)

1. Disable site in Apache
2. Delete Apache config file
3. Delete site directory
4. Stop node process
5. Reload Apache

## [setup-new-react-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-react-app.sh)
#### Setup a Create React App accessible from an Apache VirtualHost domain or subdomain

1. Create root directory for app
2. Create src directory for app
3. Create public directory for app
4. Creates basic files in src/
5. Creates basic files in public/
6. Create a basic README.md
7. Create a basic package.json
8. Create a setup-log.json
9. Change permissions for app directory to specified user
10. Install node modules
11. Build app for production
12. Create a VirtualHost config file that points to the app's build directory
13. Enable site in Apache
14. Reload Apache
15. Initialize Git repository
16. Create basic gitignore file
17. Commit basic code
18. Set up a hook that deploys any commits made to this repo
19. Create a GitHub Actions deploy workflow
20. Create a GitHub repo under fcc-lol and push
21. Set the SERVER_DEPLOY_KEY secret so pushes to main on GitHub deploy automatically

## [rebuild-react-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/rebuild-react-app.sh)
#### Rebuild a React app created by [setup-new-react-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-react-app.sh)

1. Install node modules
2. Build app for production
3. Reload Apache
   
## [remove-react-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/remove-react-app.sh)
#### Decommission a React app created by [setup-new-react-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-react-app.sh)

1. Disable site in Apache
2. Delete Apache config file
3. Delete app directory
4. Reload Apache

## [setup-new-vite-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-vite-app.sh)
#### Setup a Vite (React) app accessible from an Apache VirtualHost domain or subdomain

1. Create root directory for app
2. Create src and public directories
3. Creates basic files in src/ and public/
4. Create a basic README.md
5. Create a basic package.json and other config files (vite.config.js, .eslintrc.cjs)
6. Create a setup-log.json
7. Change permissions for app directory to specified user
8. Install node modules
9. Build app for production
10. Create a VirtualHost config file that points to the app's dist directory
11. Enable site in Apache
12. Reload Apache
13. Initialize Git repository
14. Create basic gitignore file
15. Commit basic code
16. Set up a hook that deploys any commits made to this repo
17. Create a GitHub Actions deploy workflow
18. Create a GitHub repo under fcc-lol and push
19. Set the SERVER_DEPLOY_KEY secret so pushes to main on GitHub deploy automatically

## [restart-full-stack-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/restart-full-stack-app.sh)
#### Restart a Full Stack app created by [setup-new-full-stack-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-full-stack-app.sh)

1. Install node modules
2. Build app for production
3. Kill any stale process on the port
4. Restart via PM2
5. Reload Apache

## [remove-full-stack-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/remove-full-stack-app.sh)
#### Decommission a Full Stack app created by [setup-new-full-stack-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-full-stack-app.sh)

1. Stop and remove from PM2
2. Disable site in Apache
3. Delete Apache config file
4. Delete app directory
5. Reload Apache

## [rebuild-vite-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/rebuild-vite-app.sh)
#### Rebuild a Vite app created by [setup-new-vite-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-vite-app.sh)

1. Install node modules
2. Build app for production
3. Reload Apache
   
## [remove-vite-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/remove-vite-app.sh)
#### Decommission a Vite app created by [setup-new-vite-app.sh](https://github.com/fcc-lol/server-setup-scripts/blob/main/setup-new-vite-app.sh)

1. Disable site in Apache
2. Delete Apache config file
3. Delete app directory
4. Reload Apache
