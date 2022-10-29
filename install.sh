if ! [[ -f ".git/hooks/prepare-commit-msg" ]]; then
 touch ".git/hooks/prepare-commit-msg"
fi

echo "bash ./linus_commit_helper \$1 \$2 \$3" >> ".git/hooks/prepare-commit-msg"

cp ./linus_commit_helper ./.git/hooks/linus_commit_helper
