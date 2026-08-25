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

# 4. Update the changelog in the SAME branch, before opening the PR —
#    not as a follow-up commit after merging. Two files, same entry:
#
#    a) CHANGES.md — add a bullet under "## Unreleased"
#    b) active.directory.plg — add/extend a dated block in the
#       <CHANGES> entity near the top of the file
#
#    Use the exact commit message format from the table below for both —
#    keeps CHANGES.md, the .plg block, and the git log all saying the
#    same thing.

# 5. Stage only the file(s) relevant to this fix — don't sweep in
#    unrelated changes. This should now include CHANGES.md and
#    active.directory.plg alongside the actual code file(s).
git add <path/to/file> CHANGES.md active.directory.plg
git status                     # confirm only the intended file(s) are staged —
                                # this is the step that catches an accidental
                                # `git add .` sweeping in unrelated changes
                                # (see the TDB retention PR post-mortem below)

# 6. Commit with a message matching the brief's changelog format
git commit -m "<type>: <short description>"

# 7. Push and open a PR against main
git push -u origin <branch-name>
gh pr create --fill

# 8. Review the PR diff before merging — this is the actual review step,
#    don't skip it just because you're the only contributor. Check for:
#    - Correct content (does it actually do what the commit message says?)
#    - No unexpected `old mode`/`new mode` lines (executable bit lost —
#      common when copying script files out of chat downloads; fix with
#      `chmod +x` before committing)
#    - CHANGES.md and the .plg block are both present and match
gh pr diff

# 9. Merge and clean up
gh pr merge --squash --delete-branch

# 10. Sync local main before starting the next branch
git checkout main
git pull
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

## Post-mortems

**TDB retention fix (first real branch worked through this workflow):**
files were copied into `active.directory/scripts/` outside the branch
cycle (during earlier back-and-forth testing a local model's output)
before `fix/tdb-retention-per-file` was ever created. A `git status`
partway through showed "nothing to commit, working tree clean," which
looked alarming but turned out to be a stale read — the actual state
(files staged-but-uncommitted, only on the feature branch) only became
clear once `git status` / `git branch --show-current` / `git log --oneline
--all --graph` were run together, fresh, in one shot, rather than trusted
individually across several messages. Lesson: when git state seems
contradictory, re-run the three diagnostic commands together right before
acting, don't reason from output pasted a few steps earlier.

Separately, the executable bit was lost on `rc.shutdown`/`rc.startup`
when copying them in from a chat download (`chmod` doesn't survive a
plain file download) — caught via `old mode 100755` / `new mode 100644`
in `gh pr diff` before merging. Now called out explicitly in step 8 above.

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
