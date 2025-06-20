#!/bin/bash

# LucidTalk Complete Installer
# Handles Node.js detection/installation + P2P download + app installation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DISTRIBUTION_KEY="$1"
TEMP_DIR="$HOME/.lucidtalk-install-temp"
INSTALL_DIR="$HOME/Applications/LucidTalk"
DESKTOP_LAUNCHER="$HOME/Desktop/LucidTalk.command"
NODE_VERSION_REQUIRED="16"

# Functions
print_header() {
    clear
    echo -e "${BLUE}"
    echo "🎙️  LucidTalk Complete Installer"
    echo "   From Talk to Takeaway — Instantly"
    echo ""
    echo "   ✅ Private meeting transcription"
    echo "   ✅ AI summaries (completely local)"
    echo "   ✅ P2P sharing (no servers)"
    echo "   ✅ Real-time Whisper AI"
    echo -e "${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔸 $1${NC}"
}

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "LucidTalk requires macOS 13.0 or later"
        exit 1
    fi
    
    # Check macOS version
    macos_version=$(sw_vers -productVersion)
    major_version=$(echo "$macos_version" | cut -d '.' -f 1)
    
    if [[ $major_version -lt 13 ]]; then
        print_error "LucidTalk requires macOS 13.0 or later (you have $macos_version)"
        exit 1
    fi
    
    print_success "macOS $macos_version detected"
}

check_nodejs() {
    if command -v node &> /dev/null; then
        node_version=$(node --version | cut -d 'v' -f 2)
        major_version=$(echo "$node_version" | cut -d '.' -f 1)
        
        if [[ $major_version -ge $NODE_VERSION_REQUIRED ]]; then
            print_success "Node.js v$node_version found"
            return 0
        else
            print_warning "Node.js v$node_version found, but v$NODE_VERSION_REQUIRED+ required"
            return 1
        fi
    fi
    
    return 1
}

install_nodejs_homebrew() {
    print_info "Installing Node.js via Homebrew..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_info "Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            export PATH="/usr/local/bin:$PATH"
        fi
    fi
    
    # Install Node.js
    brew install node
    
    # Add to PATH
    if [[ -f "/opt/homebrew/bin/node" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [[ -f "/usr/local/bin/node" ]]; then
        export PATH="/usr/local/bin:$PATH"
    fi
}

install_nodejs_nvm() {
    print_info "Installing Node.js via NVM..."
    
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Install latest LTS Node.js
    nvm install --lts
    nvm use --lts
    nvm alias default node
}

download_and_install_nodejs() {
    print_info "Downloading Node.js installer..."
    
    # Detect architecture
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        node_arch="arm64"
    else
        node_arch="x64"
    fi
    
    # Download latest LTS installer
    node_url="https://nodejs.org/dist/latest-v20.x/node-v20.11.1-darwin-$node_arch.tar.gz"
    
    curl -o "$TEMP_DIR/node.tar.gz" "$node_url"
    
    # Extract to temporary location
    tar -xzf "$TEMP_DIR/node.tar.gz" -C "$TEMP_DIR"
    
    # Create local Node.js installation
    local_node_dir="$HOME/.local/nodejs"
    mkdir -p "$local_node_dir"
    
    # Move files
    cp -r "$TEMP_DIR"/node-v20.11.1-darwin-$node_arch/* "$local_node_dir/"
    
    # Add to PATH for this session
    export PATH="$local_node_dir/bin:$PATH"
    
    # Add to shell profile for future sessions
    shell_profile=""
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_profile="$HOME/.zshrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        shell_profile="$HOME/.bash_profile"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_profile="$HOME/.bashrc"
    fi
    
    if [[ -n "$shell_profile" ]]; then
        echo "" >> "$shell_profile"
        echo "# LucidTalk Node.js installation" >> "$shell_profile"
        echo "export PATH=\"$local_node_dir/bin:\$PATH\"" >> "$shell_profile"
        print_info "Added Node.js to $shell_profile"
    fi
}

install_nodejs() {
    print_step "Node.js $NODE_VERSION_REQUIRED+ is required for LucidTalk's P2P technology"
    echo ""
    echo "Choose installation method:"
    echo "1. Homebrew (recommended - easiest)"
    echo "2. NVM (Node Version Manager - for developers)"
    echo "3. Direct download (manual installation)"
    echo "4. Exit and install manually from nodejs.org"
    echo ""
    
    while true; do
        read -p "Choose option (1-4): " choice
        
        case $choice in
            1)
                install_nodejs_homebrew
                break
                ;;
            2)
                install_nodejs_nvm
                break
                ;;
            3)
                download_and_install_nodejs
                break
                ;;
            4)
                print_info "Please install Node.js from https://nodejs.org"
                print_info "Then run this installer again:"
                echo "bash <(curl -s https://your-site.com/install-lucidtalk.sh) $DISTRIBUTION_KEY"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
    
    # Verify installation
    if check_nodejs; then
        print_success "Node.js installed successfully!"
    else
        print_error "Node.js installation failed"
        print_info "Please try a different installation method or install manually from nodejs.org"
        exit 1
    fi
}

validate_distribution_key() {
    if [[ -z "$DISTRIBUTION_KEY" ]]; then
        echo ""
        print_error "No distribution key provided"
        echo ""
        echo "Usage: bash <(curl -s https://your-site.com/install-lucidtalk.sh) YOUR_KEY"
        echo ""
        echo "Example:"
        echo "bash <(curl -s https://your-site.com/install-lucidtalk.sh) a864c9bd98b43fe36c3dab8959f1df3bb04d018f5310f9d57c4127523c42d9b8"
        echo ""
        print_info "If you don't have a key, ask the person who shared LucidTalk with you."
        exit 1
    fi
    
    # Basic validation - should be 64 character hex string
    if [[ ! "$DISTRIBUTION_KEY" =~ ^[a-f0-9]{64}$ ]]; then
        print_error "Invalid distribution key format"
        echo "Key should be 64 characters (letters a-f and numbers 0-9)"
        exit 1
    fi
    
    print_success "Distribution key validated"
}

setup_temp_directory() {
    # Clean up any previous installation
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    mkdir -p "$TEMP_DIR"
    print_success "Temporary directory created"
}

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

download_lucidtalk() {
    print_step "Downloading LucidTalk via P2P network..."
    
    # Create Node.js P2P downloader script
    cat > "$TEMP_DIR/p2p-downloader.js" << 'EOF'
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const DISTRIBUTION_KEY = process.argv[2];
const TEMP_DIR = process.argv[3];

async function downloadLucidTalk() {
    try {
        console.log('📦 Installing P2P components...');
        
        // Create package.json
        const packageJson = {
            name: "lucidtalk-p2p-downloader",
            version: "1.0.0",
            dependencies: {
                "corestore": "^7.4.4",
                "hyperdrive": "^11.0.0",
                "hyperswarm": "^4.7.15"
            }
        };
        
        fs.writeFileSync(path.join(TEMP_DIR, 'package.json'), JSON.stringify(packageJson, null, 2));
        
        // Install dependencies
        execSync('npm install', { cwd: TEMP_DIR, stdio: 'pipe' });
        
        console.log('🔍 Connecting to P2P network...');
        
        // Load modules
        const Corestore = require(path.join(TEMP_DIR, 'node_modules', 'corestore'));
        const Hyperdrive = require(path.join(TEMP_DIR, 'node_modules', 'hyperdrive'));
        const Hyperswarm = require(path.join(TEMP_DIR, 'node_modules', 'hyperswarm'));
        
        const store = new Corestore(path.join(TEMP_DIR, 'hyperdrive'));
        const drive = new Hyperdrive(store, Buffer.from(DISTRIBUTION_KEY, 'hex'));
        
        await drive.ready();
        console.log('✅ Drive ready, connecting to P2P network...');
        
        // Setup swarm connection with proper event handling
        const swarm = new Hyperswarm();
        let peerConnected = false;
        
        swarm.on('connection', (connection) => {
            console.log('🔗 Connected to peer');
            peerConnected = true;
            store.replicate(connection);
        });
        
        swarm.join(drive.discoveryKey);
        await swarm.flush();
        console.log('✅ Joined P2P swarm');
        
        // Wait for peer connections and file synchronization
        console.log('⏳ Waiting for peer discovery and file sync...');
        let retries = 0;
        const maxRetries = 10;
        let manifestData = null;
        
        while (retries < maxRetries && !manifestData) {
            try {
                // Wait progressively longer for network sync
                const waitTime = Math.min(2000 + (retries * 1000), 8000);
                await new Promise(resolve => setTimeout(resolve, waitTime));
                
                console.log(`📋 Attempting to load manifest (attempt ${retries + 1}/${maxRetries})...`);
                manifestData = await drive.get('/manifest.json');
                
                if (manifestData) {
                    console.log('✅ Manifest loaded successfully!');
                    break;
                }
            } catch (error) {
                console.log(`⚠️  Attempt ${retries + 1} failed, retrying...`);
            }
            retries++;
        }
        
        if (!manifestData) {
            await swarm.destroy();
            throw new Error('Unable to access P2P files after multiple attempts. The seeder may be offline.');
        }
        
        const manifest = JSON.parse(manifestData.toString());
        
        console.log(`📦 Found: ${manifest.name} v${manifest.version}`);
        
        console.log('📥 Downloading complete installer package...');
        const installerData = await drive.get('/LucidTalk-Installer.zip');
        
        if (!installerData) {
            throw new Error('Installation package not found in P2P network');
        }
        
        const sizeMB = (installerData.length / 1024 / 1024).toFixed(1);
        console.log(`✅ Downloaded ${sizeMB}MB package`);
        
        // Save installer
        const installerPath = path.join(TEMP_DIR, 'LucidTalk-Installer.zip');
        fs.writeFileSync(installerPath, installerData);
        
        console.log('📦 Extracting installation files...');
        execSync(`unzip -q "${installerPath}" -d "${TEMP_DIR}"`);
        
        // Cleanup P2P connections
        await swarm.destroy();
        await drive.close();
        console.log('✅ P2P download complete!');
        
    } catch (error) {
        console.error('❌ P2P download failed:', error.message);
        if (error.message.includes('Cannot read properties of null')) {
            console.error('🔧 The P2P seeder appears to be offline');
            console.error('   Ask the person who shared LucidTalk to start seeding');
        }
        process.exit(1);
    }
}

downloadLucidTalk();
EOF
    
    # Run the P2P downloader
    cd "$TEMP_DIR"
    node p2p-downloader.js "$DISTRIBUTION_KEY" "$TEMP_DIR"
}

install_lucidtalk() {
    print_step "Installing LucidTalk..."
    
    # Remove existing installation
    if [[ -d "$INSTALL_DIR" ]]; then
        print_info "Removing previous installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Verify required files exist
    cd "$TEMP_DIR"
    
    if [[ ! -f "LucidTalk.zip" ]] || [[ ! -f "ggml-base.bin" ]]; then
        print_error "Installation files incomplete"
        exit 1
    fi
    
    print_info "Extracting LucidTalk application..."
    unzip -o -q LucidTalk.zip -d "$INSTALL_DIR"
    
    print_info "Installing main dependencies..."
    cd "$INSTALL_DIR"
    
    # Remove distributed node_modules to avoid binary compatibility issues
    print_info "Rebuilding native dependencies for local system..."
    rm -rf node_modules package-lock.json
    
    # Create a simple package.json for quick installation
    print_info "Installing only essential dependencies (electron)..."
    
    # Install all dependencies for Electron Forge
    print_info "Installing all dependencies for Electron Forge..."
    if npm install --no-audit --no-fund; then
        print_success "All dependencies installed successfully"
        
        # Fix webpack asset relocator compatibility issue
        print_info "Ensuring webpack compatibility..."
        npm install @vercel/webpack-asset-relocator-loader@1.7.3 --save-dev --no-audit --no-fund
        print_success "Webpack compatibility ensured"
    else
        print_warning "Full installation failed, trying essential dependencies only..."
        
        # Create minimal package.json with essential dependencies
        cat > package-minimal.json << 'EOF'
{
  "name": "lucidtalk",
  "version": "1.0.0",
  "main": ".webpack/main",
  "scripts": {
    "start": "electron-forge start",
    "package": "electron-forge package"
  },
  "dependencies": {
    "electron": "^36.5.0",
    "@electron-forge/cli": "^7.8.1"
  }
}
EOF
        mv package.json package-full.json
        mv package-minimal.json package.json
        
        if npm install --no-audit --no-fund; then
            print_success "Essential dependencies installed successfully"
            # Fix webpack compatibility for minimal installation too
            npm install @vercel/webpack-asset-relocator-loader@1.7.3 --save-dev --no-audit --no-fund
            # Restore full package.json for future use
            mv package-full.json package.json
        else
            print_error "Even minimal installation failed"
            mv package-full.json package.json
        fi
    fi
    
    # Quick verification
    if [[ -f "node_modules/.bin/electron" ]] || [[ -d "node_modules/electron" ]]; then
        print_success "LucidTalk is ready to run!"
    else
        print_warning "Installation partially completed - you may need to run 'npm install' manually"
    fi
    
    print_info "Installing backend dependencies..."
    if [[ -d "backend" ]]; then
        cd backend
        if ! npm install; then
            print_error "Failed to install backend dependencies"
            print_info "Trying with verbose output..."
            npm install --verbose
        fi
        cd ..
        print_success "Backend dependencies installed"
    else
        print_warning "Backend directory not found"
    fi
    
    print_info "Setting up AI model..."
    mkdir -p models
    cp "$TEMP_DIR/ggml-base.bin" models/
    
    # Verify electron was installed
    print_info "Verifying Electron installation..."
    if [[ ! -f "node_modules/.bin/electron" ]] && [[ ! -f "node_modules/electron/dist/Electron.app/Contents/MacOS/Electron" ]]; then
        print_error "Electron installation failed"
        print_info "Attempting manual electron installation..."
        npm install electron@^28.0.0 --save
        
        if [[ ! -f "node_modules/.bin/electron" ]] && [[ ! -f "node_modules/electron/dist/Electron.app/Contents/MacOS/Electron" ]]; then
            print_error "Manual electron installation also failed"
            print_warning "You may need to run 'npm install' manually in $INSTALL_DIR"
        else
            print_success "Electron installed successfully"
        fi
    else
        print_success "Electron verified"
    fi

    print_info "Creating desktop launcher..."
    cat > "$DESKTOP_LAUNCHER" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
npm start
EOF
    chmod +x "$DESKTOP_LAUNCHER"
    
    print_success "LucidTalk installed successfully!"
}

main() {
    print_header
    
    # Validate system requirements
    check_macos
    validate_distribution_key
    
    # Set up environment
    setup_temp_directory
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Check and install Node.js if needed
    if ! check_nodejs; then
        install_nodejs
    fi
    
    # Download and install LucidTalk
    download_lucidtalk
    install_lucidtalk
    
    # Success message
    echo ""
    echo -e "${GREEN}🎉 LucidTalk Installation Complete!${NC}"
    echo ""
    echo "🚀 To start LucidTalk:"
    echo "   • Double-click 'LucidTalk.command' on your Desktop"
    echo "   • Or run: cd '$INSTALL_DIR' && npm start"
    echo ""
    echo "📱 Features available:"
    echo "   • Real-time meeting transcription"
    echo "   • AI summaries (completely private)"
    echo "   • P2P session sharing"
    echo "   • Everything runs locally"
    echo ""
    echo "💬 Share LucidTalk with friends using this key:"
    echo "   $DISTRIBUTION_KEY"
    echo ""
    echo "🔒 Privacy guarantee: All processing happens on your machine."
    echo "    No data is sent to external servers."
    echo ""
    echo "📝 Optional: Help us improve by reporting successful installation:"
    echo "   https://github.com/sarvesh610/lucidtalk-installer/issues"
    echo "   (Just create an issue saying 'Installed successfully!')"
    echo ""
    print_success "Enjoy private, intelligent meeting transcription!"
}

# Run main function
main "$@"
