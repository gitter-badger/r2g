#!/usr/bin/env bash


if [[ "$0" != *"bash"* ]]; then
  echo "$0 tried to source the r2g shell script."
fi

export r2g_source_home="$HOME/.oresoftware/nodejs/node_modules/r2g";

r2g_get_latest_source(){
  . "$HOME/.oresoftware/bash/r2g.sh"
}

r2g_home(){
  echo "$HOME/.r2g"
}

r2g_project_root(){
  echo "$HOME/.r2g/temp/project"
}

r2g_uninstall(){
 npm uninstall -g r2g
  hash -d r2g
  rm -rf "$(which r2g)"
  hash -d r2g
  rm -rf "$(which r2g)"
  rm -rf "$(r2g_home)"
  rm -rf "$(type -P r2g)"
  hash -d r2g

}

r2g_open(){
  subl "$(r2g_project_root)"
}

r2g_view_log(){
 open "$HOME/.r2g/logs/r2g.log"
}

r2g_match_arg(){
    # checks to see if the first arg, is among the remaining args
    # for example  ql_match_arg --json --json # yes
    first_item="$1"; shift;
    for var in "$@"; do
        if [[ "$var" == "$first_item" ]]; then
          echo "yes";
          return 0;
        fi
    done
    return 1;
}


r2g_internal(){

   local my_args=( "$@" );
   local r2g_keep_temp=$(r2g_match_arg "--keep" "${my_args[@]}");
   local r2g_multi_temp=$(r2g_match_arg "--multi" "${my_args[@]}");

   local r2g_multi="";
    if [[ "$r2g_multi_temp" || "$r2g_keep_temp" ]]; then
       r2g_multi="yes"
    fi

    local exit_code="";

    local r2g_gray='\033[1;30m'
    local r2g_magenta='\033[1;35m'
    local r2g_cyan='\033[1;36m'
    local r2g_orange='\033[1;33m'
    local r2g_yellow='\033[1;33m'
    local r2g_green='\033[1;32m'
    local r2g_no_color='\033[0m'


    rm -rf "$HOME/.r2g/logs";
    mkdir -p "$HOME/.r2g/logs"
    mkdir -p "$HOME/.r2g/temp/project"

    if [[ -z "$r2g_multi" ]]; then
        rm -rf "$HOME/.r2g/temp/project";
    else
       echo "We are keeping the previously installed modules because '--keep' / '--multi' was used.";
    fi

    local my_cwd="$PWD";

    if [[ ! -f package.json ]]; then
       echo "Could not find a package.json file in your current working directory.";
#       my_cwd="$(node "$r2g_source_home/dist/find-root.js")"
        my_cwd="$(r2g_find_root)"
       if [[ -z "$my_cwd" ]]; then
         echo -e "${r2g_magenta}You are not within an NPM project.${r2g_no_color}";
         return 1;
       fi
    fi

    cd "$my_cwd";

    local result="$(npm pack)"
    if [[ -z "$result" ]]; then
        echo -e "${r2g_magenta}NPM pack command did not appear to yield a .tgz file.${r2g_no_color}";
        return 1;
    fi

    local tgz_path="$my_cwd/$result";
    local dest="$HOME/.r2g/temp/project"

    echo "r2g will install this package: '$tgz_path'"
    echo "to this project: '$dest'..."
    mkdir -p "$dest"

#    local copy_test="$(node "$r2g_source_home/dist/axxel.js" package.json 'r2g.copy-tests')"

    local copy_test="$(r2g_axxel package.json 'r2g.copy-tests')"

    if [[ -z "$copy_test" ]]; then
        echo -e "${r2g_yellow}No NPM script at 'r2g.copy-tests' in your package.json file.${r2g_no_color}";
    fi

#    local run_test="$(node "$r2g_source_home/dist/axxel.js" package.json 'r2g.run-tests')";

    local run_test="$(r2g_axxel package.json 'r2g.run-tests')";

    if [[ -z "$run_test" ]]; then
        echo -e "${r2g_yellow}No NPM script at 'r2g.run-tests' in your package.json file.${r2g_no_color}";
    fi


    (
      set -e;
      cd "$dest";
       [ ! -f "package.json" ]  && {
            curl -H 'Cache-Control: no-cache' \
              "https://raw.githubusercontent.com/oresoftware/shell/master/assets/package.json?$(date +%s)" \
                --output "$dest/package.json" 2> /dev/null || {
                echo "curl command failed to read package.json, now we should try wget..." >&2
          }
        } || {
        echo "warning: package.json file may have already existed in \$HOME/.r2g/temp/project";
      }
      cat "$r2g_source_home/dist/smoke-tester.js" > smoke-tester.js;
      echo "now running: 'npm install "${tgz_path}"'...";
      npm install "$tgz_path" # --silent >> "$HOME/.r2g/logs/r2g.log" 2>&1;
    )

    exit_code="$?"
    if [[ "$exit_code" != "0" ]]; then
      echo "warning: npm install command failed, to see log, run: r2g_view_log";
      return 1;
    fi

    (
      # run the user's copy command
      set -eo pipefail;
      if [[ ! -z "$copy_test" ]]; then
         echo "Copying r2g smoke test fixtures to '\$HOME/.r2g/temp/project'...";
         echo "$copy_test" | bash
#         exec 3>&2; {  echo "$copy_test" | bash | prepend 'r2g-copying: ' 'cyan'; } 2>&1 1>&3 | prepend 'r2g-copying: ' 'magenta'
      fi
    )

    exit_code="$?"
    if [[ "$exit_code" != "0" ]]; then
      echo "warning: your copy command failed, to see log, run: r2g_view_log";
      return 1;
    fi

   ### see 1: https://unix.stackexchange.com/questions/442240/send-stderr-to-a-different-receiver-in-pipe
   ### see 2: https://unix.stackexchange.com/questions/442250/stderr-is-being-sent-down-pipeline-but-i-dont-want-that
    (
        # run the tests
        cd "$dest";
        set -eo pipefail
#        echo "$run_test" | bash > >(prepend 'r2g-test: ' 'yellow') 2> >(prepend 'r2g-test: ' 'red'  >&2);

        if [[ ! -z "$run_test" ]]; then
#            exec 3>&2; {  echo "$run_test" | bash | prepend 'r2g-test: ' 'cyan'; } 2>&1 1>&3 | prepend 'r2g-test: ' 'magenta'
             echo "$run_test" | bash
        else
#            exec 3>&2; {   node smoke-tester.js | prepend 'r2g-test: ' 'cyan'; } 2>&1 1>&3 | prepend 'r2g-test: ' 'magenta'
            node smoke-tester.js
        fi

        local exit_code="$?"

        if [[ "$exit_code" == "0" ]]; then
           echo -e "${r2g_green}r2g tests passed.${r2g_no_color}"
           return 0;
        fi

         echo -e "${r2g_magenta}===============================${r2g_no_color}"
         echo -e "${r2g_magenta} => Your r2g test(s) have failed.${r2g_no_color}"
         echo -e "${r2g_magenta}===============================${r2g_no_color}"
         return 1;
    )

    exit_code="$?"
    if [[ "$exit_code" != "0" ]]; then
      echo "warning: your test command failed, to see log, run: r2g_view_log";
      return 1;
    fi
}


r2g_delete(){
  hash -d "$(npm bin -g)/r2g"
  hash -d "/usr/local/bin/r2g"
  rm "$(npm bin -g)/r2g"
  rm "/usr/local/bin/r2g"
  hash -d r2g
}

r2g(){

#   unset -f r2g;

    echo "here is the executable: $0"
#    set -x;

    local r2g_gray='\033[1;30m'
    local r2g_magenta='\033[1;35m'
    local r2g_cyan='\033[1;36m'
    local r2g_orange='\033[1;33m'
    local r2g_yellow='\033[1;33m'
    local r2g_green='\033[1;32m'
    local r2g_no_color='\033[0m'

    if [ "$0" == "/bin/sh" ] || [ "$0" == "sh" ]; then
      echo "sh is stealing bash sunshine.";
      return 1;
    fi

  (
      set -e;
#      set +o posix;

      r2g_internal "$@"  \
      2> >( while read line; do echo -e "${r2g_magenta}r2g:${r2g_no_color} $line"; done ) \
      1> >( while read line; do echo -e "${r2g_gray}r2g:${r2g_no_color} $line"; done )
  )

    exit_code="$?"
    if [[ "$exit_code" != "0" ]]; then
        echo -e "${r2g_magenta}r2g experienced an error, to see log, run: r2g_view_log${r2g_no_color}";
        return 1;
    fi
}


export -f r2g_internal;
export -f r2g;
export -f r2g_match_arg;
export -f r2g_get_latest_source;
export -f r2g_open;
export -f r2g_home;
export -f r2g_project_root;
export -f r2g_view_log;
export -f r2g_uninstall;



