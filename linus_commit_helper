#!/bin/bash
# requires gum to run: https://github.com/charmbracelet/gum

# request git type (fix, feature, etc..)
# request title with preset type
# request commit message
# show preview 
# create commit

# check if gum is installed
if ! [ -x "$(command -v gum)" ]; then
  echo "Error: 'gum' is not installed."
  echo "More info: https://github.com/charmbracelet/gum"
  exit 1
fi

# print program info box
gum style \
	--foreground 222 --border-foreground 50 --border normal \
	--align center --width 40 --margin "0 0" --padding "0 0" \
	'Git Commit helper' 'by Linus045'

# check if directory is a git repo
if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) != "true"  ]]; then
  echo "No git repo found, aborting..."
  exit 1
fi

# get prefix for commit message
commit_prefix=""

# text in square brackets will be extracted and used as prefix for the commit subject text e.g.
# If you select "[feat]     - A new feature"
# feat: <Some text here>
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

echo $commit_subject
commit_body=$(gum write --width=100 --show-line-numbers --height=10 --placeholder="Enter a longer description here (Ctrl+D or Esc to finish|Ctrl+C to cancel)")


gum style \
	--foreground 101 --border-foreground 50 --border normal \
	--align left --width 100 --margin "0 0" --padding "0 0" \
	"$commit_subject" "" "$commit_body"

gitbranch=$(git branch --show-current)

gum confirm --affirmative="Commit changes" --negative "Abort" "Current branch: $gitbranch"
confirm=$?
if [[ $confirm ]]; then
  echo "---------------------------------------------------------------------"
  git commit -m "$commit_subject" -m "$commit_body"
else
  echo "Commit aborted"
  exit 2
fi
