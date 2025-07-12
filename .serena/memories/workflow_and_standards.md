# Workflow and Standards

## 🚨 CRITICAL SECURITY REQUIREMENTS 🚨

### ⚠️ ABSOLUTE PROHIBITION: NO PRIVATE INFORMATION EXPOSURE ⚠️

**NEVER** include private or sensitive information in:
- ❌ **Commit messages** (git commit messages are PUBLIC)
- ❌ **Pull request descriptions**
- ❌ **Issue descriptions**
- ❌ **Code comments**
- ❌ **Documentation files** (unless git-crypt protected)
- ❌ **Log outputs** shared publicly
- ❌ **Example files** or configuration templates
- ❌ **Error messages** or debug output

### 🔒 EXAMPLES OF PRIVATE INFORMATION THAT MUST NEVER BE EXPOSED
- Private hostnames (e.g., `server.private-domain.com`)
- IP addresses of internal infrastructure
- Usernames or account names
- Server names or infrastructure details
- Internal service URLs or endpoints
- Private network topology information
- System specifications or hardware details
- Internal process names or service configurations

### ✅ SAFE ALTERNATIVES FOR DOCUMENTATION
- Use placeholders: `<hostname>`, `<server>`, `<service-name>`
- Use generic examples: `example.com`, `server.example.com`
- Use template variables: `{{ ansible_host }}`, `{{ service_url }}`
- Use descriptive terms: "configured logging server", "target host", "syslog endpoint"

### 🔐 IDENTIFYING GIT-CRYPT PROTECTED FILES

**Files that CAN contain sensitive information** (encrypted by git-crypt):
Check `.gitattributes` for patterns with `filter=git-crypt`. Current protected patterns:
- `**/vars/main.yml` - Service role variables
- `*.tfbackend` - Terraform backend configurations  
- `*.tfvars` - Terraform variable files
- `*inventory.yml` - Ansible inventory files
- `**/group_vars/*.yml` - Ansible group variables
- `**/host_vars/*.yml` - Ansible host variables
- `**/defaults/*.yml` - Ansible role defaults

**Files that CANNOT contain sensitive information** (not encrypted):
- `*.example.*` - Example files (explicitly excluded from git-crypt)
- `README.md` files
- `main.yml` playbooks
- `test-playbook.yml` files
- Commit messages and git metadata
- Documentation files
- Template files (`.j2`)

**To verify if a file is git-crypt protected:**
```bash
# Check if file shows as encrypted in git status
git-crypt status

# Check .gitattributes patterns
grep "filter=git-crypt" .gitattributes
```

### 🛡️ MANDATORY SECURITY CHECKLIST BEFORE ANY COMMIT

**EVERY commit message MUST be reviewed for:**
- [ ] ❌ No private hostnames or domains
- [ ] ❌ No internal IP addresses
- [ ] ❌ No usernames or account details
- [ ] ❌ No server names or infrastructure specifics
- [ ] ❌ No sensitive configuration values
- [ ] ✅ Only generic, public-safe descriptions

**IF YOU ACCIDENTALLY INCLUDE PRIVATE INFORMATION:**
1. 🛑 **IMMEDIATELY** stop the commit process
2. 🔄 Use `git reset --soft HEAD~1` if already committed locally
3. ✏️ Rewrite commit message with generic terms
4. 🔍 Double-check all changes for any other private data
5. ✅ Recommit with clean, public-safe message

### 📝 COMMIT MESSAGE SECURITY GUIDELINES

**❌ WRONG - Exposes Private Information:**
```text
feat: Add syslog forwarding to graylog.private-company.com
- Configured logging to internal-server-01.local
- Updated firewall rules for 192.168.1.100
```

**✅ CORRECT - Generic and Safe:**
```text
feat: Add centralized syslog forwarding capability
- Configured logging to designated syslog server
- Updated firewall rules for internal infrastructure
```

## Task Completion Process

### 1. Code Quality Checks

- **Linting**: Run appropriate linters based on file types modified:
  - Terraform/OpenTofu: `tofu fmt` to format code
  - Ansible: Run `ansible-lint` on modified playbooks
  - Shell scripts: Ensure `shellcheck` passes
  - YAML/Markdown: Run appropriate linters from MegaLinter

- **Pre-commit Checks**: Run pre-commit hooks to automate validation
  ```bash
  pre-commit run --all-files
  ```

### 2. Testing

- **Infrastructure Changes**:
  - Always run `plan` operations before `apply` to review changes
  ```bash
  ./infra-deploy.sh <component> plan
  ```
  - For DNS changes, test resolution after application
  ```bash
  dig api.github.com @<DNS_IP> +short
  ```

- **Service Changes**:
  - Test service deployment in isolation first
  ```bash
  ./services-pkgx-deploy.sh <service-name>-only
  ```
  - Verify the service is operational

### 3. Documentation

- Update relevant README files for changes to:
  - User-facing functionality
  - Deployment procedures
  - Configuration options
  - Prerequisites or dependencies

- Ensure example files are updated if configuration formats change:
  - `*.example.yml` for Ansible variables
  - `*.example.tfvars` for Terraform variables
  - `*.example.tfbackend` for backend configurations

### 4. Deployment

- **Test in Isolation**: Always test changes to a component in isolation first
- **Integration Testing**: Test how changes interact with other components
- **Full Deployment**: For comprehensive changes, run complete deployments

### 5. Security Considerations

- **Sensitive Information**: Ensure any sensitive data is properly encrypted with git-crypt
- **Example Files**: Make sure example files do not contain actual secrets
- **🚨 COMMIT MESSAGE SECURITY**: Review every commit message for private information exposure
- **🔐 GIT-CRYPT VERIFICATION**: Before adding sensitive data, verify file is git-crypt protected:
  ```bash
  # Check if file pattern is in .gitattributes with git-crypt filter
  grep "filter=git-crypt" .gitattributes
  
  # Verify git-crypt status of files
  git-crypt status
  
  # If file should be protected but isn't, add pattern to .gitattributes:
  echo "path/to/sensitive/file filter=git-crypt diff=git-crypt" >> .gitattributes
  ```

### 6. Commit and Push

- **🔒 SECURITY REVIEW**: Check commit message for private information exposure
- **Pre-push Checks**: The pre-push hook runs the full MegaLinter suite
- **CI/CD**: After pushing, monitor the Gitea Actions workflows for successful execution

## New Service Creation Checklist

When adding a new Ansible service role, ensure ALL of the following integration points are updated:

### Required Files for New Service
- [ ] `services/<service-name>/defaults/main.yml` - Default configuration
- [ ] `services/<service-name>/tasks/main.yml` - Main installation tasks
- [ ] `services/<service-name>/handlers/main.yml` - Service handlers
- [ ] `services/<service-name>/meta/main.yml` - Role metadata
- [ ] `services/<service-name>/vars/main.yml` - Internal variables (if needed)
- [ ] `services/<service-name>/templates/` - Configuration templates (if needed)
- [ ] `services/<service-name>/main.yml` - Standalone deployment playbook
- [ ] `services/<service-name>/test-playbook.yml` - Service test playbook
- [ ] `services/<service-name>/tasks/test.yml` - Test validation tasks
- [ ] `services/<service-name>/README.md` - Service documentation

### Required Integration Updates
- [ ] **`services/infrastructure.yml`** - Add role to main infrastructure playbook:
  - Add `_run_<service>` variable to pre_tasks set_fact
  - Add role entry with conditional execution
- [ ] **`services/infrastructure-test.yml`** - Add test playbook import:
  - Add `import_playbook: <service-name>/test-playbook.yml`
- [ ] **`services/inventory.example.yml`** - Add example configuration for the service

### Testing Requirements
- [ ] Standalone service test: `./services-pkgx-deploy.sh <service-name>/test-playbook.yml`
- [ ] Full infrastructure test: `./services-pkgx-deploy.sh infrastructure-test.yml`
- [ ] Isolated deployment test: `./services-pkgx-deploy.sh <service-name>/main.yml`

### Documentation Requirements
- [ ] Service-specific README with configuration examples
- [ ] Update main project documentation if the service adds new capabilities
- [ ] Ensure inventory examples demonstrate proper service configuration

### 🔒 Security Requirements for New Services
- [ ] **No private information** in any service files
- [ ] **Generic examples** in documentation and README files
- [ ] **Template variables** used instead of hardcoded values
- [ ] **Example configurations** use placeholder domains and IPs

## Code Style Standards

### Terraform/OpenTofu

- Code is automatically formatted with `tofu fmt`
- A pre-commit hook ensures all Terraform/OpenTofu code is properly formatted

### YAML Files

- YAML files are linted with yamllint through MegaLinter
- Proper indentation and structure are enforced

### Ansible

- Ansible code follows best practices enforced by ansible-lint
- Loop variables should be prefixed with `item_`, `element_`, or `member_`
- Default rules from ansible-lint are used without skipping

### Shell Scripts

- Shell scripts are linted with shellcheck
- All shell scripts use `#!/bin/bash` shebang
- Some shellcheck rules are disabled inline where appropriate (e.g., `# shellcheck disable=SC2154`)

### Markdown

- Markdown files are linted with markdownlint
- Proper headings, lists, and formatting are enforced

## Common Commands Reference

### Infrastructure Deployment

```bash
# Deploy infrastructure with pkgx dependency management
./pkgx-deploy.sh

# Deploy specific DNS component with plan action
./infra-deploy.sh dns-ha plan

# Deploy Pi-hole with specific variables and backend config
./infra-deploy.sh pihole apply -- -var-file=blue.tfvars -backend-config=blue-config.s3.tfbackend

# For blue/green DNS deployments
cd infrastructure/dns/pihole
./tofu-ns.sh blue apply
./tofu-ns.sh green apply
```

### Services Deployment

```bash
# Deploy all services with default playbook
./services-pkgx-deploy.sh

# Deploy specific service
./services-pkgx-deploy.sh drone-only

# Deploy with custom options
./services-pkgx-deploy.sh --playbook=services/specific-playbook.yml --inventory=services/custom-inventory.yml

# Run Ansible playbook directly
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i services/inventory.yml services/gitea-only.yml
```

### Dependency Management

```bash
# Setup Ansible environment
./setup-ansible.sh

# Install pkgx (if not already installed)
curl -fsS https://pkgx.sh | sh
```

### Testing

```bash
# Test DNS resolution
dig api.github.com @<DNS_IP> +short

# Verify installations
nvidia-smi       # Check NVIDIA driver installation
nvcc --version   # Check CUDA compiler version
ollama --version # Check Ollama version
btop --version   # Check btop system monitor version
```

### Git Workflow

```bash
# Initialize git-crypt for secret management
git-crypt init

# Add a user to the git-crypt keyring
git-crypt add-gpg-user USER_ID

# Run pre-commit checks manually
pre-commit run --all-files
```

### Code Quality

```bash
# Run MegaLinter with fixes
mega-linter-runner --fix

# Run OpenTofu fmt on all Terraform files
tofu fmt -recursive infrastructure/

# Run ansible-lint on a specific playbook
ansible-lint services/specific-playbook.yml
```
