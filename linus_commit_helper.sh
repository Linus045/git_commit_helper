#!/bin/bash
# requires gum to run: https://github.com/charmbracelet/gum

uninstall_script() {
  repo_path=$1
  if [[ ! -d $repo_path ]]; then
    echo "Path is not a valid directory"
    exit 1
  fi

  echo "Repository path: $(realpath $repo_path)"

  is_git_repo $repo_path
  err=$?
  if [[ $err == 1  ]]; then
    echo "No git repo found, aborting..."
    exit 1
  elif [[ $err == 2  ]]; then
    echo "Path is not a valid directory"
    exit 1
  fi
  
  hook_path=$repo_path/.git/hooks/prepare-commit-msg
  
  if [[ ! -f $hook_path ]]; then
    echo "Error: No hook file not found at: $(realpath $hook_path)"
    echo "Script might already be uninstalled"
    exit 1
  fi

  echo "To uninstall:"
  echo "Remove the call to the script file from the <repo>/.git/hooks/prepare-commit-msg file (or delete the file if it only contains this call)"


  gum confirm --affirmative="Open hook file" --negative "No" $"Do you want to open the this hook file in your default editor? ($EDITOR $(realpath $hook_path))"
  confirm=$?

  if [[ $confirm == 0 ]]; then
    echo "Opening editor..."
    $EDITOR $(realpath ./.git/hooks/prepare-commit-msg)
  fi
}

instructions_usage() {
  printf \
    "Usage: 
      bash linus_commit_helper.sh --<install|uninstall|commit> <project_path>
      bash linus_commit_helper.sh --help

      This is only used internally in the hook and can be ignored:
      bash linus_commit_helper.sh --hook <COMMIT_MSG_FILE> <COMMIT_SOURCE> <SHA1>

      Options:
      --install      Installs this script as a git hook into the provided git project
      --uninstall    Prints instructions to uninstall this script and optionally opens the hook file in the default editor
      --commit       Runs this program in standalone-mode. Request commit message and then commits automatically
      --hook         Is used internally when called via git hook
      --help         Prints additional help\n"
    }

instructions_help() {
  instructions_usage
  printf \
    "
      This program can be used on its own or as a git hook.
      Charm's program 'gum' is required for it to work. More info: https://github.com/charmbracelet/gum

      To use it on its own, call this program with the path to the repo
      e.g. 
      bash linus_commit_helper.sh --commit /home/me/my_cool_project
      It will now request the commit message and automatically call 'git commit' afterwards.


      To install it as a git hook use bash linus_commit_helper.sh install <repo-path>
      e.g. 
      bash linus_commit_helper.sh --install /home/me/my_cool_project
      It will now run on every 'git commit' call automatically and prepare the commit message.\n"
    }

print_info_box() {
  # print program info box
  gum style \
    --foreground 222 --border-foreground 50 --border normal \
    --align center --width 40 --margin "0 0" --padding "0 0" \
    'Git Commit Helper' 'by Linus045'
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
  if [[ -d $path ]]; then
    # check if directory is a git repo
    if [[ $(cd $path && git rev-parse --is-inside-work-tree 2> /dev/null) != "true"  ]]; then
      return 1
    else
      return 0
    fi
  else
    return 2
  fi
}

load_current_commit_msg() {
  COMMIT_MSG_FILE=$1
  COMMIT_SOURCE=$2
  SHA1=$3

  if [[ -f $COMMIT_MSG_FILE ]]; then
    commit_subject=$(head -n 1 $COMMIT_MSG_FILE)
    commit_body=$(tail -n +2 $COMMIT_MSG_FILE)
  fi
}

request_commit_subject() {
  # get prefix for commit message
  commit_prefix=""
  scope=""
  

  if [[ -z $commit_subject ]]; then
    TYPE_NO_PREFIX="NO PREFIX"
    selected=$(gum choose "[feat]      - A new feature"\
                          "[fix]       - A bug fix"\
                          "[docs]      - Documentation only changes"\
                          "[style]     - Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)"\
                          "[refactor]  - A code change that neither fixes a bug nor adds a feature"\
                          "[test]      - Adding missing tests or correcting existing tests"\
                          "[perf]      - A code change that improves performance"\
                          "[$TYPE_NO_PREFIX] - Use no prefix")

    if [[ -z $selected ]]; then
      echo "No selection made, aborting..."
      exit 2
    fi

    # text in square brackets will be extracted and used as prefix for the commit subject text e.g.
    # If you select "[feat]     - A new feature"
    # feat: <Some text here>
    if [[ $selected =~ \[(.+)\] ]]; then
      commit_prefix=${BASH_REMATCH[1]}
      if [[ $commit_prefix = "$TYPE_NO_PREFIX" ]]; then
        commit_prefix=""
      fi
    else
      echo "Error while parsing string: $selected"
      exit 1
    fi
 
    if [[ -n $commit_prefix ]]; then
      # get optional scope for change
      scope=$(gum input --char-limit=40 --width=40 --prompt="Scope: " --placeholder="Enter optional scope here (Issue number/component name/etc.)")
    fi

    # combine prefix, scope and subject into one string
    if [[ -z $scope ]]; then
      if [[ -n $commit_prefix ]]; then
        commit_subject="$commit_prefix:"
      fi
    else
      commit_subject="$commit_prefix($scope):"
    fi
  fi
  
  commit_subject=$(gum input --char-limit=80 --width=100 --prompt="Summary: " --value="$commit_subject"  --placeholder "Enter a short summary here (80 chars max)")

  if [[ -z $commit_subject ]]; then
    echo "No summary provided, aborting..."
    exit 2
  fi
}

request_commit_body() {
  commit_body=$(gum write --width=100 --show-line-numbers --height=10 --value="$commit_body" --placeholder="Enter a longer description here (Ctrl+D or Esc to finish|Ctrl+C to cancel)")
}


request_commit_message() {
  gum_installed_check
 
  request_commit_subject
  request_commit_body

  gum style \
    --foreground 101 --border-foreground 50 --border normal \
    --align left --width 80 --margin "0 0" --padding "0 0" \
    -- "$commit_subject" "" "$commit_body"

  gitbranch=$(git branch --show-current)

  echo "Current branch: $gitbranch"
  option1='1. Edit'
  option2='2. Abort'
  option3='3. Commit'
  option=$(printf "$option1\n$option2\n$option3" | gum choose)
  # clear "Current branch" line
  # move 1 line up, carriage return, clear line
  echo -e "\033[1A\r\033[K"

  if [[ $option == $option1 ]]; then
	  request_commit_message
  elif [[ $option == $option3 ]]; then
    echo "---------------------------------------------------------------------"

    if [[ $RUN_VIA_HOOK == 1 ]]; then
      echo "$commit_subject" > $COMMIT_MSG_FILE
      echo "" >> $COMMIT_MSG_FILE
      printf -- "$commit_body" >> $COMMIT_MSG_FILE
    else
      git commit -m "$commit_subject" -m "$commit_body"
    fi
  elif [[ $option == $option2 ]]; then
    echo "Commit aborted"
    exit 2
  fi
}

check_terminal_capabilities() {
  # check if terminal is capable of displaying and using gum
  # 'man terminfo' for more info, e.g. terminfo dumb
  if [[ $TERM == "dumb" ]]; then
	echo '[linus_commit_helper] Not running in "dumb" terminal (see environment variable $TERM)'
	exit 0
  fi

  if [[ $TERM == "unknown" ]]; then
	echo '[linus_commit_helper] Not running in "unknown" terminal (see environment variable $TERM)'
	exit 0
  fi
}

# Install script with: 
# bash linus_commit_helper.sh install <PATH>
if [[ $1 == "--help" ]]; then
  instructions_help
  exit 0
elif [[ $1 == "--uninstall" ]]; then
  repo_path=$2
  if [[ -z $repo_path ]]; then
    echo "Error: No path provided."
    exit 1
  fi
  uninstall_script $2
  exit 0
elif [[ $1 == "--install" ]]; then
  repo_path=$2
  if [[ -z $repo_path ]]; then
    echo "Error: No path provided."
    exit 1
  fi

  if [[ -d $repo_path ]]; then
    echo "Installing script in $repo_path"
   is_git_repo $repo_path
    if [[ $? == 1  ]]; then
      echo "No git repo found, aborting..."
      exit 1
    elif [[ $err == 2  ]]; then
      echo "Path is not a valid directory"
      exit 1
    fi

    if ! [[ -f "$repo_path/.git/hooks/prepare-commit-msg" ]]; then
     touch "$repo_path/.git/hooks/prepare-commit-msg"
     chmod +x "$repo_path/.git/hooks/prepare-commit-msg"
     echo "Created $repo_path/.git/hooks/prepare-commit-msg file"
    fi

    script_dir="$(dirname -- "${BASH_SOURCE[0]}")"
    script_filepath=$(realpath "$script_dir/linus_commit_helper.sh")

    echo "bash $script_filepath --hook \$1 \$2 \$3" >> "$repo_path/.git/hooks/prepare-commit-msg"
    echo "Added hook call to $script_filepath in $repo_path/.git/hooks/prepare-commit-msg file"

    echo "Installed hook in $repo_path successfully."
  else 
    echo "Error: Directory not found: $repo_path"
    exit 1
  fi

  exit 0
elif [[ $1 == "--commit" ]]; then
  check_terminal_capabilities
  gum_installed_check
  RUN_VIA_HOOK=0
  
  repo_path=$2
  if [[ -z $repo_path ]]; then
    echo "Error: No path provided."
    exit 1
  fi

  if [[ -d $repo_path ]]; then
    cd $repo_path
	print_info_box
    request_commit_message
  else 
    echo "Error: Directory not found: $repo_path"
    exit 1
  fi
elif [[ $1 == "--hook" ]]; then
  check_terminal_capabilities
  gum_installed_check

  COMMIT_MSG_FILE=$2
  COMMIT_SOURCE=$3
  SHA1=$4
  


  if [[ -f $COMMIT_MSG_FILE ]]; then
    # removes all lines starting with a # sign
    existing_commit_message=$(sed "/^#.*$/d" $COMMIT_MSG_FILE)
    if [[ -n $existing_commit_message ]]; then
      gum style \
        --foreground 101 --border-foreground 50 --border normal \
        --align left --width 80 --margin "0 0" --padding "0 0" \
        "$existing_commit_message"
    
      gum confirm --affirmative="Edit commit" --negative "Continue" "Do you want to edit the commit message?"
      confirm=$?

      if [[ $confirm == 1 ]]; then
        echo "Continuing without editing commit..."
        exit 0
      fi
    
      load_current_commit_msg $COMMIT_MSG_FILE $COMMIT_SOURCE $SHA1
    fi
  fi

  
  RUN_VIA_HOOK=1
  print_info_box
  request_commit_message
else
  echo "Error: Unknown command"
  instructions_usage
fi


