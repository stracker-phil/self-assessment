#!/bin/bash

if [ "run-test" != "$LOAD_SUBMODULE" ]; then
  source "$(dirname $0)/lib/script.bash"
fi

usage() {
  title "Usage"
  show_cmd "$0" "php  " "<options>"
  show_cmd "$0" "js   " "<options>"
  show_cmd "$0" "jest " "<options>"
  show_cmd "$0" "cs   "

  show "Executes a test-suite using either Codeception (PHP), CodeceptJS (JS) or Jest (JS)."

  show_param "php" "Run a PHP test-suite using Codeception"
  show_param "js" "Run end-to-end tests in the browser using CodeceptJS"
  show_param "jest" "Run JS unit tests using Jest"
  show_param "cs" "Check code style against elegant themes phpcs standards"
  show_param "--project" "Absolute path to the project folder that contains config.bash"

  if [ 1 -eq $flags ] && [ $flag_php ]; then
    title "Options for 'php'"
  elif [ 1 -eq $flags ] && [ $flag_js ]; then
    title "Options for 'js'"
    show_param "--headless" "Run tests in headless mode."
    show_param "--workers=<n>" "Assigns <n> workers to the test - only used in headless mode. Default is 1"
    show_param "--debug" "Output detailed test feedback. Only used when not in headless mode."
    show_param "--tests" ""
    show_param "--features" ""
    show_param "--profile=<profile>" ""
  elif [ 1 -eq $flags ] && [ $flag_jest ]; then
    title "Options for 'jest'"
  fi

  show_help_error "$@"
  exit 0
}

# ----------------------------------------------------------------------

if [ "run-test" != "$LOAD_SUBMODULE" ]; then
  flag_php=$(has_param "php")
  flag_js=$(has_param "js")
  flag_jest=$(has_param "jest")
  flag_cs=$(has_param "cs")
  remove_param "php js jest cs"

  flags=0
  [ $flag_php ] && ((flags++))
  [ $flag_js ] && ((flags++))
  [ $flag_jest ] && ((flags++))
  [ $flag_cs ] && ((flags++))

  show_help

  if [ 0 -eq $flags ]; then
    usage "Please specify the operation for this command: 'php', 'js', 'jest' or 'cs'."
  elif [ 1 -lt $flags ]; then
    usage "Please specify only one operation 'php', 'js', 'jest' or 'cs', but not multiple options."
  fi

  if [ ! -d "$dev_dir"/vendor ] || [ ! -f "$dev_dir"/vendor/bin/codecept ]; then
    show_fail "Please set up the test environment via update-project.sh"
  fi

fi

# ----------------------------------------------------------------------

#
# Run Codeception tests (PHP).
function run_tests_php() {
  suite=${PARAMS[0]}
  title "PHP tests with Codeception ($suite)"
  params="--config=./_config/codeception.yml --steps"

  if [ ${#PARAMS[@]} -gt 0 ]; then
    params="$params ${PARAMS[@]}"
  fi

  qa_run_tests "php ../vendor/bin/codecept" "run $params"
}

#
# Run end-to-end tests in browser (CodeceptJS).
function run_tests_js() {
  title "End-to-end tests in CodeceptJS"

  params="--config ./_config/codecept.conf.js"

  if [ $(has_param "--headless") ]; then
    workers=$(int $(get_param_value "--workers --worker"))
    [ $workers -lt 1 ] && workers=1
    remove_param "--workers --worker --headless"

    if [ $(has_param "--steps") ]; then
      params="$params --steps"
    fi

    export CC_MODE=headless
  else
    workers=1
    export CC_MODE=browser
    params="$params --steps"

    if [ $(has_param "--debug") ]; then
      params="$params --debug"
      remove_param "--debug"
    fi
  fi

  if [ $(has_param "--tests") ]; then
    params="$params --tests"
    remove_param "--tests"
  fi

  if [ $(has_param "--features") ]; then
    params="$params --features"
    remove_param "--features"
  fi

  if [ $(has_param "--profile") ]; then
    params="$params --profile $(get_param_value "--profile")"
    remove_param "--profile" 2
  fi

  remove_param "--steps"

  if [ ${#PARAMS[@]} -gt 0 ]; then
    params="$params --grep ${PARAMS[@]}"
  fi

  # Run tests!
  if [ $workers -gt 1 ]; then
    qa_run_tests "npx codeceptjs" "run-workers $workers $params"
  else
    qa_run_tests "npx codeceptjs" "run $params"
  fi
}

#
# Run JS unit tests (Jest).
function run_tests_jest() {
  title "JS Unit tests in Jest"

  params="--config=./_config/jest.config.js"

  if [ ${#PARAMS[@]} -gt 0 ]; then
    params="${PARAMS[@]} $params"
  fi

  qa_run_tests "jest" "$params"
}

#
# Check code style with phpcs.
function run_tests_cs() {
  title "Review code style with phpcs"

  show_val "Update standards from github ..."
  if [ ! -d "$phpcs_path" ]; then
    (git clone https://github.com/elegantthemes/marketplace-phpcs/ "$phpcs_path")
  fi

  networksetup -setv6off Wi-Fi
  res=$(cd "$phpcs_path" && git pull --rebase && composer install --no-interaction 2>&1)
  networksetup -setv6automatic Wi-Fi
  show_res "$res"

  show_val "Checking standards ..."

  # -p .. show progress
  # -s .. show sniff codes in output
  res=$(
    "$phpcs_path"/vendor/bin/phpcs \
      -p \
      -s \
      --extensions=php \
      --ignore=/bin/*,/node_modules/*,vendor/*,/tests/*,/build/*,wp-config.php \
      --standard="$phpcs_path/ruleset.xml" \
      "$dev_dir"
  )

  show_res "$res"

  if [[ $res =~ "FOUND " ]]; then
    show_fail "Code does not meet Divi Marketplace standards"
  fi

  show_val "Code is valid!"
}

# ----------------------------------------------------------------------

if [ "run-test" != "$LOAD_SUBMODULE" ]; then
  if [ $flag_php ]; then
    run_tests_php
  elif [ $flag_js ]; then
    run_tests_js
  elif [ $flag_jest ]; then
    run_tests_jest
  elif [ $flag_cs ]; then
    run_tests_cs
  fi
else
  LOAD_SUBMODULE=
fi
