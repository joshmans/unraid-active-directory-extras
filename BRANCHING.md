# Branching Workflow

One branch per bug/enhancement from `docs/AI_REFACTOR_BRIEF.md`, one PR per
branch, nothing lands on `main` unreviewed — especially since a lot of this
content will originate from a local LLM rather than your own hands.

## Standard cycle (repeat per item)

```bash
# 1. Start from an up-to-date main
git checkout main
git pull

# 2. Create the branch (see naming table below)
git checkout -b <branch-name>

# 3. Make/apply the change (paste in what your model generated,
#    or edit directly)

# 4. Stage only the file(s) relevant to this fix — don't sweep in
#    unrelated changes
git add <path/to/file>
git status                     # confirm only the intended file(s) are staged

# 5. Commit with a message matching the brief's changelog format
git commit -m "<type>: <short description>"

# 6. Push and open a PR against main
git push -u origin <branch-name>
gh pr create --fill

# 7. Review the PR diff on GitHub (or via `gh pr diff`) before merging —
#    this is the actual review step, don't skip it just because you're
#    the only contributor

# 8. Merge and clean up
gh pr merge --squash --delete-branch
```

Quick diff review without leaving the terminal, if you'd rather not open
the browser each time:

```bash
gh pr diff
```

---

## Branch reference — Bugs (Section 4 of the brief)

| # | Branch name | File(s) touched | Commit message |
|---|---|---|---|
| 1 | `fix/tdb-retention-per-file` | `active.directory/scripts/rc.cleanup` | `Fix: Per-file TDB backup retention instead of global retention` |
| 2 | `fix/backup-restore-atomicity` | `active.directory/scripts/rc.shutdown`, `rc.startup` | `Fix: Atomic staging for TDB backup and restore` |
| 3 | `fix/tdb-corruption-check` | `active.directory/scripts/rc.startup` | `Fix: Validate TDB integrity before restoring, fall back to older generation` |
| 4 | `fix/apply-settings-error-surfacing` | `active.directory/scripts/rc.active.directory`, `active.directory/ActiveDirectory.page` | `Fix: Surface apply_settings() failures to the GUI instead of failing silently` |

## Branch reference — Enhancements (Section 5 of the brief)

| # | Branch name | File(s) touched | Commit message |
|---|---|---|---|
| 1 | `feat/ldap-backend-cleanup` | `active.directory/ActiveDirectory.page` | `Change: Remove incomplete LDAP idmap option from Backend Database dropdown` |
| 2 | `feat/domain-range-fields` | `active.directory/ActiveDirectory.page`, `active.directory/scripts/rc.active.directory` | `Add: Enable and validate Domain Range / Backend Range fields` |
| 3 | `feat/ad-join-status` | `active.directory/ActiveDirectory.page`, `active.directory/scripts/rc.active.directory` | `Add: Live AD join status via wbinfo/net ads testjoin` |
| 4 | `feat/clear-cache-confirm` | `active.directory/ActiveDirectory.page` | `Add: Confirmation dialog before Clear Cache (drops SMB connections)` |
| 5 | `chore/sha256-plg` | `active.directory.plg` | `Change: Use SHA256 instead of MD5 for package integrity check` |
| 6 | `feat/configurable-backup-path` | `active.directory/scripts/rc.startup`, `rc.shutdown`, `ActiveDirectory.page` | `Add: Configurable TDB backup destination (flash vs array/cache)` |

## Branch reference — Fork setup itself (not from the brief)

| Branch name | File(s) touched | Commit message |
|---|---|---|
| `chore/plg-rebrand` | `active.directory.plg` | `Change: Update plg entities for fork (author, gitURL, supportURL, name)` |
| `chore/shellcheck-ci` | `.github/workflows/lint.yml` (new) | `Add: CI lint step (shellcheck + php -l)` |

---

## Notes

- Do the bugs before the enhancements — several enhancements (e.g. #2, #3)
  touch the same functions the bug fixes (#1, #4) modify. Merging bug
  fixes first keeps enhancement branches based on the corrected code
  instead of forking off something you're about to change underneath them.
- If a branch touches the same file as an already-open, unmerged branch,
  rebase onto `main` after the first one merges rather than resolving a
  conflict blind:
  ```bash
  git checkout <second-branch>
  git rebase main
  ```
- Tag a release once a meaningful batch has merged (e.g. all 4 bug fixes),
  matching Phase 2 of `docs/PUBLISHING_CHECKLIST.md`:
  ```bash
  git tag -a v1.0.1 -m "Bug fixes: TDB retention, atomicity, corruption check, error surfacing"
  git push origin v1.0.1
  ```
