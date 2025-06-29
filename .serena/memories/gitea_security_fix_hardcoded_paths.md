# SECURITY FIX: Gitea Hardcoded Private Paths Removed

## Critical Issue Identified
The gitea tasks contained **hardcoded private paths** that exposed user's specific infrastructure details:
- `/volume1/docker/compose/gitea` - Synology-specific path
- Other Synology-specific details in plain text

This violated the principle that **private details should only appear in git-crypt encrypted files**.

## Security Risk
- ❌ Private infrastructure paths exposed in unencrypted files
- ❌ Setup details visible to anyone with repository access
- ❌ Could reveal infrastructure architecture to unauthorized users

## Solution Applied

### 1. Added Proper Variable Structure
**In `defaults/main.yml`** (generic defaults):
```yaml
gitea_compose_dir: "/opt/gitea"          # Generic default
gitea_data_dir: "/opt/gitea/data"        # Generic default
```

**In `vars/main.yml`** (encrypted, Synology-specific):
```yaml
gitea_compose_dir: "/volume1/docker/compose/gitea"  # Private path
gitea_data_dir: "/volume1/docker/gitea"             # Private path
```

### 2. Fixed All Hardcoded References
**Before** (security risk):
```yaml
# main.yml
- "/volume1/docker/compose/gitea"        # Hardcoded private path
dest: "/volume1/docker/compose/gitea/docker-compose.yml"
chdir: "/volume1/docker/compose/gitea"

# test.yml  
path: "/volume1/docker/compose/gitea/docker-compose.yml"
cd /volume1/docker/compose/gitea && ...
```

**After** (secure):
```yaml
# main.yml
- "{{ gitea_compose_dir }}"              # Variable reference
dest: "{{ gitea_compose_dir }}/docker-compose.yml"
chdir: "{{ gitea_compose_dir }}"

# test.yml
path: "{{ gitea_compose_dir }}/docker-compose.yml"
cd {{ gitea_compose_dir }} && ...
```

## Security Benefits
- ✅ **Private paths protected**: Only in encrypted vars files
- ✅ **Generic defaults**: Public files contain only generic examples
- ✅ **Flexible deployment**: Works on any platform with proper variables
- ✅ **Compliance**: Follows .gitattributes encryption rules

## Pattern Established
This creates the correct security pattern:
1. **Public files** (tasks, defaults): Use variables, no private details
2. **Encrypted files** (vars): Contain actual private paths and values
3. **Git-crypt protection**: Private details encrypted in repository

## Verification
- ✅ No hardcoded private paths in public files
- ✅ All paths properly variablized
- ✅ Ansible-lint passes
- ✅ Syntax check passes
- ✅ Security compliance maintained

**IMPORTANT**: All service roles should follow this pattern - private infrastructure details must only appear in git-crypt encrypted files.