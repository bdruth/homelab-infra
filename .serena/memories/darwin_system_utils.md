# Darwin (macOS) System Utilities

## Common CLI Commands

### File System Operations

```bash
# List files
ls -la

# List files with detailed information in human-readable format
ls -lah

# Change directory
cd /path/to/directory

# Print working directory
pwd

# Create directory
mkdir directory_name

# Create nested directories
mkdir -p parent/child/grandchild

# Remove file
rm filename

# Remove directory
rm -r directory_name

# Copy file
cp source destination

# Move/rename file
mv source destination

# Find files by name (case insensitive)
find . -iname "*pattern*"

# Find files by content
grep -r "text to find" .
```

### Process Management

```bash
# List processes
ps aux

# List processes with a specific name
ps aux | grep process_name

# Kill process by PID
kill PID
kill -9 PID  # Force kill

# View running processes in real-time
top
```

### Network

```bash
# Check DNS resolution
dig domain.com

# Test connectivity to host
ping hostname

# Trace route to host
traceroute hostname

# Show network interfaces
ifconfig

# Show network connections
netstat -an
```

### Git Operations

```bash
# Clone repository
git clone repository_url

# Check status
git status

# Stage changes
git add file_name
git add -A  # All changes

# Commit changes
git commit -m "Commit message"

# Push changes
git push origin branch_name

# Pull changes
git pull origin branch_name

# Create and checkout branch
git checkout -b new_branch_name
```

### Package Management

```bash
# Use pkgx to run a command with dependencies
pkgx +dependency_name command

# Homebrew (if installed)
brew install package_name
brew update
brew upgrade
```

### Docker Commands

```bash
# List running containers
docker ps

# List all containers including stopped ones
docker ps -a

# Run container with interactive terminal
docker run -it image_name bash

# Stop container
docker stop container_id

# Remove container
docker rm container_id

# List images
docker images

# Remove image
docker rmi image_id
```

## Darwin-Specific Notes

- macOS uses BSD versions of many Unix commands, which may have slightly different options than their GNU/Linux counterparts
- Default shell is zsh in newer versions of macOS
- File system is case-insensitive by default (but case-preserving)
- Hidden files start with a dot (.) and can be shown in Finder with Cmd+Shift+.