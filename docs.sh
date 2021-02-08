#!/usr/bin/env bash

set -euo pipefail

doc_directory=$1
scribble_file=$2
github_token=$3

# This part of the script, which publishes the scribble docs to Github pages,
# is adapted from Alexis King’s original scripts for Travis CI. Unfortunately,
# we cannot infer very much from the package structure so we rely on the
# the user to set the paths.
if [ -n "$doc_directory" ] && [ -n "$scribble_file" ] && [ -n "$github_token" ]; then
    raco scribble +m --htmls \
	 --redirect https://docs.racket-lang.org/search/index.html \
	 --dest ./docs \
	 "${doc_directory}/scribblings/${scribble_file}.scribl"
    # Here we create a /new/ repository with no history where the scribble docs are generated.
    cd docs || exit 1
    # Sometimes the scribble command will create a subfolder, but Github doesn't like it.
    # This is a noop in the case that there isn't one.
    cd $(find . -maxdepth 1 -type d | tail -n1) || exit 1
    git config --global user.email $(git show -s --format=format:%ae) 
    git config --global user.name $(git show -s --format=format:%an)
    git init
    git add .
    git commit -m 'Deploy to Github Pages'
    # Rarely do we want to actually save the history of the Github Pages — force pushing wipes the history.
    git push --force  \
	"https://${GITHUB_ACTOR}:${github_token}@github.com/${GITHUB_REPOSITORY}.git" \
	master:gh-pages
fi
