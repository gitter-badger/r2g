#!/usr/bin/env bash

set -e;

if [[ "$r2g_skip_postinstall" == "yes" ]]; then
  echo "skipping r2g postinstall routine.";
  exit 0;
fi


if [[ "$docker_r2g_in_container" == "yes" ]]; then
  echo "skipping r2g postinstall routine because we are in a docker image/container.";
  exit 0;
fi


export r2g_skip_postinstall="yes";
r2g_exec="r2g";

if [[ "$oresoftware_local_dev" == "yes" ]]; then
    echo "Running the r2g postinstall script in oresoftware local development env."
fi

r2g_gray='\033[1;30m'
r2g_magenta='\033[1;35m'
r2g_cyan='\033[1;36m'
r2g_orange='\033[1;33m'
r2g_green='\033[1;32m'
r2g_no_color='\033[0m'

mkdir -p "$HOME/.r2g/temp/project" || {
  echo "could not create directory => '$HOME/.r2g/temp/project'...";
}


mkdir -p "$HOME/.oresoftware" && {

  (
    curl -H 'Cache-Control: no-cache' \
    "https://cdn.rawgit.com/ORESoftware/shell/a49dc374/shell.sh?$(date +%s)" \
    --output "$HOME/.oresoftware/shell.sh" 2>&1 || {
           echo "curl command failed to read shell.sh, now we should try wget..."
    }
  ) &

} || {

  echo "could not create '$HOME/.oresoftware'";
  exit 1;

}

mkdir -p "$HOME/.oresoftware/bash" && {
    cat r2g.sh > "$HOME/.oresoftware/bash/r2g.sh" || {
      echo "could not copy r2g shell file to user home.";
    }
}


mkdir -p "$HOME/.oresoftware/nodejs/node_modules" && {


    [ ! -f "$HOME/.oresoftware/nodejs/package.json" ]  && {
        curl -H 'Cache-Control: no-cache' \
          "https://cdn.rawgit.com/ORESoftware/shell/a49dc374/assets/package.json?$(date +%s)" \
            --output "$HOME/.oresoftware/nodejs/package.json" 2>&1 || {
            echo "curl command failed to read package.json, now we should try wget..."
      }
    }

    (
      cd "$HOME/.oresoftware/nodejs" && npm install --loglevel=warn "$r2g_exec"  || {
        echo "could not install r2g in user home.";
       }
    )


} || {

   echo "could not create a 'nodejs' dir in $HOME/oresoftware directory."
}

# wait for background processes to finish
wait;

echo -e "${r2g_green}r2g was installed successfully.${r2g_no_color}";
echo -e "Add the following line to your .bashrc/.bash_profile files:";
echo -e "${r2g_cyan} . \"\$HOME/.oresoftware/shell.sh\"${r2g_no_color}";
echo " ";


