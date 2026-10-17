# Syncing the Homeserve mirror with upstream rtk-ai/rtk

This fork (`HomeserveFR/rtk`) is a mirror of the upstream `rtk-ai/rtk`,
maintained for Homeserve security compliance. The branch `homeserve/main`
carries an upstream release tag plus the Homeserve layer (CI on self-hosted
runners, SonarQube, release workflow, `install.sh`, Homebrew formula).

Sync is **manual**: there is no scheduled automation. Every sync goes through
a pull request to `homeserve/main`, so the full CI (fmt, clippy, tests on
Linux/macOS/Windows, cargo-audit, semgrep, SonarQube) runs on it before merge.

## One-time setup

```bash
git remote add upstream https://github.com/rtk-ai/rtk.git
# Fetch upstream tags into their own namespace. The mirror has its own
# release line (v1.0.0, v1.0.1, v1.1.0, ...) whose tag names collide with
# upstream tags of different content: a plain `git fetch upstream --tags`
# fails with "would clobber existing tag".
git fetch upstream --no-tags \
  '+refs/heads/master:refs/remotes/upstream/master' \
  '+refs/tags/*:refs/upstream-tags/*'
```

Upstream release `vX.Y.Z` is then `refs/upstream-tags/vX.Y.Z` locally.

## Sync procedure

Sync onto an upstream **release tag**, never onto `develop` or an
unreleased `master`.

1. Create a Jira ticket, then a branch from `homeserve/main`:

   ```bash
   git fetch origin
   git switch -c chore/<TICKET>-sync-upstream-vX.Y.Z origin/homeserve/main
   ```

2. Merge the upstream tag as a **real merge commit**:

   ```bash
   git merge --no-ff refs/upstream-tags/vX.Y.Z \
     -m "chore(<TICKET>): sync upstream rtk-ai/rtk vX.Y.Z"
   ```

   A merge commit keeps the upstream tag as an ancestor of `homeserve/main`,
   so the next sync only replays what changed since. A squash would drop
   that link and make every later sync re-conflict on the same lines.

3. Resolve conflicts, keeping the Homeserve layer (see the list below), then
   run the full local validation:

   ```bash
   cargo fmt --all -- --check
   cargo clippy --workspace --all-targets
   cargo doc --no-deps
   cargo test --all
   cargo audit
   ```

   For each advisory with a semver-compatible fix, update the lockfile only
   (`cargo update -p <crate>`) in its own `deps(<TICKET>)` commit. A fix that
   needs a breaking bump of a direct dependency changes upstream code: raise
   it upstream or in a dedicated PR.

4. Pin release-please past the imported history. In a commit **after** the
   merge commit, set the top-level `last-release-sha` in
   `release-please-config.json` to the merge commit SHA:

   ```bash
   git rev-parse HEAD   # right after committing the merge
   ```

   release-please walks history from `homeserve/main` back to that SHA and
   ignores everything older, so the ~1000 imported upstream commits never
   reach the mirror's changelog. The key must sit at the top level of the
   file: release-please ignores it inside `packages`.

5. Cut a release. release-please skips a release whose changelog would be
   empty, and `chore`/`ci`/`docs` commits are hidden from it. Add one
   user-facing commit describing what the sync brings, with a `Release-As`
   footer for the next mirror version:

   ```text
   feat(<TICKET>): ship rtk built from upstream rtk-ai/rtk vX.Y.Z

   <what changes for users>

   Release-As: A.B.C
   ```

6. Push the branch and open a PR to `homeserve/main`. Merge it with
   **"Create a merge commit"**, never "Squash and merge".

### Commit message ruleset

The org ruleset `commit-message` checks every pushed commit. Some upstream
commits do not match it (merge commits like `Merge upstream/develop into
...`, `fmt:` or `bench:` subjects). Pushing the sync branch therefore needs
an actor on the ruleset bypass list (organization admin).

### Conflict points: keep the Homeserve version

| File | Homeserve change |
|---|---|
| `.github/workflows/ci.yml` | `homeserve/main` in `pull_request.branches` |
| `.github/workflows/cd.yml` | release-please in manifest mode (no `release-type` input), `GITHUB_TOKEN`; no develop pre-release path |
| `.github/workflows/release.yml` | 4 targets only (macOS x2, Linux musl, Windows), `LICENSE` + `LICENSE-ENGINE` in every archive, formula committed to `homeserve/main` |
| `.github/workflows/sonarqube.yml` | Homeserve only (not upstream); the coverage run skips the two `isolate_rtk_test` cases that llvm-cov instrumentation breaks |
| `.github/workflows/stale.yml` | job guarded to `rtk-ai/rtk` |
| `.github/dependabot.yml` | `target-branch: "homeserve/main"` |
| `release-please-config.json` | top-level `last-release-sha` |
| `.release-please-manifest.json`, `CHANGELOG.md` | mirror release line |
| `install.sh` | `HomeserveFR/rtk`, Windows zip support, no `RTK_EDITION` (no `rtk-oss` assets) |
| `Formula/rtk.rb` | Homeserve tap URLs |
| `README.md` | Installation and "What You Install" sections |
| `Cargo.toml` | `repository` field |
| `Cargo.lock` | security patch bumps: take upstream, then redo the `cargo update -p` from `cargo audit` |
| `sonar-project.properties` | Homeserve only |

## Runners: GitHub-hosted on purpose

Homeserve bans GitHub-hosted runners, but this repository is an exception.
A GitHub fork of a public repository is public, and the org's self-hosted
runner groups refuse public repositories (`allows_public_repositories:
false`): a job sent to `docker` or `deployer` stays queued forever. Opening
a runner group to public repositories is not an option either: a pull request
from any external fork would run its code on Homeserve infrastructure. Keep
upstream's `ubuntu-latest` / `macos-latest` / `windows-latest` runners.

Moving to self-hosted runners requires the repository to stop being a public
fork (detached and made internal), which also puts `install.sh`, the Homebrew
tap and release downloads behind GitHub authentication.

## Versioning

The mirror has its own version line, driven by release-please on
`homeserve/main`. It does not follow upstream numbers. The release notes of
each sync release name the upstream version it is built from.

| Mirror | Upstream |
|---|---|
| 1.0.0, 1.0.1 | v0.43.0 |
| 1.1.0 | v1.0.1 |

## Releasing after a sync

1. The merge to `homeserve/main` runs `cd.yml`; release-please opens (or
   updates) a PR titled `chore(homeserve/main): release A.B.C`.
2. Review it: version bump and CHANGELOG entry.
3. Merge it: `release.yml` builds the four archives, publishes the GitHub
   release with `checksums.txt`, then commits the regenerated
   `Formula/rtk.rb` to `homeserve/main`.
4. `update-latest-tag` moves the `latest` tag; `install.sh` users get the
   new version.

## Verification

```bash
gh release view --repo HomeserveFR/rtk
```

Expected assets:

- `rtk-x86_64-apple-darwin.tar.gz`
- `rtk-aarch64-apple-darwin.tar.gz`
- `rtk-x86_64-unknown-linux-musl.tar.gz`
- `rtk-x86_64-pc-windows-msvc.zip`
- `checksums.txt`

Each archive contains `rtk` (or `rtk.exe`), `LICENSE` and `LICENSE-ENGINE`.

## Recovering a stale release-please branch

If a `release-please--branches--homeserve/main--components--rtk` branch is
left over from a failed run, delete it:

```bash
gh api -X DELETE \
  "repos/HomeserveFR/rtk/git/refs/heads/release-please--branches--homeserve%2Fmain--components--rtk"
```
