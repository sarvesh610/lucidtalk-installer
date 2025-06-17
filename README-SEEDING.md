# LucidTalk P2P Distribution - Seeding Guide

## Overview
This guide explains how to update and redistribute LucidTalk after making changes to the codebase using the P2P Hyperdrive system.

## Prerequisites
- Node.js 16+
- macOS with development tools
- Swift compiler (for building binaries)

## Step-by-Step Process

### 1. Make Your Changes
Edit any files in the LucidTalk codebase as needed.

### 2. Build Pre-compiled Swift Binary
```bash
# Build the Swift binary for distribution
npm run build-swift
```

This creates `src/swift/MindMeetStreamer` - a pre-compiled binary that eliminates Swift compilation requirements for end users.

### 3. Stop Current Seeder
If a seeder is running, stop it:
```bash
# Find and kill the seeder process
pkill -f "node robust-seeder.js"
```

### 4. Create New Distribution
```bash
# Create fresh P2P distribution with your changes
node create-p2p-drive.js
```

This will:
- Package the entire application
- Include the pre-compiled Swift binary
- Create a new Hyperdrive with updated files
- Generate a new distribution key

### 5. Start New Seeder
```bash
# Start seeding the new distribution
node robust-seeder.js
```

The seeder will output:
- 🔑 Drive Key: `[new-key-here]`
- 🔍 Discovery key for peer connections
- 💓 Heartbeat showing active connections

### 6. Update Installation Script
Update the installer script to use the new drive key:

1. Edit `install-lucidtalk.sh` in your GitHub repository
2. Replace the old drive key with the new one
3. Commit and push changes

### 7. Test Installation
Test the complete process:
```bash
# Test installation with new distribution
bash <(curl -s https://raw.githubusercontent.com/[your-repo]/install-lucidtalk.sh) [new-drive-key]
```

## File Locations

### Distribution Files
- **Source**: `/Users/sarveshnaidu/projects/mindmeet/`
- **Distribution**: `/Volumes/Mac-backup/LucidTalk-Hyperdrive/distribution/`
- **Hyperdrive**: `/Volumes/Mac-backup/LucidTalk-Hyperdrive/distribution/hyperdrive/`

### Key Scripts
- `create-p2p-drive.js` - Creates new distributions
- `robust-seeder.js` - Seeds distributions to P2P network
- `install-lucidtalk.sh` - End-user installation script

## Important Notes

### Pre-compiled Binaries
Always build Swift binaries before distribution:
```bash
npm run build-swift
```

This prevents users from encountering Swift SDK version mismatch errors.

### Drive Key Management
- Each new distribution gets a unique drive key
- Users need the new drive key to download updates
- Update your installer script with the new key
- Keep seeder running for users to download

### Testing
Always test the complete installation flow:
1. Create distribution
2. Start seeder  
3. Download and install as end user
4. Verify application launches correctly

## Troubleshooting

### Seeder Not Responding
- Check if seeder process is running: `ps aux | grep seeder`
- Verify Hyperdrive directory exists
- Check network connectivity

### Installation Failures
- Verify Swift binary is included and executable
- Check installer script has correct drive key
- Ensure seeder is running and accessible

### File Corruption
- Recreate distribution if files appear corrupted
- Always test installation after creating new distribution
- Keep seeder logs for debugging: `tail -f seeder.log`

## Current Distribution
- **Drive Key**: `f009372b2ce09f2764201afbfee3756b7df04503ce5e9c1e2614f93f2f4abc01`
- **Status**: Active (includes whisper-cli dependencies + meeting templates + AI object parsing fixes)
- **Installation**: `bash <(curl -s https://raw.githubusercontent.com/sarvesh610/lucidtalk-installer/main/install-lucidtalk.sh) f009372b2ce09f2764201afbfee3756b7df04503ce5e9c1e2614f93f2f4abc01`