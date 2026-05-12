# Syncing the Homeserve mirror with upstream rtk-ai/rtk

This fork (`HomeserveFR/rtk`) is a macOS-only mirror of the upstream `rtk-ai/rtk`,
maintained for Homeserve security compliance. The branch `homeserve/main` carries
upstream `master` plus Homeserve-specific commits (e.g. SonarQube workflow).

Sync is **manual** — there is no scheduled automation. Pull upstream changes when
needed by following the procedure below.

## One-time setup

Add the upstream remote to your local clone:

```bash
git remote add upstream git@github.com:rtk-ai/rtk.git
git fetch upstream --tags
```

## Sync procedure

Always sync via a **squash merge PR**, never a regular merge. A regular merge
imports every upstream commit (including their conventional-commit subjects)
into the homeserve/main history, which confuses release-please into thinking
those upstream commits are new Homeserve work and triggers spurious version
bumps. A squash merge collapses the whole sync into a single commit whose
subject we control.

```bash
git checkout master
git fetch upstream
git pull --ff-only upstream master   # master tracks upstream/master verbatim

git push origin master
# Open a PR: HomeserveFR/rtk:master -> HomeserveFR/rtk:homeserve/main
# Resolve conflicts on the master branch (or a sync branch) as needed.
```

Likely conflict points — keep the Homeserve versions for:

- `.github/workflows/sonarqube.yml`
- `.github/workflows/cd.yml`
- `.github/workflows/release.yml`
- `install.sh`
- `Formula/rtk.rb`
- `README.md` (Installation section)
- `Cargo.toml` (repository field)

When the PR is mergeable, **merge it with the "Squash and merge" button**
and rewrite the commit subject to:

```
chore: sync upstream <vX.Y.Z>
```

The `chore:` prefix is ignored by release-please for version bumps, so the
sync alone will not trigger a release PR. After merge, bump the
`last-release-sha` value in `release-please-config.json` to the new
homeserve/main HEAD so release-please skips the imported upstream commits
in its analysis (only commits **after** that SHA are considered for
versioning):

```bash
git checkout homeserve/main && git pull
HEAD_SHA=$(git rev-parse HEAD)
# Edit release-please-config.json -> set "last-release-sha" to $HEAD_SHA
# Then commit on a branch and open a PR titled 'chore: bump release-please last-release-sha'
```

## Releasing after sync

1. After the push, GitHub Actions runs `cd.yml` → `release-please` job
2. release-please opens (or updates) a PR titled `chore(homeserve/main): release X.Y.Z`
3. Review the PR — verify the version bump and CHANGELOG entries make sense
4. Merge the release PR → triggers `release.yml` → builds 2 macOS binaries
5. The `latest` tag is force-updated by `update-latest-tag` job
6. End users running `install.sh` get the new version automatically

## Verification

After release publication:

```bash
gh release view --repo HomeserveFR/rtk
gh release list --repo HomeserveFR/rtk --limit 3
```

Expected assets in each release:

- `rtk-x86_64-apple-darwin.tar.gz`
- `rtk-aarch64-apple-darwin.tar.gz`
- `checksums.txt`

## Skipping a release

If you need to sync upstream code without releasing, close the release-please
PR without merging. Release-please will reopen it on the next push. To suppress
a release entirely for a given commit, prefix the commit subject with `chore:`
(release-please ignores `chore` for version bumps under default config).

## Recovering from a non-squash upstream sync

If a sync was merged as a regular merge commit (importing the full upstream
history), release-please will see all upstream conventional commits as new
work and may calculate an incorrect next version. To recover:

1. Note the current homeserve/main HEAD SHA: `git rev-parse origin/homeserve/main`
2. Update `release-please-config.json` → set `"last-release-sha"` to that SHA
3. Open a PR with that change titled `chore: bump release-please last-release-sha after upstream sync`
4. After merge, the next release-please run will only consider commits added
   **after** that SHA, ignoring the imported upstream history.

If a stale `release-please--branches--homeserve/main--components--rtk` branch
exists from a prior failed run, delete it via the GitHub UI (Branches list)
or:

```bash
gh api -X DELETE \
  "repos/HomeserveFR/rtk/git/refs/heads/release-please--branches--homeserve%2Fmain--components--rtk"
```
