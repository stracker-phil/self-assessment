#!/bin/bash

# Used by the GitHub deployment action.
#
# To run it locally:
# 1. set up node (check version in .github/workflows/deployment.yml)
# 2. install dependencies: npm install
# 3. run the script in bash: bash bin/build.sh

SCRIPT_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
PROJECT_DIR=$(dirname "$(readlink -f "${SCRIPT_DIR}")")

source "$SCRIPT_DIR/lib/helpers.bash"
source "$PROJECT_DIR/config.bash"

plugin_main_path="$PROJECT_DIR/plugin.php"

# Extract the plugin version frm the main plugin file.
plugin_version=$(grep -e '\* Version:' <"$plugin_main_path" | cut -d : -f 2 | sed 's/ //g')
build_path_zip="$PROJECT_DIR/build/$plugin_name"

# Build target configuration - add more lines to generate additional packages.
build_targets=(
	"Divimode  : $PROJECT_DIR/build/divimode : $plugin_type : divimode"
	"ET-Market : $PROJECT_DIR/build/et-market : $plugin_type : etmarket"
)

# ----------------------------------------------------------------------------
# Update version numbers, just to be sure.

jsapi_file="sources/scripts/version.js"
jsapi_path="$PROJECT_DIR/$jsapi_file"
readme_path="$PROJECT_DIR/readme.txt"

sed_i "s/(const .*_VERSION = ').*(';)/\1$(esc_vars "$plugin_version")\2/g" "$plugin_main_path"

if [ -f "$jsapi_path" ]; then
	sed_i "s/([[:space:]]+version:[[:space:]]*').*(',?)/\1$(esc_vars "$plugin_version")\2/g" "$jsapi_path"
fi

if [ -f "$readme_path" ]; then
	sed_i "s/(Stable tag: ).*/\1$plugin_version/g" "$readme_path"
fi


# -----------------------------------------------------------------------------
# Pack and deploy the code.

#
# Deployment process:
#                        ┌───────┐
#                        │ REPO  │
#                        └───┬───┘
#                            │
#  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ pre process
#                            │
# ┌──────────────────────────┴──────────────────────────┐
# │                   compile assets                    │
# │              remove conditional blocks              │
# │                         ...                         │
# └──────────────────────────┬──────────────────────────┘
#                            │
#          ┌─────────────────┴─────────────────┐
# ┌────────┴────────┐                 ┌────────┴────────┐
# │    divimode     │      build      │    et-market    │
# └┬────────────────┘                 └┬────────────────┘
#  │                                   │
#  ┼ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─ ─ ─ ─ copy files/zip
#  │                                   │
#  │ ┌──────────────┐                  │ ┌──────────────┐
#  ├─┤   <plugin>   │      stage       ├─┤ <plugin>-et  │
#  │ │    files     │                  │ │    files     │
#  │ └──────────────┘                  │ └──────────────┘
#  │ ┌──────────────┐                  │ ┌──────────────┐
#  └─┤  <plugin>    │     deploy       └─┤ <plugin>-et  │
#    │     zip      │                    │     zip      │
#    └──────────────┘                    └──────────────┘
#

# -----------------------------------------------------------------------------

echo "Compile CSS and JS ..."

# when running the script locally, those folders might contain old assets.
rm -rf "$PROJECT_DIR/scripts"
rm -rf "$PROJECT_DIR/styles"

(cd "$PROJECT_DIR" && npm run asset-build 2>&1)

# Compile the Divi modules, when the includes/loader.js file is present.
if [ -f "$PROJECT_DIR/includes/loader.js" ]; then
	(cd "$PROJECT_DIR" && npm run divi-build 2>&1)
fi

# -----------------------------------------------------------------------------
# Build the deployment packages.

# when running the script locally, this folder might not be empty.
rm -rf "$PROJECT_DIR/build"

for target in "${build_targets[@]}"; do
	parts=(${target//:/ })
	build_name=${parts[0]}
	build_path=${parts[1]}
	build_type=${parts[2]}
	build_store=${parts[3]}
	zip_path="$PROJECT_DIR/build/$plugin_name-$build_store-$plugin_version.zip"

	echo "Build $build_name package ..."

	# Again, folder should not exist, but we'd like to ensure that.
	rm -rf "$build_path_zip"
	mkdir -p "$build_path_zip"

	rsync -a "$PROJECT_DIR/" "$build_path_zip" --exclude-from="$SCRIPT_DIR/lib/exclude.txt"

	# Remove pro/free remarks.
	find "$build_path_zip" -name '*.php' | while read -r build_file || [ -n "$build_file" ]; do
		sed_i "/@formatter:o/d" "$build_file"
		remove_conditional "$build_file" dev

		if [ "$build_type" == "pro" ]; then
			remove_conditional "$build_file" free
			keep_conditional "$build_file" pro
		else
			remove_conditional "$build_file" pro
			keep_conditional "$build_file" free
		fi

		if [ "$build_store" == "divimode" ]; then
			remove_conditional "$build_file" etmarket
			keep_conditional "$build_file" divimode
		else
			remove_conditional "$build_file" divimode
			keep_conditional "$build_file" etmarket
		fi
	done

	# Remove empty folders from build path.
	find "$build_path_zip" -type d -empty -delete

	# Restore an empty languages folder, if present in the dev folder.
	if [ -d "$PROJECT_DIR/languages" ]; then
		mkdir -p "$build_path_zip/languages"
	fi

	# create zip package
	if [ -f "$zip_path" ]; then
		rm "$zip_path"
	fi
	cd "$build_path_zip/.." && zip -rq "$zip_path" "$plugin_name"

	mv "$build_path_zip" "$build_path"
done
