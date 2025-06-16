#!/bin/bash

# LucidTalk Complete Installer
# Downloads and installs LucidTalk via P2P network

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
DISTRIBUTION_KEY="$1"
NODE_VERSION_REQUIRED=16
TEMP_DIR="$HOME/.lucidtalk-install-temp"
INSTALL_DIR="$HOME/Applications/LucidTalk"
DESKTOP_LAUNCHER="$HOME/Desktop/LucidTalk.command"

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

detect_os() {
    local os_name=$(uname -s)
    local os_version=""
    
    case "$os_name" in
        Darwin)
            os_version=$(sw_vers -productVersion)
            print_success "macOS $os_version detected"
            
            # Check macOS version (require 13.0+ for ScreenCaptureKit)
            local major_version=$(echo "$os_version" | cut -d '.' -f 1)
            if [[ $major_version -lt 13 ]]; then
                print_error "macOS 13.0 or later required for system audio capture"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported operating system: $os_name"
            print_info "LucidTalk currently supports macOS only"
            exit 1
            ;;
    esac
}

validate_distribution_key() {
    if [[ -z "$DISTRIBUTION_KEY" ]]; then
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
    
    # Basic validation (64 character hex string)
    if [[ ! "$DISTRIBUTION_KEY" =~ ^[a-f0-9]{64}$ ]]; then
        print_error "Invalid distribution key format"
        print_info "Key should be a 64-character hexadecimal string"
        exit 1
    fi
    
    print_success "Distribution key validated"
}

setup_temp_directory() {
    # Clean up any existing temporary directory
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    mkdir -p "$TEMP_DIR"
    print_success "Temporary directory created"
}

check_nodejs() {
    if command -v node &> /dev/null; then
        node_version=$(node --version | cut -d 'v' -f 2)
        major_version=$(echo "$node_version" | cut -d '.' -f 1)
        
        if [[ $major_version -ge $NODE_VERSION_REQUIRED ]]; then
            print_success "Node.js v$node_version found"
            return 0
        else
            print_error "Node.js v$node_version found, but v$NODE_VERSION_REQUIRED+ required"
        fi
    else
        print_error "Node.js not found"
    fi
    
    print_info "Installing Node.js automatically..."
    install_nodejs
}

install_nodejs() {
    echo "🔧 Installing Node.js..."
    
    # Try Homebrew first (most common on macOS)
    if command -v brew &> /dev/null; then
        echo "📦 Installing via Homebrew..."
        brew install node > /dev/null 2>&1
        if command -v node &> /dev/null; then
            local node_version=$(node --version)
            print_success "Node.js $node_version installed via Homebrew"
            return 0
        fi
    fi
    
    # Try NVM if available
    if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
        echo "📦 Installing via NVM..."
        source "$HOME/.nvm/nvm.sh"
        nvm install node > /dev/null 2>&1
        nvm use node > /dev/null 2>&1
        if command -v node &> /dev/null; then
            local node_version=$(node --version)
            print_success "Node.js $node_version installed via NVM"
            return 0
        fi
    fi
    
    # Direct download as last resort
    echo "📦 Installing via direct download..."
    local node_url="https://nodejs.org/dist/v20.11.0/node-v20.11.0-darwin-x64.tar.xz"
    local node_dir="$HOME/.local/nodejs"
    
    mkdir -p "$node_dir"
    curl -L "$node_url" | tar -xJ -C "$node_dir" --strip-components=1 > /dev/null 2>&1
    
    # Add to PATH temporarily
    export PATH="$node_dir/bin:$PATH"
    
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        print_success "Node.js $node_version installed via direct download"
        
        # Add to shell profile for persistence
        local shell_profile=""
        if [[ -f "$HOME/.zshrc" ]]; then
            shell_profile="$HOME/.zshrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            shell_profile="$HOME/.bash_profile"
        fi
        
        if [[ -n "$shell_profile" ]]; then
            echo "export PATH=\"$node_dir/bin:\$PATH\"" >> "$shell_profile"
            print_info "Added Node.js to $shell_profile"
        fi
        
        return 0
    fi
    
    print_error "Failed to install Node.js automatically"
    print_info "Please install Node.js manually from https://nodejs.org"
    exit 1
}

download_via_p2p() {
    echo -e "${PURPLE}🔸 Downloading LucidTalk via P2P network...${NC}"
    
    cd "$TEMP_DIR"
    
    # Create package.json with working versions
    echo "📦 Installing P2P components..."
    cat > package.json << EOF
{
  "name": "lucidtalk-p2p-downloader",
  "version": "1.0.0",
  "dependencies": {
    "corestore": "^7.4.5",
    "hyperdrive": "^11.13.4",
    "hyperswarm": "^4.11.7"
  }
}
EOF
    
    # Install dependencies
    npm install > /dev/null 2>&1
    
    # Create the P2P download script with exact working configuration
    cat > p2p-download.js << 'EOJS'
#!/usr/bin/env node

const Corestore = require('corestore');
const Hyperdrive = require('hyperdrive');
const Hyperswarm = require('hyperswarm');
const fs = require('fs');
const path = require('path');

const DISTRIBUTION_KEY = process.argv[2];

async function downloadViaP2P() {
    let swarm = null;
    let drive = null;
    
    try {
        console.log('🔍 Connecting to P2P network...');
        
        // Initialize corestore (use same pattern as working seeder)
        const store = new Corestore('./lucidtalk-temp');
        drive = new Hyperdrive(store, DISTRIBUTION_KEY);
        
        // Initialize Hyperswarm for peer discovery
        swarm = new Hyperswarm();
        
        // Set up connection handling
        swarm.on('connection', (conn) => {
            console.log('🤝 Connected to peer');
            store.replicate(conn);
        });
        
        await drive.ready();
        console.log('✅ Connected to P2P network!');
        
        // Join swarm with discovery key for peer finding
        const topic = drive.discoveryKey;
        const discovery = swarm.join(topic, { server: false, client: true });
        
        // Wait for peer discovery to complete
        console.log('🔍 Discovering peers...');
        await discovery.flushed();
        
        // Allow time for peer connections to establish
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        console.log('📋 Loading package information...');
        
        // Get the manifest file
        const manifestData = await drive.get('/manifest.json');
        
        if (!manifestData) {
            throw new Error('Manifest not found - seeder may be offline');
        }
        
        const manifest = JSON.parse(manifestData.toString());
        console.log(`📦 Found: ${manifest.name} v${manifest.version}`);
        
        // Download the bundled installer
        console.log('📥 Downloading LucidTalk-Installer.zip...');
        const installerData = await drive.get('/LucidTalk-Installer.zip');
        
        if (!installerData) {
            throw new Error('Installer package not found');
        }
        
        // Save the installer file
        const installerPath = './LucidTalk-Installer.zip';
        fs.writeFileSync(installerPath, installerData);
        
        const sizeMB = (installerData.length / 1024 / 1024).toFixed(1);
        console.log(`✅ Downloaded LucidTalk-Installer.zip (${sizeMB}MB)`);
        
        // Clean up connections
        await swarm.destroy();
        await drive.close();
        
        return installerPath;
        
    } catch (error) {
        console.error('❌ P2P download failed:', error.message);
        
        // Clean up on error
        if (swarm) {
            try {
                await swarm.destroy();
            } catch (e) {}
        }
        if (drive) {
            try {
                await drive.close();
            } catch (e) {}
        }
        
        // Provide helpful error messages
        if (error.message.includes('timeout') || error.message.includes('not found')) {
            console.error('🔧 The P2P seeder appears to be offline');
            console.error('   Ask the person who shared LucidTalk to start seeding');
        }
        
        throw error;
    }
}

// Run the download
downloadViaP2P().then(() => {
    console.log('🎉 P2P download successful!');
    process.exit(0);
}).catch(() => {
    process.exit(1);
});
EOJS
    
    # Execute the P2P download
    if ! node p2p-download.js "$DISTRIBUTION_KEY"; then
        print_error "P2P download failed"
        print_info "Trying alternative download methods..."
        
        # Here you could add HTTP fallback if needed
        # download_via_http
        
        exit 1
    fi
    
    # Verify download
    if [[ ! -f "LucidTalk-Installer.zip" ]]; then
        print_error "Installation package not found after download"
        exit 1
    fi
}

install_lucidtalk() {
    echo -e "${BLUE}🚀 Installing LucidTalk...${NC}"
    
    cd "$TEMP_DIR"
    
    # Remove any existing installation
    if [[ -d "$INSTALL_DIR" ]]; then
        echo "🗑️  Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    mkdir -p "$INSTALL_DIR"
    
    # Extract the installer package
    echo "📦 Extracting application..."
    unzip -q LucidTalk-Installer.zip -d extracted/
    
    # Copy all extracted contents to install directory
    cp -r extracted/* "$INSTALL_DIR/"
    
    cd "$INSTALL_DIR"
    
    # Install Node.js dependencies
    echo "⚙️ Installing dependencies..."
    if ! npm install > /dev/null 2>&1; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    # Create desktop launcher
    echo "🚀 Creating desktop launcher..."
    cat > "$DESKTOP_LAUNCHER" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
npm start
EOF
    chmod +x "$DESKTOP_LAUNCHER"
    
    print_success "LucidTalk installed successfully!"
}

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

main() {
    print_header
    
    # Set up cleanup on exit
    trap cleanup EXIT
    
    # Installation steps
    detect_os
    validate_distribution_key
    setup_temp_directory
    check_nodejs
    download_via_p2p
    install_lucidtalk
    
    # Success message
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo ""
    echo "🚀 To start LucidTalk:"
    echo "   • Double-click 'LucidTalk.command' on your Desktop"
    echo "   • Or run: cd $INSTALL_DIR && npm start"
    echo ""
    echo "📝 LucidTalk Features:"
    echo "   • Real-time meeting transcription"
    echo "   • AI-powered summaries (completely local)"
    echo "   • P2P session sharing"
    echo "   • Complete privacy - no cloud dependencies"
    echo ""
    echo "🎙️ Ready for your next meeting!"
}

# Run the installer
main "$@"
