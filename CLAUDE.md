# CLAUDE.md - Instructions for Claude Code

## IMPORTANT: FIRST READ THE MEMORY BANK

When working with this repository, Claude Code should ALWAYS start by reading all files in the `memory-bank/` directory using this specific hierarchy:

1. Start with `memory-bank/projectbrief.md` - Provides the foundation and core goals
2. Read `memory-bank/productContext.md` - Explains why this project exists and how it should work
3. Read `memory-bank/systemPatterns.md` - Details the system architecture and key technical decisions
4. Read `memory-bank/techContext.md` - Lists technologies used and detailed implementation guidance
5. Read `memory-bank/activeContext.md` - Shows what's currently being worked on and recent changes
6. Finish with `memory-bank/progress.md` - Provides current status and project evolution

## Using the Memory Bank Effectively

- The memory bank is the PRIMARY source of truth for all project standards and information
- All project documentation, patterns, commands, and standards have been incorporated into the memory bank
- Always reference memory bank files over this CLAUDE.md file when working on code
- Ensure your changes follow the patterns and standards documented in the memory bank
- If you need to modify standards, update the memory bank files, not this file

## Key Technical Concepts

This is just a brief overview pointing to the relevant memory bank files for details:

1. **Infrastructure as Code** - All changes are defined in Ansible and Terraform/OpenTofu
2. **Deployment Commands** - See `memory-bank/techContext.md` for all commands and usage
3. **Container Management** - We use podman with docker CLI syntax; see `memory-bank/techContext.md` for details
4. **Code Style** - Follow patterns in `memory-bank/systemPatterns.md` Development Standards section
5. **Monitoring** - See `memory-bank/systemPatterns.md` API Integration Patterns and Monitoring Solutions
6. **Network Configuration** - IPv4/IPv6 support details in `memory-bank/techContext.md`

## Current Project Priorities

See `memory-bank/activeContext.md` and `memory-bank/progress.md` for:

- Current work focus
- Recent changes
- Next steps
- Known issues
- Current status of components

## Updating the Memory Bank

When the user types **update memory bank**, this is a specific command that requires you to:

1. Review ALL memory bank files, even if some don't require updates
2. Focus particularly on `activeContext.md` and `progress.md` which track current state
3. Document the following in appropriate files:
   - Current state of the project
   - New project patterns discovered
   - Implementation changes made
   - Next steps and priorities
   - Any insights or learnings

The memory bank update process follows this sequence:

1. Review ALL Files
2. Document Current State
3. Clarify Next Steps
4. Document Insights & Patterns

Memory bank updates should occur when:

1. Discovering new project patterns
2. After implementing significant changes
3. When the user explicitly requests with **update memory bank**
4. When context needs clarification

Remember that after every memory reset, Claude Code begins completely fresh. The Memory Bank is the only link to previous work, so it must be maintained with precision and clarity.
