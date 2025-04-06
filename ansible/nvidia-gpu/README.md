# NVIDIA GPU Configuration Module

This Ansible module configures a system for AI/ML/CUDA workloads with NVIDIA GPU support.

## Features

- Installs NVIDIA drivers (version 570 by default, configurable)
- Configures CUDA toolkit and samples
- Sets up container runtime for GPU workloads
- Blacklists nouveau drivers for compatibility
- Configures thunderbolt eGPU support for external GPUs
- Installs essential development tools
- Installs latest docker-compose from GitHub
- Installs latest btop system monitor from GitHub
- Installs Ollama for running AI models locally
- Installs uv Python package manager and pipx
- Installs n8n AI workflow platform with NVIDIA GPU acceleration

## Requirements

- Ubuntu Noble (24.04)
- NVIDIA GPU compatible with driver version 570 (or other configured version)

## Module Structure

The module is organized into separate task files for better maintainability:

- `main.yml` - Main playbook that imports all task files
- `tasks/gpu_setup.yml` - Consolidated GPU-related tasks (driver, CUDA, repositories, eGPU)
- `tasks/packages.yml` - Installs base system packages
- `tasks/btop.yml` - Installs btop system monitor
- `tasks/ollama.yml` - Installs and configures Ollama
- `tasks/uv_manager.yml` - Installs uv Python package manager
- `tasks/n8n.yml` - Installs and configures n8n AI workflow platform

## Usage

1. Copy `vars/main.example.yml` to `vars/main.yml` and customize as needed
2. Create host_vars file for your specific GPU server
3. Run the playbook:

```bash
ansible-playbook -i your_inventory.yml main.yml
```

## Feature Toggles

Each major component can be enabled or disabled using variables:

- `nvidia_install_gpu_drivers` - Whether to install NVIDIA GPU drivers
- `nvidia_install_cuda_toolkit` - Whether to install CUDA toolkit
- `install_btop` - Whether to install btop
- `install_ollama` - Whether to install Ollama
- `install_uv` - Whether to install uv Python package manager
- `install_n8n` - Whether to install n8n AI workflow platform
- `install_docker_compose` - Whether to install latest docker-compose
- `nvidia_configure_egpu` - Whether to configure thunderbolt eGPU support

## Testing

To test the playbook on a local system:

```bash
ansible-playbook -i test-inventory.yml test-playbook.yml
```

## Variables

See `vars/main.example.yml` for all available configuration options.

## Validation

After running the playbook, verify installation with:

```bash
nvidia-smi  # Should display GPU information
nvcc --version  # Should display CUDA compiler version
docker-compose --version  # Should display docker-compose version
ollama --version  # Should display Ollama version
btop --version  # Should display btop version
uv --version  # Should display uv version
docker ps | grep n8n  # Should show running n8n containers
```

### n8n AI Workflow Platform

After installation, access the n8n web interface at `http://localhost:5678/` (or the host/port configured in the variables). The platform includes:

- n8n workflow automation with AI capabilities
- Integration with system-installed Ollama for local LLM execution
- Qdrant vector database for embedding storage
- PostgreSQL for data storage
- Shared folder at `/opt/n8n-ai-starter-kit/data/shared` (configurable)

This implementation uses the system-wide Ollama service installed by the `ollama.yml` task, avoiding port conflicts and duplicating services.
