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
- Installs Whisper ASR Webservice with NVIDIA GPU acceleration
- Installs Open WebUI with NVIDIA GPU acceleration
- Installs Watchtower for automatic container updates using beatkind/watchtower fork

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
- `tasks/whisper_asr.yml` - Installs and configures Whisper ASR Webservice
- `tasks/open_webui.yml` - Installs and configures Open WebUI
- `tasks/watchtower.yml` - Installs and configures Watchtower for automatic container updates

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
- `install_whisper_asr` - Whether to install Whisper ASR Webservice
- `install_open_webui` - Whether to install Open WebUI
- `install_watchtower` - Whether to install Watchtower for automatic container updates
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
docker ps | grep whisper  # Should show running Whisper ASR container
docker ps | grep open-webui  # Should show running Open WebUI container
docker ps | grep watchtower  # Should show running Watchtower container
```

### n8n AI Workflow Platform

After installation, access the n8n web interface at `http://localhost:5678/` (or the host/port configured in the variables). The platform includes:

- n8n workflow automation with AI capabilities
- Integration with system-installed Ollama for local LLM execution
- Qdrant vector database for embedding storage
- PostgreSQL for data storage
- Shared folder at `/opt/n8n-ai-starter-kit/data/shared` (configurable)

This implementation uses the system-wide Ollama service installed by the `ollama.yml` task, avoiding port conflicts and duplicating services.

### Whisper ASR Webservice

After installation, access the Whisper ASR API at `http://localhost:9000/` (or the host/port configured in the variables). The service provides:

- OpenAI-compatible Whisper API for automatic speech recognition
- GPU acceleration for faster transcription when NVIDIA drivers are installed
- Support for multiple Whisper model sizes (tiny, base, small, medium, large, large-v3)
- Uses faster-whisper for improved performance
- Data directory at `/opt/whisper-asr/data` (configurable) for persistent storage

The service automatically detects if GPU support is available and uses the appropriate compute type (float16 for GPU, int8 for CPU).

### Open WebUI

After installation, access the Open WebUI interface at `http://localhost:3000/` (or the host/port configured in the variables). The service provides:

- Modern web interface for interacting with Ollama models
- GPU acceleration for faster inference when NVIDIA drivers are installed
- Integration with local Ollama installation
- User management and conversation history

### Watchtower

This playbook installs the [beatkind/watchtower](https://github.com/beatkind/watchtower) fork, which automatically updates running Docker containers when new image versions are available. Key features:

- Automatic container updates based on schedule or polling interval
- Optional cleanup of old images to save disk space
- Support for label-based monitoring (only update containers with specific labels)
- Rolling updates to minimize service disruption
- Pushover notifications for update events

The service is configured with docker-compose and set to run daily at 4 AM by default, or at a specified interval. Container-specific update flags allow you to control which services get automatically updated:

```yaml
# Container update flags
watchtower_update_n8n: true              # Update n8n container
watchtower_update_postgres: false         # Don't update PostgreSQL container
watchtower_update_qdrant: true           # Update Qdrant container
watchtower_update_whisper_asr: true      # Update Whisper ASR container
watchtower_update_open_webui: true       # Update Open WebUI container
```

These flags add the appropriate labels to containers to enable or disable automatic updates. This is especially useful for database containers like PostgreSQL where updates should be performed manually with proper data migration.
