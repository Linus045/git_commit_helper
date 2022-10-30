# Description
This program is a simple interface for commiting to git similar to https://github.com/streamich/git-cz using Charm's gum tool (more info: https://github.com/charmbracelet/gum).

This program can be used on its own or as a git hook.

# Installation | Usage
Usage: 
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
