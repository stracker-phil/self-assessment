#!/bin/bash

source "$(dirname "$0")/lib/script.bash"

usage() {
	title "Usage"
	show_cmd "$0" "" ""
	show_cmd "$0" "--config=\"/path/to/config.copy.bash\"" "--project=\"/path/to/project\""

	show_param "--config"  "Absolute path to the copy-configuration file. If not specified the default is loaded: '<project-dir>/config.copy.bash'"
	show_param "--project" "Absolute path to the project folder that contains config.bash"

	title "Description"
	show "Copies the project to a different location and performs string replacements that are defined in the copy-configuration file."
	show "Used for the 'Pro to Free' synchronization of plugins."

	show_help_error "$@"
	exit 0
}
show_help

config_file=$(get_param_value "--config")
if [ -z "$config_file" ]; then
	config_file=$PROJECT_DIR/config.copy.bash
fi

if [ -z "$config_file" ] || [ ! -e "$config_file" ]; then
	show_fail "Could not find the copy-configuration file" "Path: $config_file"
fi

#
# Load the copy configuration.
if [ -f "$config_file" ]; then
  source "$config_file"
fi

if [[ -z $copy_target ]]; then
	show_fail "Missing detail in copy-config: 'copy_target'."
fi
if [[ -z $copy_replacements ]]; then
	show_fail "Missing detail in copy-config: 'copy_replacements'."
fi
if [[ -z $copy_target_lang ]]; then
	show_fail "Missing detail in copy-config: 'copy_target_lang'."
fi
if [[ -z $copy_target_prefix ]]; then
	show_fail "Missing detail in copy-config: 'copy_target_prefix'."
fi
if [[ -z $copy_target_package ]]; then
	show_fail "Missing detail in copy-config: 'copy_target_package'."
fi
if [[ -z $copy_target_type ]]; then
	show_fail "Missing detail in copy-config: 'copy_target_type'."
fi

#
# Read all config details, ensure we are ready to sync the plugins.
# -----------------------------------------------------------------------------

copy_source=$PROJECT_DIR
plugin_version=$(grep -E '\* Version:' < "$plugin_main_path" | cut -d : -f 2 | sed 's/ //g')
from_class=$(echo "$prefix" | tr "[:lower:]" "[:upper:]")_
target_class=$(echo "$copy_target_prefix" | tr "[:lower:]" "[:upper:]")_
fn_from="${prefix}_"
fn_target="${copy_target_prefix}_"
file_selector="\* @$copy_target_type  *include file"

terms=("$package" "$text_domain" "$from_class" "$fn_from" "class-$prefix")
len=$(max_word_len "${terms[@]}")

title "Copy Project"
show_val "Source"  "$copy_source"
show_val "Target"  "$copy_target"
show_val "Version" "$plugin_version"
show_val "Project type"    "$(pad_str ' ' "$len" "$plugin_type"   ) --> $copy_target_type"
show_val "Package"         "$(pad_str ' ' "$len" "$package"       ) --> $copy_target_package"
show_val "Lang"            "$(pad_str ' ' "$len" "$text_domain"   ) --> $copy_target_lang"
show_val "Class prefix"    "$(pad_str ' ' "$len" "$from_class"    ) --> $target_class"
show_val "Function prefix" "$(pad_str ' ' "$len" "$fn_from"       ) --> $fn_target"
show_val "File prefix"     "$(pad_str ' ' "$len" "class-$prefix") --> class-$copy_target_prefix"
show_val "File selector"   "'$file_selector'"


# 2. Generate a list of matching files
# -----------------------------------------------------------------------------
title "File list"
file_list=()

# Copy all files that contain the string "* @TYPE include file" (in the header comment)
while read -r from_file || [[ $from_file ]]; do
	file_list+=("${from_file#$copy_source}")
done < <(grep -rl -e "$file_selector" "$copy_source/sources")

while read -r from_file || [[ $from_file ]]; do
	file_list+=("${from_file#$copy_source}")
done < <(grep -rl -e "$file_selector" "$copy_source/includes")

while read -r from_file || [[ $from_file ]]; do
	file_list+=("${from_file#$copy_source}")
done < <(grep -rl -e "$file_selector" "$copy_source/tests")

for file in "${file_list[@]}"; do
	show_val "$file"
done


# Ask for confirmation.
if [[ -z $(is_git_committed "$copy_target") ]]; then
	title "WARNING" 3
	show_val "The target project has uncommitted changes!"
fi

maybe_stop "Copy the project using the above configuration?"

# 3. Copy files and adjust code.
# -----------------------------------------------------------------------------

# Validate the conditional blocks.
for base_name in "${file_list[@]}"; do
	from_file=$copy_source$base_name

	if [[ ${from_file: -4} == ".php" ]]; then
		mismatch=$(validate_conditional "$from_file")
		if [[ -n $mismatch ]]; then
			show_fail "$mismatch"
		fi
	fi
done

# Copy files and modify code.
for base_name in "${file_list[@]}"; do
	from_file=$copy_source$base_name
	target_file=${base_name/"class-$prefix-"/"class-$copy_target_prefix-"}
	filename=$(basename "$target_file")
	dirname=$(dirname "$target_file")
	to_basedir=$copy_target$dirname
	to_file="$to_basedir/$filename"

	show_val "Copy $base_name ..."

	mkdir -p "$to_basedir"
	cp "$from_file" "$to_file"

	# Delete content that is marked as "pro"-only.
	# All other conditions are processed during deployment of the free plugin.
	if [ "$plugin_type" != "$copy_target_type" ]; then
		remove_conditional "$to_file" "$plugin_type"
	fi

	# Replace text-domains.
	if [[ ${to_file: -4} == ".php" ]]; then
		# Update text domains.
		sed_i "s/'$text_domain'/'$copy_target_lang'/g" "$to_file"

		# Update @package comments.
		sed_i "s/@package *$package/@package $copy_target_package/g" "$to_file"

		# Update class-name prefix.
		sed_i "s/ $from_class/ $target_class/g" "$to_file"

		# Update function prefix.
		sed_i "s/([\"'\` 	])$fn_from([a-z_]+)/\1$fn_target\2/g" "$to_file"

		# Replace plugin specific strings (defined at the top of this file).
		for replacement in "${copy_replacements[@]}"; do
			original_string=$(esc_vars "${replacement%==>*}")
			target_string=$(esc_vars "${replacement#*==>}")
			sed_i "s/$original_string/$target_string/g" "$to_file"
		done
	fi
done

# Update the plugin version.
sed_i '' "s/(\* Version: *).*/\1$plugin_version/g" "$copy_target/plugin.php"

show "The free plugin was updated to version $(tput setaf 3)$plugin_version$(tput sgr0)"

title "Finish"
show "1. Add relevant items to the $(tput setaf 3)changelog.txt$(tput sgr0) and $(tput setaf 3)readme.txt$(tput sgr0)"
show "2. Use the free plugins $(tput setaf 3)run-tests.sh --full$(tput sgr0) to validate changes"
