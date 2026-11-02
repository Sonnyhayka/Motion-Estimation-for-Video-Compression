
---
description: git commit, update changelog, and push
subtask: true
---

Commit and push the changes, updating CHANGELOG.md first.

## Commit Message Rules

Use `type(scope): summary` with one of these types:
- `feat`: New functionality
- `fix`: Bug fixes
- `docs`: Documentation updates
- `chore`: Maintenance or configuration
- `refactor`: Code restructuring without behavior changes
- `test`: Test additions or modifications

The scope is optional.

Prefer to explain WHY something was done from an end-user perspective instead of WHAT was done.

Avoid generic messages like "improved agent experience". Be specific about what user-facing changes were made and why they matter.

Examples:
- Bad: `feat: improve website`
- Good: `feat(portfolio): help visitors explore projects by category`
- Bad: `fix: update navigation`
- Good: `fix(nav): prevent mobile menu from covering page content`

## Workflow

### 1. Review Changes

Review all staged and unstaged changes using the provided git context.

Understand:
- What functionality was added, fixed, or removed
- Why the changes were necessary
- How users or developers benefit
- Which changes should appear in the changelog

Do not invent features, fixes, or benefits.

### 2. Check for Conflicts

Check for unresolved merge conflicts before modifying files.

If conflicts exist:
- STOP immediately.
- DO NOT fix or resolve conflicts.
- DO NOT commit or push.
- Notify the user about the conflicting files.

### 3. Update CHANGELOG.md

Before committing, update `CHANGELOG.md` based on the actual changes.

Rules:
- If `CHANGELOG.md` exists, preserve its existing structure and formatting.
- If it does not exist, create one using the Keep a Changelog format.
- Add new changes under an `Unreleased` section.
- Create the `Unreleased` section if necessary.
- Categorize entries under `Added`, `Changed`, `Fixed`, or `Removed` when appropriate.
- Write concise, specific descriptions explaining the purpose or benefit of each change.
- Focus on user-facing impact whenever possible.
- Do not include irrelevant implementation details.
- Do not duplicate existing entries.
- Do not overwrite previous release history.
- If there are no meaningful changes to document, do not create an unnecessary changelog entry.

Example:

## [Unreleased]

### Added
- Added project filtering so visitors can find relevant engineering projects faster.

### Fixed
- Fixed mobile navigation overlapping content on smaller screens.

### Changed
- Updated project descriptions to make technical contributions easier for recruiters to understand.

### 4. Stage and Commit

After updating the changelog:

1. Review the final diff.
2. Stage the intended changes, including `CHANGELOG.md`.
3. Generate a conventional commit message from the actual diff.
4. Verify that no unresolved conflicts exist.
5. Commit the changes.

The commit message should summarize the main purpose of the changes, not simply state that the changelog was updated.

Do not create a commit if there are no changes.

### 5. Push

Push the committed changes to the current branch's configured upstream.

Rules:
- Do not force push.
- Do not automatically rebase or merge.
- If the push is rejected or conflicts occur, STOP.
- Notify the user and explain what needs manual attention.

### 6. Final Summary

After completion, report:
- Commit hash
- Commit message
- Branch pushed
- Summary of changes
- Whether `CHANGELOG.md` was updated

If any step fails, explain the issue without claiming success.

## GIT DIFF

!`git diff`

## GIT DIFF --cached

!`git diff --cached`

## GIT STATUS --short

!`git status --short`
