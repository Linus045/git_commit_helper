#!/bin/bash
# requires gum to run: https://github.com/charmbracelet/gum

instructions_uninstall() {
  echo "To uninstall:"
  echo "1. Delete the file <repo>/.git/hooks/linus_commit_helper.sh in the corresponding repo."
  echo "2. Remove the call to this file from the <repo>/.git/hooks/prepare-commit-msg file (or delete the file if it only contains this call"
}

instructions_usage() {
  printf \
"Usage: 
  bash linus_commit_helper.sh --<install|commit> [project_path]>
  bash linus_commit_helper.sh --<uninstall|help>

Options:
  --install      Installs this script as a git hook into the provided git project
  --uninstall    Prints instructions to uninstall this script (its just 2 simple steps)
  --commit       Runs this program in standalone-mode. Request commit message and then commits automatically
  --hook         Is used internally when called via git hook
"
}

instructions_help() {
  printf \
"Usage: 
  bash linus_commit_helper.sh --<install|commit> [project_path]>
  bash linus_commit_helper.sh --<uninstall|help>

  This is only used internally in the hook and can be ignored:
  bash linus_commit_helper.sh --hook <COMMIT_MSG_FILE> <COMMIT_SOURCE> <SHA1>

Options:
  --install      Installs this script as a git hook into the provided git project
  --uninstall    Prints instructions to uninstall this script (its just 2 simple steps)
  --commit       Runs this program in standalone-mode. Request commit message and then commits automatically
  --hook         Is used internally when called via git hook


This program can be used on its own or as a git hook.
Charm's program 'gum' is required for it to work. More info: https://github.com/charmbracelet/gum

To use it on its own, call this program with the path to the repo
e.g. 
bash linus_commit_helper.sh --commit /home/me/my_cool_project
It will now request the commit message and automatically call 'git commit' afterwards.


To install it as a git hook use bash linus_commit_helper.sh install <repo-path>
e.g. 
bash linus_commit_helper.sh --install /home/me/my_cool_project
It will now run on every 'git commit' call automatically and prepare the commit message.
"
}

print_info_box() {
  # print program info box
  gum style \
    --foreground 222 --border-foreground 50 --border normal \
    --align center --width 40 --margin "0 0" --padding "0 0" \
    'Git Commit helper' 'by Linus045'
}

gum_installed_check() {
  # check if gum is installed
  if ! [ -x "$(command -v gum)" ]; then
    echo "Error: 'gum' is not installed."
    echo "More info: https://github.com/charmbracelet/gum"
    exit 1
  fi
}


is_git_repo() {
  path=$1
  if [[ -d path ]]; then
    # check if directory is a git repo
    if [[ $(cd $path && git rev-parse --is-inside-work-tree 2> /dev/null) != "true"  ]]; then
      echo "No git repo found, aborting..."
      return 1
    else
      return 0
    fi
  else
    echo "Not a directory: $path"
    return 1
  fi
}

request_commit_subject() {
  # get prefix for commit message
  commit_prefix=""
  
  selected=$(gum choose "[feat]     - A new feature" "[fix]      - A bug fix"\
                        "[docs]     - Documentation only changes"\
                        "[style]    - Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)"\
                        "[refactor] - A code change that neither fixes a bug nor adds a feature"\
                        "[test]     - Adding missing tests or correcting existing tests"\
                        "[perf]     - A code change that improves performance")

  if [[ -z $selected ]]; then
    echo "No selection made, aborting..."
    exit 2
  fi

  # text in square brackets will be extracted and used as prefix for the commit subject text e.g.
  # If you select "[feat]     - A new feature"
  # feat: <Some text here>
  if [[ $selected =~ \[(.+)\] ]]; then
    commit_prefix=${BASH_REMATCH[1]}
  else
    echo "Error while parsing string: $selected"
    exit 1
  fi

  
  # get optional scope for change
  scope=$(gum input --char-limit=40 --width=40 --prompt="Scope: " --placeholder="Enter optional scope here (Issue number/component name/etc.)")

  commit_subject=$(gum input --char-limit=50 --width=100 --prompt="$commit_prefix: "  --placeholder "Enter a short summary here (50 chars max)")
  if [[ -z $commit_subject ]]; then
    echo "No summary provided, aborting..."
    exit 2
  fi

  # combine prefix, scope and subject into one string
  if [[ -z $scope ]]; then
    commit_subject="$commit_prefix: $commit_subject"
  else
    commit_subject="$commit_prefix($scope): $commit_subject"
  fi
}

request_commit_body() {
  echo $commit_subject
  commit_body=$(gum write --width=100 --show-line-numbers --height=10 --placeholder="Enter a longer description here (Ctrl+D or Esc to finish|Ctrl+C to cancel)")
}

request_commit_message() {
  gum_installed_check
  print_info_box
  
  request_commit_subject
  request_commit_body

  gum style \
    --foreground 101 --border-foreground 50 --border normal \
    --align left --width 100 --margin "0 0" --padding "0 0" \
    "$commit_subject" "" "$commit_body"

  gitbranch=$(git branch --show-current)

  gum confirm --affirmative="Commit changes" --negative "Abort" "Current branch: $gitbranch"
  confirm=$?

  if [[ $confirm == 0 ]]; then
    echo "---------------------------------------------------------------------"

    if [[ $RUN_VIA_HOOK == 1 ]]; then
      echo "$commit_subject" > $COMMIT_MSG_FILE
      echo "" >> $COMMIT_MSG_FILE
      printf "$commit_body" >> $COMMIT_MSG_FILE
    else
      git commit -m "$commit_subject" -m "$commit_body"
    fi
  else
    echo "Commit aborted"
    exit 2
  fi
}

# Install script with: 
# bash linus_commit_helper.sh install <PATH>
if [[ $1 == "--help" ]]; then
  instructions_help
  exit 0
elif [[ $1 == "--uninstall" ]]; then
  deinstall_instructions
  exit 0
elif [[ $1 == "--install" ]]; then
  repo_path=$2
  if [[ -n $repo_path ]]; then
    repo_path=$(pwd)
  fi

  if [[ -d $repo_path ]]; then
    echo "Installing script in $repo_path"
   
    if [[ $(is_git_repo $repo_path) == 1  ]]; then
      echo "No git repo found, aborting..."
      exit 1
    fi

    if ! [[ -f "$repo_path/.git/hooks/prepare-commit-msg" ]]; then
     touch "$repo_path/.git/hooks/prepare-commit-msg"
     chmod +x "$repo_path/.git/hooks/prepare-commit-msg"
     echo "Created $repo_path/.git/hooks/prepare-commit-msg file"
    fi

    echo "bash .git/hooks/linus_commit_helper.sh --hook \$1 \$2 \$3" >> "$repo_path/.git/hooks/prepare-commit-msg"
    echo "Added hook call in $repo_path/.git/hooks/prepare-commit-msg file"

    cp ./linus_commit_helper.sh $repo_path/.git/hooks/linus_commit_helper.sh
    echo "Installed linus commit helper in $repo_path"
  else 
    echo "Error: Directory not found: $repo_path"
    exit 1
  fi

  exit 0
elif [[ $1 == "--commit" ]]; then
  RUN_VIA_HOOK=0
  request_commit_message
elif [[ $1 == "--hook" ]]; then
  COMMIT_MSG_FILE=$2
  COMMIT_SOURCE=$3
  SHA1=$4

  RUN_VIA_HOOK=1
  request_commit_message
else
  instructions_usage
fi
 