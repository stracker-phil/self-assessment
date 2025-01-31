#
# Determine the path to the current script.
# shellcheck disable=SC2005
SCRIPT_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
export SCRIPT_DIR

COLS=${COLS-80}

#
# Run composer command.
function composer() {
  local composer=/Applications/MAMP/bin/php/composer

  if [ ! -f "$composer" ]; then
    separator
    show_val "bin path" "$composer"
    show_fail "Composer not found!"
  fi

  # shellcheck disable=SC2068
  $composer $@
}

#
# Run a WP-CLI command.
function wp() {
  local wp

  if [ "mamp" == "$DEV_WEB_SERVER" ]; then
    # WP CLI on current (host) machine.
    wp=/usr/local/bin/wp

    if [ ! -f "$wp" ]; then
      wp=/Applications/MAMP/Library/bin/wp
    fi

    if [ ! -f "$wp" ]; then
      separator
      show_fail "WP-CLI not found!"
    fi

    echo "$(cd "$PROJECT_DIR" && $wp "$@")"
  else
    # Support for different web server.
    echo "TODO: Add support for $DEV_WEB_SERVER"
    exit 1
  fi
}

#
# Clears the console screen.
function clear() {
  if [ "yes" == "$USE_COLOR" ]; then
    # shellcheck disable=SC2034
    for i in {1..40}; do
      echo
    done

    /usr/bin/clear
    printf "\33c\e[3J"

    if [ -f /usr/bin/osascript ]; then
      /usr/bin/osascript -e 'tell application "System Events" to tell process "Terminal" to keystroke "k" using command down'
    fi
  else
    /usr/bin/clear
  fi
}

#
# Run command and captures all returns output of that command
function run() {
  LINES=20 COLUMNS=80 script -q /dev/null $@ 2>&1
}

#
# Wrapper for $(tput) that supports both color and monochrome output.
#
# tput options:
# https://www.gnu.org/software/termutils/manual/termutils-2.0/html_chapter/tput_1.html
#
# See colors:
#  printf '\e[%sm▒' {30..37} 0; echo
#
#  Color     Value   RGB
#  black       0     0, 0, 0
#  red         1     max,0,0
#  green       2     0,max,0
#  yellow      3     max,max,0
#  blue        4     0,0,max
#  magenta     5     max,0,max
#  cyan        6     0,max,max
#  white       7     max,max,max
#
function tput() {
  if [ -n "$USE_COLOR" ]; then
    /usr/bin/tput "$@"
  fi
}

#
# Returns the length of the longest word/term in the array.
function max_word_len() {
  local longest=0

  for word in "$@"; do
    if [ ${#word} -gt $longest ]; then
      longest=${#word}
    fi
  done

  echo "$longest"
}

#
# Converts a string to an integer.
function int() {
  printf '%d' "$(expr "${1:-}" : '[^0-9]*\([0-9]*\)' 2>/dev/null)" || :
}

#
# Pads a string to the specified length using a custom character
#
# Usage:
# term=$(pad_str '-' -20 'My Term') # Returns 'My Term-------------'
# term=$(pad_str '-'  20 'My Term') # Returns '-------------My Term'
# term=$(pad_str '-'   5 'My Term') # Returns 'My Term'
function pad_str() {
  local char
  local len
  local term
  local side

  char="$1"
  len="$(int "$2")"
  term="$3"
  side="left"

  if [ $((len)) -lt 0 ]; then
    len=$((len * -1))
    side=right
  fi

  if [ ${#term} -lt $len ]; then
    while ((${#term} < len)); do
      if [ 'left' == $side ]; then
        term+=$char
      else
        term="$char$term"
      fi
    done
  fi

  echo "$term"
}

#
# Adds a blank line between two different output types (e.g. between "title" and "show_val")
function show_gap() {
  local cmd=$1

  if [ -z "$cmd" ]; then
    echo
  elif [ "$cmd" != "$prev_output_cmd" ]; then
    prev_output_cmd="$cmd"
    echo
  fi
}

#
# Output a separator line.
function separator() {
  show_gap "separator"
  echo "$(tput setaf 8)$(pad_str '-' 40 '')$(tput sgr0)"
}

#
# Output a visually highlighted title
function title() {
  local msg=$1
  local col=${2-5}

  show_gap "title"
  echo "$(tput setaf "$col")=== $(tput bold)$msg$(tput sgr0) $(tput setaf "$col")===$(tput sgr0)"
}

#
# Displays multiline text where each line is indented.
# Usually used in combination with "run":
# show_res "$(cd dir && run some-command 2>&1)"
function show_res() {
  show_gap "show_res"

  while read -r line; do
    show_res_line "$line"
  done <<<"$@"
}

function show_res_line() {
  # Remove the trailing carriage return.
  line=${line%$'\r'}

  # When the line contains multiple carriage returns, only display the last segment
  # For example, a progress bar adds multiple \r entries to update the progress.
  line=${line##*$'\r'}

  echo "$(tput dim)$(tput setaf 6)   | $(tput sgr0)$line"
}

#
# Display an error message and exit the process.
function show_fail() {
  title "ERROR" 1
  show_res "$(echo "$@" | fmt -w "$COLS")"

  exit 1
}

#
# Displays a value as bullet-list.
function show_val() {
  show_gap "show_val"

  local label="$1"
  local value="$2"
  local col_bullet=3
  local col_label=7
  local col_value=4

  local indent_col
  local count
  local bullet
  local prefix
  local indent
  local line

  indent_col=${SCRIPT_VAL_IDENT:-15}
  count=$((indent_col > ${#label} ? indent_col - ${#label} : 0))
  bullet="*"
  prefix="$bullet"
  indent=$(printf "%${count}s")

  if [ -n "$label" ]; then
    local spaces=${label%%[^ ]*}
    label="${label#"${label%%[![:space:]]*}"}"

    if [ -n "$spaces" ]; then
      bullet="-"
    fi

    case "$label" in
    "✔︎"* | "✓"*)
      bullet="✔"
      col_bullet=2
      label=${label#"✔︎"}
      label=${label#"✓"}
      label="${label#"${label%%[![:space:]]*}"}"
      ;;
    "✘"* | "✗"*)
      bullet="✘"
      col_bullet=1
      label=${label#"✘"}
      label=${label#"✗"}
      label="${label#"${label%%[![:space:]]*}"}"
      ;;
    esac

    prefix="$spaces$bullet"

    if [ -z "$value" ]; then
      indent=""

      if [ -z "$spaces" ]; then
        col_label=$col_value
      fi
    fi
  else
    prefix=" "
  fi

  if [ -n "$label" ]; then
    indent="${indent// /·}"
  fi

  # Calculate prefix len before adding the tput-formatting.
  prefix_len=$((${#prefix} + ${#label} + ${#indent}))

  prefix="$(tput setaf $col_bullet)$(tput dim)$prefix$(tput sgr0)"
  label="$(tput setaf $col_label)$label$(tput sgr0)"

  if [ -n "$value" ]; then
    indent="$(tput setaf $col_bullet)$(tput dim)$indent$(tput sgr0)"

    if ((prefix_len < COLS)); then
      line_ident=$(printf "%${indent_col}s")
      lines=$(echo "$value" | fmt -w $((COLS - prefix_len)))
      line1="$(echo "$lines" | head -1)"
      lines=$(echo "$lines" | tail -n +2 | fmt -w $((COLS - indent_col)) | sed "s/^/     $line_ident/")

      if ((${#lines} > 0)); then
        line1="$line1\n"
      fi
    else
      indent="$indent\n"
      lines=$(echo "$value" | fmt -w $((COLS - 8)) | sed 's/^/        /')
    fi

    value="$(tput setaf $col_value)$line1$lines$(tput sgr0)"
  fi

  echo " $prefix $label $indent $value"
}

#
# Outputs the specified text and adds line-breaks at a certain column when needed.
function show() {
  show_gap "show"
  echo "$@" | fmt -w "$COLS"
}

#
# Outputs parameter information (for usage help)
function show_param() {
  show_gap "show_param"

  local param=$1
  local explain=$2
  local lines=
  local line1=
  local sep=

  param=$(pad_str " " 4 "$param")
  if [ -n "$explain" ]; then
    lines=$(echo "$explain" | fmt -w $((COLS - 4 - ${#param})))
    line1=$(echo "$lines" | head -1)
    lines=$(echo "$lines" | tail -n +2 | fmt -w $((COLS - 8)) | sed 's/^/        /')

    sep=".."
    explain=$(echo -e "$line1\n$lines")
  fi

  echo "$(tput setaf 6)$param$(tput sgr0) $sep $explain"
}

#
# Displays a command (e.g. for usage instructions)
function show_cmd() {
  show_gap "show_cmd"

  local cmd=$1
  local param=$2
  shift
  shift

  if [ -n "$param" ]; then
    param="$param "
  fi

  echo -e "$(tput setaf 6) \$$(tput sgr0) $(tput setaf 4)$cmd $(tput setaf 4)$(tput bold)$param$(tput sgr0)$(tput setaf 4)$*$(tput sgr0)"
}

#
# Pause the script until the user presses any key.
function pause() {
  show_gap "pause"
  if [ -z "$1" ]; then
    msg="Press any key to continue, or Ctrl-C to cancel ..."
  else
    msg="$1"
  fi

  if [ "dumb" == "$TERM" ]; then
    echo "$msg"
    read -p " >  " -n 1 -r
  else
    read -p "$msg  " -n 1 -r
  fi

  if [ ${#REPLY} -ne 0 ]; then
    echo
  fi
}

#
# Asks the user for confirmation and exits when the user chooses to cancel.
function maybe_stop() {
  if [ -z "$1" ]; then
    msg="Continue?  [yN]"
  else
    msg="$1  [yN]"
  fi

  separator

  pause "$msg"

  separator

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n\n-- $(tput setaf 3)Process stopped$(tput sgr0) --\n"
    exit 1
  fi
}

#
# Test, if a string starts with a substring.
#
# Usage:
# if [ beginsWith "prefix" "$haystack" ]
function beginsWith() {
  case $2 in
  "$1"*)
    echo "yes"
    true
    ;;
  *)
    false
    ;;
  esac
}

#
# Checks, if the script was called with a specific command line parameter.
# https://stackoverflow.com/a/63919629/313501
#
# Usage:
# has_param needle [haystack]
#   needle .. string containing one or more params to look for
#   haystack .. either an array or empty. When empty, the global $PARAMS array is scanned.
#   returns "yes" or empty string.
#
# Samples:
#
# if [ $(has_param "-q --quick") ]; then       # Scan $PARAMS array
# if [ $(has_param "-q --quick" "$@") ]; then  # Scans $@ parameter
# flag_quick=$(has_param "-q --quick")         # "yes" or ""
# flag_quick=$(has_param "-q --quick" "$@")    # "yes" or ""
function has_param() {
  local terms="$1"
  local args=()
  shift

  if [ 0 == $# ]; then
    args=("${PARAMS[@]}")
  else
    args=("$@")
  fi

  for arg in "${args[@]}"; do
    for term in $terms; do
      if [ "$arg" == "$term" ] || [ "$(beginsWith "$term=" "$arg")" ]; then
        echo "yes"
        return
      fi
    done
  done
  false
}

#
# Gets the value of a command line parameter.
#
# Usage:
#
# script.sh -f "filter value":
# script.sh -f="filter value":
# filter=$(get_param_value "-f --filter" "$@")  # returns "filter value"
function get_param_value() {
  local terms="$1"
  local args=()
  shift

  if [ 0 == $# ]; then
    args=("${PARAMS[@]}")
  else
    args=("$@")
  fi

  local num_args=${#args[@]}
  for ((i = 0; i < num_args; i++)); do
    local arg="${args[$i]}"

    for term in $terms; do
      if [ "$arg" == "$term" ]; then
        # Found "--term value"
        echo "${args[((i + 1))]}"
        return
      elif [ "$(beginsWith "$term=" "$arg")" ]; then
        # Found "--term=value"
        echo "${arg#$term=}"
        return
      fi
    done
    shift
  done
}

#
# Removes the given parameter from the argument list.
#
# Usage:
# remove_param needle [haystack]
#    needle .. string containing one or more parameters to remove
#    haystack .. optional. array to filter. If omitted, the global $PARAMS list is scanned
#    Returns the modified haystack.
#    When no haystack is given, the function directly updates the $PARAMS list.
#
# Samples:
# args=$(remove_param "-f --filter" 2)               # removes "-f <val>" and "--filter <val>" and "-f=<val>" from $PARAMS
# args=$(remove_param "-f --filter" 2 "${args[@]}")  # removes "-f <val>" and "--filter <val>" and "-f=<val>"
# args=$(remove_param "-q --quick" 1 "${args[@]}")   # removes "-q" and "--quick" and "--quick=<val>"
# args=($(remove_param "--tests" 1 "${args[@]}")); set -- "${args[@]}"
function remove_param() {
  local terms="$1"
  local num=$2
  local args=()
  local res=()
  local is_global=no
  shift
  shift

  if [ -z "$num" ] || [ "$num" -lt 1 ]; then
    num=1
  fi
  if [ 0 == $# ]; then
    args=("${PARAMS[@]}")
    is_global=yes
  else
    args=("$@")
  fi

  local num_args=${#args[@]}
  for ((i = 0; i < num_args; i++)); do
    local arg="${args[$i]}"

    for term in $terms; do
      if [ "$arg" == "$term" ]; then
        i=$((i + num - 1))
        continue 2
      elif [ "$(beginsWith "$term=" "$arg")" ]; then
        continue 2
      fi
    done

    res+=("$arg")
  done

  if [ "yes" == $is_global ]; then
    PARAMS=("${res[@]}")
  else
    echo "${res[@]}"
  fi
}

#
# Parameter is the path to a git repository.
function is_git_committed() {
  local git_path=$1
  local changes=

  if [ -z "$git_path" ]; then
    changes=$(git status -s)
  else
    changes=$(git -C "$git_path" status -s)
  fi

  if [ -z "$changes" ]; then
    # Return "yes" when everything is committed.
    echo "yes"
    return
  fi

  # Uncommitted changes are found.
  false
}

#
# Automated testing: Clears the output folder.
function qa_clean_results() {
  if [ -n "$tests_dir" ]; then
    (cd "$tests_dir" && rm -rf _output && mkdir _output)
    (cd "$tests_dir" && rm -rf _screenshots/diff && mkdir _screenshots/diff)
    printf "*\n!.gitignore" >"$tests_dir/"_output/.gitignore
    printf "*\n!.gitignore" >"$tests_dir/"_screenshots/diff/.gitignore
  fi
}

#
# Automated testing: Runs tests and displays some stats.
function qa_run_tests() {
  local cmd=$1
  local params=$2
  local start_time
  local end_time
  local duration

  if [ ! -d "$tests_dir" ]; then
    show_val "Skipped tests, because 'tests' folder does not exist"
    return
  fi

  qa_clean_results

  start_time=$(date +%s)

  { # try
    show_gap "show_res"

    (cd "$tests_dir" && run "$cmd" "$params")
  } || { # catch
    show_gap "run_tests"
    echo "[$(tput bold)$(tput setaf 1)ERROR$(tput sgr0)] Run failed!"

    if [ -z "$CC_SILENT" ] && [ "jest" != "$cmd" ]; then
      echo "Inspect contents of _output directory for more details"
    fi
  }

  if [ -z "$CC_SILENT" ]; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo "$(tput setaf 3)─┐$(tput sgr0)"
    echo "$(tput setaf 3) │ $(tput sgr0)$(tput dim)Command took $(tput sgr0)$(tput bold)$duration sec$(tput sgr0)$(tput dim) to complete:$(tput sgr0)"
    echo "$(tput setaf 3) └ \$$(tput sgr0) $(tput setaf 4)$cmd $(tput bold)$params$(tput sgr0)"
  fi
}

#
# Outputs a variable.
function dump_var() {
  local var=$1
  show_val "$var" "${!var}"
}

#
# Output the usage help, when param -h or --help are present
function show_help() {
  if [ "$(has_param "-h --help")" ]; then
    remove_param "-h --help"

    if [[ $(type -t usage) == "function" ]]; then
      usage
    else
      echo "- No usage instructions available -"
    fi

    exit 0
  fi
}

#
# Output an error message in the usage page.
function show_help_error() {
  if [ -n "$1" ]; then
    title "Error" 1
    echo "$@" | fmt -w "$COLS"
  fi
}

#
# Test, if color output is supported.
USE_COLOR=""
if /usr/bin/tput Co >/dev/null 2>&1; then
  test "$(/usr/bin/tput Co)" -gt 2 && USE_COLOR=yes
elif /usr/bin/tput colors >/dev/null 2>&1; then
  test "$(/usr/bin/tput colors)" -gt 2 && USE_COLOR=yes
fi

source "$SCRIPT_DIR"/lib/helpers.bash
source "$SCRIPT_DIR"/lib/vars.bash
