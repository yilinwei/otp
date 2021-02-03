#!/usr/bin/env bash

set -euo pipefail

# This part of the script, which publishes the scribble docs to Github pages,
# is adapted from Alexis King’s original scripts for Travis CI. Unfortunately,
# we cannot infer very much from the package structure so we rely on the
# the user to set the paths.
if [ -n "$INPUT_DOC_DIRECTORY" ] && [ -n "$INPUT_SCRIBBLE_FILE" ] \
       && [ -n "$INPUT_MAIN_REF" ] && [ -n "$INPUT_GITHUB_TOKEN" ]; then
    if [[ -z "$GITHUB_BASE_REF" ]] && [ "$INPUT_MAIN_REF" == "$GITHUB_REF" ]; then
        echo "Uploading documentation under ${INPUT_DOC_DIRECTORY}..."
	raco scribble +m --htmls \
	     --redirect-main http://pkg-build.racket-lang.org/doc/ \
	     --dest ./docs \
	     "${INPUT_DOC_DIRECTORY}/scribblings/${INPUT_SCRIBBLE_FILE}.scribl"
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
	    "https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" \
	    master:gh-pages
    fi
fi
