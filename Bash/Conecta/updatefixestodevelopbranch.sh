#!/bin/bash

my_dir="$(dirname "$0")"
source "$my_dir/utils.sh"

RELEASE_BRANCH=""
CONFIGURATION="Loc.SqlS.Release"
CONECTA_DIR="/e/Compart/Conecta/Conecta"
nextStep="1"

while getopts 'c:d:n:b:' flag; do
  case "${flag}" in
    b) RELEASE_BRANCH="${OPTARG}" ;;
    c) CONFIGURATION="${OPTARG}" ;;
    d) CONECTA_DIR="${OPTARG}" ;;
    n) nextStep="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

function updateBranch() {
    git checkout "$2"
    git reset --hard origin/"$2"
    exitIfLastHasError "$1"
}

function deleteBranchRemote() {
    git push origin :"$1"
}

function updateCurrentBranchWith() {
    git pull origin "$2"
    exitIfLastHasError "$1"
    deleteBranchRemote $(git rev-parse --abbrev-ref HEAD)
    git push -u origin $(git rev-parse --abbrev-ref HEAD)
}

function createUpdateBranch() {
    git branch -D "propagateChangesFromBaseBranch-$2" || :
    git checkout -b "propagateChangesFromBaseBranch-$2"
    exitIfLastHasError "$1"
}

function start() {
    pushd "$CONECTA_DIR"
    git fetch --prune
    
    RELEASE_BRANCH="$(getReleaseBranch $RELEASE_BRANCH)" || (echo "$RELEASE_BRANCH" && exit $?)
    echo "Using release branch: $RELEASE_BRANCH"

    if [[ $nextStep -le 1 ]]; then
        updateBranch 1 $RELEASE_BRANCH
    fi

    if [[ $nextStep -le 2 ]]; then
        createUpdateBranch 2 $RELEASE_BRANCH
    fi

    if [[ $nextStep -le 3 ]]; then
        updateCurrentBranchWith 3 "master"
        git pr
    fi

    if [[ $nextStep -le 4 ]]; then
        read -p "Release precisa ser atualizada (s/n)? " answer
        case ${answer:0:1} in
            y|Y|s|S )
                iexit 4
            ;;
            * )
                deleteBranchRemote "propagateChangesFromBaseBranch-$RELEASE_BRANCH"
                echo "Continuando..."
            ;;
        esac
    fi

    if [[ $nextStep -le 5 ]]; then
        updateBranch 5 "develop"
    fi

    if [[ $nextStep -le 6 ]]; then
        createUpdateBranch 6 "develop"
    fi

    if [[ $nextStep -le 7 ]]; then
        updateCurrentBranchWith 7 $RELEASE_BRANCH
        git pr
    fi

    if [[ $nextStep -le 8 ]]; then
        read -p "Develop precisa ser atualizada (s/n)? " answer
        case ${answer:0:1} in
            y|Y|s|S )
                iexit 8
            ;;
            * )
                deleteBranchRemote "propagateChangesFromBaseBranch-develop"
            ;;
        esac
    fi

    popd
}

start