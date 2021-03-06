#!/usr/bin/env bash


if [ "$0" == "/bin/sh" ] || [ "$0" == "sh" ]; then
    echo "sh is stealing bash sunshine.";
    exit 1;
fi


export r2g_gray='\033[1;30m'
export r2g_magenta='\033[1;35m'
export r2g_cyan='\033[1;36m'
export r2g_orange='\033[1;33m'
export r2g_yellow='\033[1;33m'
export r2g_green='\033[1;32m'
export r2g_no_color='\033[0m'

my_args=( "$@" );

project_root="";

if [[ "$(uname -s)" == "Darwin" ]]; then
    project_root="$(dirname $(dirname $("$HOME/.oresoftware/bin/realpath" $0)))";

else
    project_root="$(dirname $(dirname $(realpath $0)))";
fi

commands="$project_root/dist/commands"

r2g_match_arg(){
    # checks to see if the first arg, is among the remaining args
    # for example  ql_match_arg --json --json # yes
    first_item="$1"; shift;
    for var in "$@"; do
        if [[ "$var" == "$first_item" ]]; then
          return 0;
        fi
    done
    return 1;
}

export -f r2g_match_arg;


export FORCE_COLOR=1;
cmd="$1";


#r2g_zmx(){
# "$@"  \
#      2> >( while read line; do echo -e "${r2g_magenta}r2g:${r2g_no_color} $line"; done ) \
#      1> >( while read line; do echo -e "${r2g_gray}r2g:${r2g_no_color} $line"; done )
#}

r2g_zmx() {
    "$@" 2>&1 | sed 's/^/r2g: /'
}


export -f r2g_zmx;


if [ "$cmd" == "run" ] || [ "$cmd" == "test" ]; then

   shift 1;

    if [ -z "$(which rsync)" ]; then
        echo >&2 "You need to install 'rsync' for r2g to work its magic.";
        exit 1;
    fi

    if [ -z "$(which curl)" ]; then
        echo >&2 "You need to install 'curl' for r2g to work its magic.";
        exit 1;
    fi

    . "$HOME/.oresoftware/bash/r2g.sh" || {
        echo >&2 "Could not source r2g bash functions from .oresoftware/bash/r2g.sh.";
        exit 1;
    }

   r2g_zmx node "$commands/run" "$@"


elif [ "$cmd" == "init" ]; then

  shift 1;
  r2g_zmx  node "$commands/init" "$@"

elif [ "$cmd" == "symlink" ] || [ "$cmd" == "link" ]; then

  shift 1;
  r2g_zmx r2g_symlink "$@"

elif [ "$cmd" == "docker" ]; then

  shift 1;

  if ! which dkr2g; then
    npm install -g '@oresoftware/docker.r2g' || {
      echo "Could not install docker.r2g, exiting.";
      exit 1;
    }
  fi


  dkr2g exec --allow-unknown "$@"

else

  echo "r2g error: no subcommand was recognized, available commands: (r2g run, r2g init, r2g docker)."
  node "$commands/basic" "$@"

fi

exit_code="$?"

if [[ "$exit_code" != "0" ]]; then
    echo -e "${r2g_magenta}Your r2g test process is exiting with 1.${r2g_no_color}";
    exit 1;
fi
