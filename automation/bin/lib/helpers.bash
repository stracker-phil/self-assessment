# The helper functions in this file are used by manual scripts (like build.sh)
# and GitHub workflow scripts (like action/build.sh).


#
# sed -i works differently on macOS and Linux.
# This function is a wrapper that calls the OS-relevant sed syntax.
sed_i() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS uses BSD sed
        sed -Ei '' "$@"
    else
        # Linux uses GNU sed
        sed -Ei "$@"
    fi
}

#
# Escape slashes, brackets, and single/double quotes in text, for use in sed
# http://url.com/ --> http:\/\/url.com\/
# $var["test"] --> $var\[\"test\"\]
function esc_vars() {
  local text="$*"
  text=${text//\//\\/}
  text=${text//\"/\\\"}
  text=${text//\'/\'}
  text=${text//\[/\\[}
  text=${text//\]/\\]}
  echo "$text"
}

#
# Validates the conditional comments in a file and confirms
# that the number of opening and closing comments is identical.
#
# Usage:
# err=$(validate_conditional "file.php" "condition")
# if [ -n "$err" ]; then echo $err && exit; fi
function validate_conditional() {
  file="$1"
  type="$2"

  # File could have been deleted by previous keep_conditional check.
  if [ ! -f "$file" ]; then
    return
  fi

  count_block_start=$(grep -c "/\* start $type block \*/" <"$file")
  count_block_end=$(grep -c "/\* end $type block \*/" <"$file")
  count_inline_start=$(grep -c "/\* start $type \*/" <"$file")
  count_inline_end=$(grep -c "/\* end $type \*/" <"$file")

  if [ "$count_block_start" != "$count_block_end" ]; then
    echo "[$type block] mismatch: $count_block_start / $count_block_end - $file"
    return
  fi
  if [ "$count_block_start" != "$count_block_end" ]; then
    echo "[$type inline] mismatch: $count_inline_start / $count_inline_end - $file"
    return
  fi
}

#
# Removes conditional comments from a file while
# preserving the content between those comments.
#
# Usage:
# keep_conditional "file.php" "condition"
function keep_conditional() {
  file="$1"
  type="$2"

  # File could have been deleted by previous keep_conditional check.
  if [ ! -f "$file" ]; then
    return
  fi

  mismatch=$(validate_conditional "$file" "$type")
  if [ -n "$mismatch" ]; then
    echo "$mismatch"
    exit 1
  fi

  # Remove the entire file, if the "@type exclude file" marker is present.
  if grep -q "\*  *@$type  *exclude file" "$file"; then
    rm "$file"
  else
    sed_i "/\/\* start $type block \*\//d" "$file"
    sed_i "/\/\* end $type block \*\//d" "$file"
    sed_i "/\/\/ @start-$type-block/d" "$file"
    sed_i "/\/\/ @end-$type-block/d" "$file"
    sed_i "s/\/\* start $type \*\///g" "$file"
    sed_i "s/\/\* end $type \*\///g" "$file"
    sed_i "s/[[:space:]]*\/\/ @$type-only[[:space:]]*//g" "$file"
  fi
}

#
# Removes conditional comments from a file and also
# removes the code between those comments.
#
# Usage:
# remove_conditional "file.php" "condition"
function remove_conditional() {
  file="$1"
  type="$2"

  # File could have been deleted by previous keep_conditional check.
  if [ ! -f "$file" ]; then
    return
  fi

  mismatch=$(validate_conditional "$file" "$type")
  if [ -n "$mismatch" ]; then
    echo "$mismatch"
    exit 1
  fi

  sed_i "/\/\* start $type block \*\//,/\/\* end $type block \*\//d" "$file"
  sed_i "/\/\/ @start-$type-block/,/\/\/ @end-$type-block/d" "$file"
  sed_i "s/\/\* start $type \*\/.*\/\* end $type \*\///g" "$file"
  sed_i "/\/\/ @$type-only/d" "$file"
}
