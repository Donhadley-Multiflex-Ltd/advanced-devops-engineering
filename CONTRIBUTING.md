# Contributing

We welcome contributions to this project! Whether you're fixing bugs, adding new features, or improving documentation, your help is greatly appreciated.

## Getting Started

To get started, please follow these steps:

1. Fork the repository and clone it to your local machine.
2. Create a new branch for your feature or bug fix: `git switch -c feat/description`.
3. Read `README.md` for repository-specific prerequisites.
4. Copy `.env.example` to `.env` when the repository provides one, then supply development-safe values. DO NOT REUSE production secrets.
5. Make your changes and commit them with clear and descriptive messages.
6. Run `make help` to discover the supported setup, development, lint, and test targets, then run the targets relevant to your change.

## Repository Layout

The repository is organized as follows:

```
├── .github/             # GitHub-specific files (workflows, pull request/issue templates, etc.)
├── api/                 # Application Backend
|── deploy/              # Cloud Deployment (Infra,Ansible,Container,Orchestration,GitOps, etc.)
├── docs/                # Documentation files
├── web/                 # Application Frontend
├── runbooks/            # Operational Guidelines
├── scripts/             # Ad-hoc automation/boostrapping bash scripts and local hooks.
├── .env.example         # Example environment variables file
├── .gitignore           # Git ignore file
├── LICENSE              # License file
├── Makefile             # Makefile for build and development tasks
├── README.md            # Project overview and setup instructions
```

## Commit Messages

When committing changes, please follow these guidelines for commit messages:

- Use [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
- Use the present tense ("Add feature" not "Added feature").
- Use the imperative mood ("Fix bug" not "Fixed bug").

## Before opening a pull request

- Run the relevant lint and tests for the area you changed.
- Do **not** commit secrets, credentials, or `.env` files.
- Fill out the pull request template and link any related issues.
- Keep PRs focused; smaller PRs review faster.

## Code review

At least one approving review from a [CODEOWNER](/CODEOWNERS) is required before
merge. Be responsive to review feedback.
