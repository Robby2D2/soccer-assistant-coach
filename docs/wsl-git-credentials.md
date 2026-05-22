# Fix: WSL git push fails silently from fastlane

## The bug

When `bundle exec fastlane bump` (or `create_release`) runs from WSL, the final `git push origin main:main --tags` step fails with:

```
/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe get: 1: /mnt/c/Program: not found
```

WSL's git is configured to delegate authentication to Windows' `git-credential-manager.exe` (single sign-on with the Windows credential store — Microsoft's recommended setup for WSL ↔ Windows git interop). The path `/mnt/c/Program Files/...` contains a space, and WSL's shell parses it as a word boundary, so it tries to execute `/mnt/c/Program` (which doesn't exist) instead of the full path.

Worse: fastlane doesn't check the push exit code, so the lane reports "Successfully committed" and exits 0 even when the push failed. The commit and tag are created locally but never reach GitHub, so the release workflows never fire.

## The fix: GitHub PAT in `$GITHUB_TOKEN`

Replace the Windows credential helper with one that reads a Personal Access Token from an environment variable. One-time setup; works forever after.

### Step 1: create a GitHub PAT

1. Go to https://github.com/settings/tokens/new
2. **Note**: `WSL git push (soccer-assistant-coach)`
3. **Expiration**: 1 year (or whatever fits your rotation policy)
4. **Scopes**: check `repo` (full control of private repositories)
5. **Generate token** → copy the `ghp_...` string immediately (you won't see it again)

### Step 2: store the token in WSL

Add this to `~/.bashrc` (or `~/.zshrc`) in WSL:

```bash
export GITHUB_TOKEN='ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

Reload:
```bash
source ~/.bashrc
```

> Why `~/.bashrc` and not the repo's `.env`? Because fastlane is invoked as a subprocess of your interactive shell — it inherits env vars from the parent shell. Tokens should not be checked into the repo.

### Step 3: configure WSL git to use it

Run once in WSL:

```bash
git config --global --unset-all credential.helper
git config --global credential.helper '!f() { test "$1" = get && echo "username=git" && echo "password=$GITHUB_TOKEN"; }; f'
```

This:
1. Removes any existing credential helpers (including the broken Windows one)
2. Installs a shell function that, when git asks for credentials, prints `username=git` and `password=<value of $GITHUB_TOKEN>`

The `!f() { ... }; f` syntax is git's standard "custom credential helper" pattern — the `!` prefix tells git to run the rest as a shell command.

### Step 4: verify

```bash
cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach
git pull       # should succeed without any prompt or error
echo $GITHUB_TOKEN | head -c 12   # should print "ghp_xxxxxxxx"
```

A successful `git pull` with no `git-credential-manager` errors confirms the helper is working. From now on, `fastlane create_release` push step will work end-to-end from WSL.

## Token rotation

When the PAT expires:
1. Generate a new one (same scopes)
2. Update `GITHUB_TOKEN` in `~/.bashrc`
3. Run `source ~/.bashrc`

No git config changes needed — the credential helper reads the env var fresh on every push.

## Why not just use `gh auth setup-git` in WSL?

That works too, and is what GitHub officially recommends. Requires `gh` installed in WSL + an interactive `gh auth login` flow. It's a fine alternative if you prefer OAuth over a PAT — the credential helper it installs uses `gh auth git-credential` under the hood, which also bypasses the path-space issue.

## Why not use `credential.helper store`?

That works too, but stores the token plaintext in `~/.git-credentials` (no encryption, just file permissions). The env-var approach keeps the token out of files entirely; it only lives in process memory and your `~/.bashrc` (which is just as readable but conceptually less of a "credential file").

## Why does this even happen?

Microsoft's WSL setup guide tells you to run:
```
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
```

The backslash-space is meant to escape the space inside the quoted argument. But git stores the value verbatim and re-emits it without re-quoting when invoking the helper. Different shell parsers (bash vs sh vs dash) handle the escaped space differently. On systems with `dash` as the default `/bin/sh` (Ubuntu, Debian-based WSL distros), the escape doesn't survive — the helper invocation breaks on the bare space.

The env-var approach sidesteps this entirely: no path with spaces, no escape gymnastics, no Windows interop.
