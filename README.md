# Description
This program is a simple interface for commiting to git similar to https://github.com/streamich/git-cz using Charm's gum tool (more info: https://github.com/charmbracelet/gum).

This program can be used on its own or as a git hook.

![Preview](https://i.imgur.com/apKuO1k.png)
![Preview](https://i.imgur.com/3rdpRS7.png)

# Installation
To install, simply clone this repo.

`git clone https://github.com/Linus045/git_commit_helper.git git_commit_helper`

# Usage: 
```
bash linus_commit_helper.sh --<install|commit> <project_path>
bash linus_commit_helper.sh --<uninstall|help>

Options:
  --install      Installs this script as a git hook into the provided git project
  --uninstall    Prints instructions to uninstall this script (its just 2 simple steps)
  --commit       Runs this program in standalone-mode. Request commit message 
                 and then commits automatically
  --hook         Is used internally when called via git hook
  --help         Prints this help info
```

To use it on its own, call this program with the path to the repo e.g. 

`bash linus_commit_helper.sh --commit /home/me/my_cool_project`

It will now request the commit message and automatically call 'git commit' afterwards.


To install it as a git hook use `--install` e.g. 
`bash linus_commit_helper.sh --install /home/me/my_cool_project`

It will now run on every `git commit` call automatically and prepare the commit message.

# Updating
To update this script, simply pull the latest version from `main`

# Notice for usage in git hooks
The hook itself links to the script using the absolute path (after using --install) 

Example: 

After using `bash linus_commit_helper.sh --install /home/linus/dev/github/git_commit_helper`

`/home/linus/dev/github/git_commit_helper/.git/hooks/prepare-commit-msg` now contains this call:
```
bash /home/linus/dev/github/git_commit_helper/linus_commit_helper.sh --hook $1 $2 $3
```

This makes it easier to update the script since you can just pull the latest changes and it reflects immediately for all repos that use the hook.
If you only need this hook for one git repository and don't care about updating, 
you could also move the file `linus_commit_helper.sh` into the `<Git Repo>/.git/hooks/` directory of the respective git repository 
and adjust the path in the `<Git Repo>/.git/hooks/prepare-commit-msg` file
