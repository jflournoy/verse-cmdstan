# Docker Development Environment Setup

## What's New in the Enhanced Dockerfile

### Node.js Environment (v22.x LTS)
- Full Node.js and npm installation
- Global packages: eslint, typescript, ts-node
- Proper permissions for rstudio user
- npm global packages installed to `/home/rstudio/.npm-global`

### Additional R Packages
- `testthat` - Testing framework
- `devtools` - R package development
- `covr` - Test coverage
- `lintr` - Code linting
- `styler` - Code formatting
- `usethis` - Project setup utilities

### VS Code Integration
- Git safe directory configuration
- Workspace directory at `/home/rstudio/code`
- Extension recommendations file (`.vscode/extensions.json`)

## Building the Image

```bash
cd /home/rstudio/code/verse-cmdstan

# Build the image
docker build -t cmdstan-dev:latest -f Dockerfile.enhanced .

# Or if you want to replace the original
mv Dockerfile Dockerfile.original
mv Dockerfile.enhanced Dockerfile
docker build -t cmdstan-dev:latest .
```

## Running the Container

### Option 1: RStudio Server (port 8787)
```bash
docker run -d \
  --name rstudio-dev \
  -p 8787:8787 \
  -e PASSWORD=yourpassword \
  -v $(pwd):/home/rstudio/code \
  cmdstan-dev:latest
```

Access RStudio at: http://localhost:8787

### Option 2: VS Code Remote-SSH
```bash
docker run -d \
  --name rstudio-dev \
  -p 8787:8787 \
  -p 2222:22 \
  -e PASSWORD=yourpassword \
  -v $(pwd):/home/rstudio/code \
  cmdstan-dev:latest
```

Then connect via VS Code Remote-SSH to `localhost:2222`

### Option 3: VS Code Dev Containers
Create `.devcontainer/devcontainer.json`:

```json
{
  "name": "R Stan Development",
  "image": "cmdstan-dev:latest",
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "reditorsupport.r",
        "quarto.quarto"
      ]
    }
  },
  "forwardPorts": [8787],
  "postStartCommand": "git config --global safe.directory '*'",
  "remoteUser": "rstudio"
}
```

## Verifying the Environment

Once inside the container:

```bash
# Check Node.js
node --version   # Should be v22.x.x
npm --version    # Should be 10.x.x

# Check R
R --version      # Should be 4.3.2

# Check Quarto
quarto --version # Should be 1.5.57

# Check CmdStan
echo $CMDSTAN    # Should show /cmdstan/cmdstan-2.35.0

# Check npm global packages work
npm list -g --depth=0
```

## Installing Claude Code Extension

### Method 1: VS Code UI
1. Open VS Code
2. Press `Ctrl+Shift+X` (Extensions panel)
3. Search for "Claude Code"
4. Install "Claude Code" by Anthropic

### Method 2: Command Line (if using code-server)
```bash
code-server --install-extension anthropic.claude-code
```

### Method 3: Sync Settings
If you use VS Code Settings Sync, your extensions will automatically install.

## Project Setup for Claude Code

In your project directory (e.g., `/home/rstudio/code/phd-unemployment-model`):

```bash
# Install npm dependencies
npm install

# Verify tooling works
npm run env:check    # Should now pass!
npm run hygiene:full # Should run all checks
npm run test:r       # Should run R tests

# Initialize git if needed
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Troubleshooting

### Node.js permission issues
```bash
# Fix npm global permissions
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Git safe directory warnings
```bash
git config --global --add safe.directory '*'
```

### R package installation issues
```bash
# Update all packages
Rscript -e "update.packages(ask = FALSE)"

# Reinstall specific package
Rscript -e "install.packages('packagename')"
```

## Next Steps

1. **Build the enhanced Docker image**
2. **Run container with volume mount** to your code directory
3. **Connect via VS Code** Remote-SSH or Dev Containers
4. **Install Claude Code extension** (if not already synced)
5. **Run `/hygiene`** in your project to verify everything works

## Integration with Existing Projects

To add this setup to existing projects:

1. Copy `.vscode/extensions.json` to your project (renamed from `.vscode-extensions.json`)
2. Add `npm run env:check` script to verify environment
3. Ensure `package.json` has `"node": ">=22.0.0"` in engines
4. Rebuild your Docker image with the enhanced Dockerfile

## Resources

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Rocker Project](https://rocker-project.org/)
- [CmdStanR Documentation](https://mc-stan.org/cmdstanr/)
- [Quarto Documentation](https://quarto.org/)
