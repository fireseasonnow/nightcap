<img src=".github/social.png" alt="nightcap: a quiet daily brew for your Mac. Keeps Homebrew up to date in the background." width="100%">

A quiet daily brew for your Mac: keeps Homebrew up to date in the background on macOS. Once a day it runs:

```
brew update && brew upgrade && brew cleanup
```

It's a ~40-line shell script plus a launchd agent, with no tap and nothing else to trust. Read [`nightcap`](nightcap) before you install it; that's the whole thing.

If you want more options (pick which packages to upgrade, `sudo` prompts for casks and so on), look at [DomT4/homebrew-autoupdate](https://github.com/DomT4/homebrew-autoupdate) instead.

## What it does

- Runs once a day and at login.
- **Skips the run on battery**, so the catch-up after you open the lid won't drain it.
- **Notifies you only when something fails.** Successful runs stay quiet.
- Logs to `~/Library/Logs/nightcap.log`, trimmed to the last 2000 lines. Each run ends with a summary line such as `ok, upgraded: git node ripgrep`, so you can see what changed and when.
- Runs as a low-priority background job.
- Works with Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) Homebrew installs.

## Install

```
git clone https://github.com/fireseasonnow/nightcap.git
cd nightcap
./install.sh
```

This copies the script to `~/.local/bin/nightcap` and loads `~/Library/LaunchAgents/io.github.fireseasonnow.nightcap.plist`. The first run starts right away. Running `install.sh` again is safe; it replaces the script and reloads the agent.

By default it runs every 24 hours, counted from install or login. To run at a fixed time of day instead, pass it in 24-hour format:

```
./install.sh 03:00
```

Either way it also runs at login.

The first time it runs, macOS may show an "App Background Activity" notice. You can manage it in System Settings → General → Login Items & Extensions.

## Uninstall

```
./uninstall.sh
```

Or by hand:

```
launchctl bootout gui/$(id -u)/io.github.fireseasonnow.nightcap
rm ~/Library/LaunchAgents/io.github.fireseasonnow.nightcap.plist
rm ~/.local/bin/nightcap ~/Library/Logs/nightcap.log
```

## Things to know

- **Sleep and shutdown:** launchd doesn't wake the Mac. If a run comes due while it's asleep, it runs once soon after you wake it. If the Mac is off, the agent starts again at login. So a fixed time like `03:00` only actually runs at 3am on a Mac that stays awake overnight; on a laptop that sleeps, it runs when you open the lid.
- **To hold a package back** (a database, a specific language version), run `brew pin <name>`. Pinned packages are skipped by `brew upgrade`, so this script leaves them alone too. `brew unpin <name>` releases it.
- **Casks that need `sudo`** can't upgrade in the background. Those runs fail with a notification; run `brew upgrade` in a terminal to finish them.
- **`brew cleanup` also autoremoves formulae that nothing depends on anymore**, for example a Python version that was only installed as a dependency. To prevent that, add `export HOMEBREW_NO_AUTOREMOVE=1` near the top of the script.
- **Change the schedule** by running `install.sh` again, with or without a time.

## License

[MIT](LICENSE)
