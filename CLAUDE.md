# CLAUDE.md - AI Assistant Guide for Impossibles Repository

## Repository Overview

**Repository Name:** impossibles
**License:** GNU General Public License v3.0
**Current Status:** Early stage / Minimal codebase
**Last Updated:** 2025-11-14

### Purpose
This is a minimal repository currently in its initial stages. The repository name "impossibles" suggests it may be intended for projects that tackle challenging or "impossible" problems, though the specific purpose has not yet been defined through code or documentation.

## Current Repository Structure

```
impossibles/
├── LICENSE          # GNU GPL v3.0 license file
├── koe              # Test file with minimal content
├── .git/            # Git repository metadata
└── CLAUDE.md        # This file - AI assistant guide
```

### Existing Files

1. **LICENSE** (line count: 675)
   - Standard GNU General Public License Version 3
   - All code in this repository is open source under GPL v3.0 terms
   - Contributors must comply with GPL v3.0 requirements

2. **koe** (line count: 3)
   - Simple test file containing placeholder text
   - No apparent functional purpose yet
   - May be used for testing git operations

## Git Workflow

### Branch Strategy

**Current Branch:** `claude/claude-md-mhyn7s5joa1gs22w-01USRL2Zu3hcgqXvwP1CYmZa`

This repository uses feature branches with the following convention:
- Format: `claude/<descriptive-name>-<session-id>`
- All AI assistant work should be done on designated feature branches
- NEVER push directly to main/master without explicit permission

### Commit History

```
ceea8ff - Create koe
ad95529 - Initial commit
```

The repository has minimal commit history, indicating it's in early development.

### Git Best Practices

1. **Commits:**
   - Write clear, descriptive commit messages
   - Use conventional commit format when possible (feat:, fix:, docs:, etc.)
   - Keep commits focused on single logical changes

2. **Pushing:**
   - Always use: `git push -u origin <branch-name>`
   - Branch names must start with 'claude/' and include session ID
   - Retry network failures up to 4 times with exponential backoff (2s, 4s, 8s, 16s)

3. **Pulling/Fetching:**
   - Prefer specific branch fetches: `git fetch origin <branch-name>`
   - Use retry logic for network failures

## Development Conventions

### Code Standards

Since this is an early-stage repository, the following conventions should be established:

1. **Language Choice:** Not yet determined - to be established with first substantial code
2. **Code Style:** Follow language-specific best practices once language is chosen
3. **Testing:** Implement tests for all new functionality
4. **Documentation:** Maintain inline comments and update this CLAUDE.md

### File Organization

When the project grows, consider this structure:

```
impossibles/
├── src/              # Source code
├── tests/            # Test files
├── docs/             # Documentation
├── examples/         # Usage examples
├── scripts/          # Build/utility scripts
├── .gitignore        # Git ignore rules
├── README.md         # Project documentation
├── LICENSE           # License file (exists)
├── CLAUDE.md         # AI assistant guide (this file)
└── [config files]    # Language/framework specific configs
```

### Dependencies

Currently, there are no dependencies. When adding dependencies:

1. Use a dependency management file (package.json, requirements.txt, Cargo.toml, etc.)
2. Document all dependencies and their purposes
3. Pin versions for reproducibility
4. Keep dependencies up to date and audit for security

## Development Workflow for AI Assistants

### Initial Setup

1. Verify you're on the correct feature branch
2. Check git status to understand current state
3. Review recent commits to understand recent changes
4. Read existing code before making modifications

### Making Changes

1. **Plan First:**
   - Use TodoWrite tool to track multi-step tasks
   - Break down complex changes into manageable steps
   - Mark tasks as in_progress/completed as you work

2. **Code Development:**
   - Always read files before editing
   - Use Edit tool for modifications, not Bash commands
   - Test changes before committing
   - Ensure no security vulnerabilities (SQL injection, XSS, command injection, etc.)

3. **Committing:**
   - Stage relevant files only
   - Write descriptive commit messages
   - Do not commit secrets, credentials, or .env files
   - Follow the git commit workflow documented above

4. **Pushing:**
   - Push to the designated feature branch
   - Never force push to main/master
   - Verify push succeeds

### Communication

1. Be concise and direct in responses
2. Use markdown for formatting
3. Reference code locations as `file_path:line_number`
4. Don't use excessive praise or emojis unless requested

## Project-Specific Guidelines

### Current State

- **Maturity Level:** Very early / bootstrapping phase
- **Active Development:** Repository structure being established
- **Documentation:** CLAUDE.md created, README.md needed
- **Testing:** No test framework established yet

### Immediate Next Steps (Recommendations)

1. Create README.md with project description and goals
2. Add .gitignore for common ignore patterns
3. Define the project's purpose and scope
4. Choose primary programming language(s)
5. Set up basic project structure
6. Implement initial functionality
7. Add testing framework
8. Set up CI/CD pipeline

### When Adding New Features

1. **Research:** Understand existing codebase patterns
2. **Design:** Plan the feature architecture
3. **Implement:** Write clean, well-documented code
4. **Test:** Add unit tests and integration tests
5. **Document:** Update relevant documentation
6. **Review:** Check for security issues and code quality
7. **Commit:** Create clear, atomic commits

### Security Considerations

1. Never commit sensitive information (API keys, passwords, tokens)
2. Validate all inputs
3. Use parameterized queries for database operations
4. Sanitize user input to prevent XSS
5. Follow OWASP Top 10 guidelines
6. Keep dependencies updated
7. Use secure defaults

## Tools and Resources

### Available Tools

When working on this repository, AI assistants have access to:

- **File Operations:** Read, Write, Edit, Glob
- **Search:** Grep for code search
- **Execution:** Bash for running commands
- **Version Control:** Git operations via Bash
- **Web:** WebFetch for documentation, WebSearch for research
- **Planning:** TodoWrite for task management
- **Agents:** Task tool for complex, multi-step operations

### Best Practices

1. Use specialized tools instead of bash when possible
2. Run independent commands in parallel for efficiency
3. Use Task tool with Explore agent for codebase exploration
4. Always verify file paths exist before operations
5. Quote file paths with spaces

## Troubleshooting

### Common Issues

1. **Git Push Failures:**
   - Verify branch name matches required format (claude/*)
   - Check network connectivity
   - Retry with exponential backoff
   - Ensure you have proper permissions

2. **File Not Found:**
   - Use Glob to verify file existence
   - Check working directory
   - Verify file paths are absolute

3. **Merge Conflicts:**
   - Fetch latest changes from remote
   - Resolve conflicts manually
   - Test after resolution
   - Commit with clear message

## Future Considerations

As the project grows, consider adding:

1. **README.md** - Comprehensive project documentation
2. **CONTRIBUTING.md** - Contribution guidelines
3. **CHANGELOG.md** - Version history and changes
4. **.github/** - GitHub-specific templates and workflows
5. **CI/CD** - Automated testing and deployment
6. **Code Coverage** - Track test coverage metrics
7. **Linting** - Automated code style enforcement
8. **Pre-commit Hooks** - Prevent common mistakes

## Remote Repository

**Origin:** `http://local_proxy@127.0.0.1:29035/git/gitnuutti/impossibles`

This appears to be a local or development proxy setup. Verify remote access when needed.

## Notes for AI Assistants

1. This repository is in very early stages
2. No established codebase patterns exist yet
3. First real features will set the foundation
4. Be thoughtful about architectural decisions
5. Establish good practices from the start
6. Keep this document updated as project evolves

## Questions or Issues?

When working on this repository:

1. If unclear about requirements, ask the user for clarification
2. If you encounter errors, investigate before asking
3. If making significant architectural decisions, discuss with user
4. Keep user informed of progress via TodoWrite

---

**Last Updated:** 2025-11-14
**Repository Status:** Initializing
**Next Update:** After first major feature implementation
