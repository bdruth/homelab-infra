# Workflow and Standards

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

### 6. Commit and Push

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