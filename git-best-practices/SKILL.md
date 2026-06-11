# git-best-practices

Use this skill whenever working with Git in any project. Covers the full development workflow: branch naming conventions, commit message standards (Conventional Commits), feature branch flow, PR creation and merging, hotfix flow, and conflict resolution.

Activate this skill when:
- Creating a new branch (feature, fix, hotfix, refactor, chore, docs, test)
- Writing or reviewing a commit message
- Opening or reviewing a pull request
- Merging branches (squash, merge commit, rebase)
- Resolving merge or rebase conflicts
- Asking how to structure Git workflow for a task
- Asking about branch naming, commit format, or PR description
- Syncing a branch with main or develop via rebase
- Cleaning up branches after merge
- Any question involving `git checkout`, `git commit`, `git merge`, `git rebase`, `git push`, `git branch`, or `git PR`

This skill applies globally to all projects. If the project's CLAUDE.md defines specific branch or commit conventions, those take priority over this skill.

---

## Branch Naming

### Format
```
<type>/<short-description>
```

### Types
| Type | When to use |
|------|-------------|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `hotfix/` | Urgent production fix |
| `refactor/` | Code restructuring, no behavior change |
| `chore/` | Maintenance, deps, config |
| `docs/` | Documentation only |
| `test/` | Adding or fixing tests |

### Rules
- Use **kebab-case** (lowercase, hyphens)
- Be descriptive but concise (3-5 words max)
- No special characters except `-` and `/`

### Examples
```
feature/user-authentication
fix/null-pointer-login
hotfix/payment-gateway-timeout
refactor/order-service-cleanup
chore/update-spring-dependencies
docs/api-endpoints
```

### Project-specific override
If the project's CLAUDE.md defines a branch convention (e.g. `feature/<TICKET-ID>/<author>`), that takes priority over this skill.

---

## Commit Messages

### Format (Conventional Commits)
```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### Types
| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Refactoring |
| `chore` | Maintenance, deps |
| `docs` | Documentation |
| `test` | Tests |
| `style` | Formatting, no logic change |
| `perf` | Performance improvement |
| `ci` | CI/CD changes |
| `revert` | Reverts a previous commit |

### Rules
- Subject line: max **72 characters**
- Use **imperative mood**: "add feature" not "added feature"
- No period at the end of subject
- Scope is optional but recommended
- Body explains **what and why**, not how

### Examples
```
feat(auth): add JWT refresh token endpoint

fix(catalog): resolve null price on out-of-stock items

refactor(order-service): extract payment logic to dedicated class

chore(deps): upgrade Spring Boot to 3.4.2

docs(api): add endpoint descriptions to OpenAPI spec
```

### Bad commits to avoid
```
❌ fix bug
❌ changes
❌ WIP
❌ updated stuff
❌ asdfgh
```

---

## Complete Git Workflow

### Starting a new feature

```bash
# Always branch from the latest main/develop
git checkout main
git pull origin main
git checkout -b feature/my-new-feature
```

### During development

```bash
# Check status frequently
git status

# Stage only related changes (avoid git add .)
git add src/specific/file.java

# Commit in small, logical units
git commit -m "feat(module): add specific behavior"

# Keep branch up to date with main
git fetch origin
git rebase origin/main
```

### Before opening a PR

```bash
# Make sure tests pass
# Review your own diff
git diff origin/main

# Clean up commit history if needed
git rebase -i origin/main
```

### Opening a PR

PR title should follow the same Conventional Commits format:
```
feat(auth): add JWT refresh token endpoint
```

PR description should include:
- **What** was changed and **why**
- How to test it
- Screenshots if UI change
- Reference to ticket/issue if applicable

### Merging

Preferred strategy: **Squash and merge** for feature branches (keeps main history clean).

Use **Merge commit** only when preserving full history is important (e.g. long-lived release branches).

Never merge directly to `main` without a PR review.

### After merging

```bash
# Delete local branch
git branch -d feature/my-new-feature

# Delete remote branch
git push origin --delete feature/my-new-feature

# Update local main
git checkout main
git pull origin main
```

---

## Hotfix Flow

```bash
# Branch from main (not develop)
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug-description

# Fix, commit, push
git commit -m "hotfix(module): fix critical issue description"
git push origin hotfix/critical-bug-description

# Open PR to main
# After merge, also merge main back into develop
git checkout develop
git merge main
```

---

## Conflict Resolution

```bash
# See which files have conflicts
git status

# After manually resolving conflicts in each file
git add src/resolved/file.java

# Continue rebase or merge
git rebase --continue
# or
git merge --continue

# If things go wrong, abort and start over
git rebase --abort
git merge --abort
```

### Rules for conflict resolution
- Never blindly accept "ours" or "theirs" — understand both changes
- Run tests after resolving before committing
- If unsure about a conflict, ask the author of the conflicting code

---

## General Rules

- **Never force push to main or develop**
- **Never commit secrets**, API keys, passwords, or `.env` files
- Keep `.gitignore` updated before first commit
- One logical change per commit
- A branch should be short-lived (days, not weeks)
- If a branch lives too long, sync with main via rebase frequently
