# Publishing Checklist: Active Directory Extras (Community Fork)

Follow this in order. Nothing here is legally required beyond the GPLv2
attribution step, but skipping the transparency/community steps is what
gets forks flagged, blacklisted, or resented by the userbase.

---

## Phase 1 — Legal / attribution prep

- [ ] Confirm the archive is GPLv2 (`LICENSE.md` inside the `.tgz` already
      confirms this — copy it into the new repo unmodified).
- [ ] Keep Dan Landon's original copyright notice intact in every file that
      contains his original code. Add your own copyright line *underneath*
      it for your changes — don't replace his.
- [ ] Do not reuse his icon (`activedirectoryextras.png`) if you're
      rebranding the fork name — a distinct icon avoids visual confusion in
      the Plugins list. Reusing it as-is is legally fine (GPLv2) but adds to
      the "is this the same thing?" confusion you're trying to avoid.

## Phase 2 — Repo setup

- [ ] Create a new GitHub repo. Suggested naming: avoid an exact collision
      with `active.directory` — e.g. `active.directory.extras.community`,
      `<yourhandle>-active-directory-extras`, or similar. CA moderators
      actively deduplicate near-identical plugin names (see precedent in
      their moderation database for other dlandon-adjacent forks).
- [ ] Push the extracted plugin contents (`active.directory/...` folder
      structure) plus the new `README.md`, `CHANGES.md`, and `LICENSE.md`
      at repo root.
- [ ] Tag a release matching the version in your updated `.plg`.

## Phase 3 — Rewrite the `.plg` manifest

- [ ] Update `<!ENTITY name ...>` if you renamed it, and every place
      `&name;` propagates (paths, filenames).
- [ ] Update `<!ENTITY author ...>` to reflect fork maintainership — don't
      leave it claiming `dlandon` as the current maintainer.
- [ ] Update `gitURL` / `pluginURL` to point at your new repo's raw URLs.
- [ ] Update `supportURL` to your **new** forum thread (Phase 5), not the
      old silent one.
- [ ] Replace the `<MD5>` entity with a `<SHA256>` entity (Unraid's plugin
      installer supports both — SHA256 is the better practice going
      forward). Recompute it against your repackaged `.tgz`:
      ```bash
      sha256sum active.directory-<version>.tgz
      ```
- [ ] Add a `min=` **and** `max=`/`MaxVer` compatibility bound once you've
      tested against current Unraid — don't leave it open-ended.
- [ ] Add a new `<CHANGES>` entry documenting the fork itself, e.g.:
      ```
      ###2026.XX.XX
      - Fork: Continued as community fork after upstream repository was
        removed and author became unresponsive. See README for details.
      ```

## Phase 4 — Test before publishing

- [ ] Install via `installplg <path-to-local-.plg>` on a spare Unraid box
      or VM — **not** production — and confirm:
  - Plugin installs cleanly
  - Settings page renders under Settings → SMB with AD selected
  - Apply/Default/Clear Cache buttons all work
  - A reboot correctly backs up and restores the `.tdb` files
  - Uninstall removes plugin files but leaves your `.cfg` and `database/`
    backups intact (matches current behavior — confirm you haven't
    regressed this)
- [ ] Run `shellcheck` on all `.sh`/`rc.*` files and `php -l` on the PHP.

## Phase 5 — One-time notice in the original thread

Post **once** in the original "Active Directory Extras" support thread,
then don't belabor it there. Draft text:

> Since there's been no response here regarding the plugin's status, and
> the original GitHub repository has been removed, I've forked it to keep
> it working on current Unraid: **[link]**. All credit for the original
> work goes to dlandon — this is just to keep it maintained. Happy to hand
> this back if the original project resumes.

## Phase 6 — Start a new support thread

- [ ] Create a new thread in the Unraid **Plugin Support** forum for your
      fork, using your fork's actual name so it's discoverable and not
      confused with the original.
- [ ] Link it in your `.plg`'s `supportURL` and in `README.md`.

## Phase 7 — Community Applications submission

- [ ] Read CA's submission help and go through
      `ca.unraid.net/submit`.
- [ ] Before/during submission, proactively flag the situation to CA
      moderators (they maintain `Moderation.json` in the
      `Squidly271/Community-Applications-Moderators` repo) — explain it's a
      fork of an orphaned plugin, link both repos, and let them decide
      whether to mark the original `Deprecated`/`RemoveFromCA` in their
      moderation data pointing at yours. This is exactly the kind of
      succession they already handle for other authors' abandoned plugins.

## Phase 8 — Ongoing maintenance

- [ ] Add a GitHub Action running `shellcheck` + `php -l` on push/PR.
- [ ] Keep `CHANGES.md` and the `.plg`'s `<CHANGES>` block in sync.
- [ ] Re-test against new Unraid releases (especially major WebGUI
      revisions) before bumping `MaxVer`.
