# Make the main script parameters available in all functions.
PARAMS=("$@")

if [ "$(has_param "--project")" ]; then
  PROJECT_DIR=$(get_param_value "--project")
  PROJECT_DIR=${PROJECT_DIR%/}
  remove_param "--project"
else
  PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
  PROJECT_DIR=${PROJECT_DIR%/}
fi

#
# Load project configuration.
if [ -z "$PROJECT_DIR" ] || [ ! -f "$PROJECT_DIR"/config.bash ]; then
  if [ "no" != "$REQUIRE_PROJECT_CONFIG" ]; then
    show_help

    show_fail "Could not locate the project configuration" "Path: $PROJECT_DIR/config.bash"
  fi
fi

if [ -f "$PROJECT_DIR"/config.bash ]; then
  source "$PROJECT_DIR"/config.bash
fi

#
# Load custom configuration for local machine, if present.
if [ -f "$PROJECT_DIR"/config.local.bash ]; then
  source "$PROJECT_DIR"/config.local.bash
fi

#
# ----------------------------------------------------------------------
#

if [ "no" != "$REQUIRE_PROJECT_CONFIG" ]; then
  #
  # Validate project configuration.
  plugin_name=${plugin_name:?"Missing value in 'config.bash'"}
  text_domain=${text_domain:?"Missing value in 'config.bash'"}

  local_dev_user=${local_dev_user:?"Missing value in 'config.bash'"}
  local_dev_pass=${local_dev_pass:?"Missing value in 'config.bash'"}
  local_dev_url=${local_dev_url:?"Missing value in 'config.bash'"}
  local_dev_root_dir=${local_dev_root_dir:?"Missing value in 'config.bash'"}

  local_stage_user=${local_stage_user:?"Missing value in 'config.bash'"}
  local_stage_pass=${local_stage_pass:?"Missing value in 'config.bash'"}
  local_stage_url=${local_stage_url:?"Missing value in 'config.bash'"}
  local_stage_root_dir=${local_stage_root_dir:?"Missing value in 'config.bash'"}
else
  if [ -n "$PROJECT_DIR" ]; then
    if [ -z "$plugin_name" ]; then
      plugin_name=$(basename "$PROJECT_DIR")
    fi
    if [ -z "$text_domain" ]; then
      text_domain=$(basename "$PROJECT_DIR")
    fi
  fi
fi

plugin_main_file=${plugin_main_file-"plugin.php"}

#
# Build local environment paths.
dev_dir=${dev_dir-"$PROJECT_DIR"}
stage_site_path=${stage_site_path-"/Users/philipp/Sites/public/plugin-test"}
deploy_root_path=${deploy_root_path-"/Users/philipp/Dropbox/Divimode/Deployment"}

# List of dirs/files to exclude from the build-folders
build_exclude=${build_exclude-()}

stage_dir=$stage_site_path/wp-content/plugins/$plugin_name
archive_dir=$deploy_root_path/svn/$plugin_name
zip_dir=$deploy_root_path/$plugin_name
plugin_main_path=$dev_dir/$plugin_main_file
tests_dir=$dev_dir/tests
snapshot_dir=${snapshot_dir-"$tests_dir/_data"}

dev_site_path=$dev_dir
while [ "$dev_site_path" != "" ] && [ ! -f "$dev_site_path/wp-config.php" ]; do
  dev_site_path=$(dirname "$dev_site_path")
done

phpcs_path="$SCRIPT_DIR"/phpcs-marketplace

#
# Configuration for automated tests (QA).
#
# Use a separate testing-DB and NOT the wp-config details!
# Automated tests will modify this DB and import a predefined snapshot.

# QA: Isolated test site (do not use Dev DB here!).
test_db_name=${test_db_name-"wp_codeception_test"}
test_db_user=${test_db_user-"wp_test"}
test_db_pass=${test_db_pass-"wp_test"}
test_db_prefix=${test_db_prefix-"wp_"}
test_db_host=${test_db_host-"127.0.0.1"}
test_wp_version=${test_wp_version-"latest"}

# QA: Dev site.
dev_admin_user=${dev_admin_user-$local_dev_user}
dev_admin_pass=${dev_admin_pass-$local_dev_pass}
dev_url=${dev_url-$local_dev_url}
dev_domain=${dev_domain-${dev_url#*//}}
dev_wp_path=${dev_wp_path-$local_dev_root_dir}

# QA: Stage site.
stage_admin_user=${stage_admin_user-$local_stage_user}
stage_admin_pass=${stage_admin_pass-$local_stage_pass}
stage_url=${stage_url-$local_stage_url}
stage_domain=${stage_domain-${stage_url#*//}}
stage_wp_path=${stage_wp_path-$local_stage_root_dir}

#
# Displays the current script configuration.
_info() {
  SCRIPT_VAL_IDENT=22
  title "Environment"
  dump_var "USE_COLOR"
  dump_var "SCRIPT_DIR"
  dump_var "DEV_WEB_SERVER"
  dump_var "DEV_DB_SERVER"
  dump_var "DEV_DB_HOST"

  title "Project"
  dump_var "PROJECT_DIR"
  dump_var "plugin_main_file"
  dump_var "plugin_name"
  dump_var "text_domain"

  title "Local Dev Site"
  dump_var "local_dev_user"
  dump_var "local_dev_pass"
  dump_var "local_dev_url"
  dump_var "local_dev_root_dir"

  title "Local Stage Site"
  dump_var "local_stage_user"
  dump_var "local_stage_pass"
  dump_var "local_stage_url"
  dump_var "local_stage_root_dir"

  title "Sites"
  dump_var "dev_site_path"
  dump_var "stage_site_path"
  dump_var "deploy_root_path"

  title "Deployment"
  dump_var "dev_dir"
  dump_var "stage_dir"
  dump_var "archive_dir"
  dump_var "zip_dir"
  dump_var "plugin_main_path"

  title "QA: General"
  dump_var "tests_dir"
  dump_var "snapshot_dir"
  dump_var "phpcs_path"

  title "QA: Isolated test site"
  dump_var "test_db_name"
  dump_var "test_db_user"
  dump_var "test_db_pass"
  dump_var "test_db_prefix"
  dump_var "test_db_host"
  dump_var "test_wp_version"

  title "QA: Dev site"
  dump_var "dev_admin_user"
  dump_var "dev_admin_pass"
  dump_var "dev_url"
  dump_var "dev_domain"
  dump_var "dev_wp_path"

  title "QA: Stage site"
  dump_var "stage_admin_user"
  dump_var "stage_admin_pass"
  dump_var "stage_url"
  dump_var "stage_domain"
  dump_var "stage_wp_path"

  title "Script"
  SCRIPT_VAL_IDENT=${#0}

  # SCRIPT_VAL_IDENT is used by show_val()
  export SCRIPT_VAL_IDENT

  show_val "$0" "--project=$PROJECT_DIR"
  for var in "${PARAMS[@]}"; do
    show_val "" "$var"
  done

  exit 0
}

if [ "$(has_param "-i --info")" ]; then
  _info
fi
remove_param "-i --info"

# --- export configuration ---

export PARAMS
export PROJECT_DIR

# Validate project configuration.
export plugin_name
export text_domain

export local_dev_user
export local_dev_pass
export local_dev_url
export local_dev_root_dir

export local_stage_user
export local_stage_pass
export local_stage_url
export local_stage_root_dir

export plugin_name
export text_domain

export plugin_main_file

# Build local environment paths.
export dev_dir
export stage_site_path
export deploy_root_path

# List of dirs/files to exclude from the build-folders
export build_exclude

export stage_dir
export archive_dir
export zip_dir
export plugin_main_path
export tests_dir
export snapshot_dir
export dev_site_path
export phpcs_path

export test_db_name
export test_db_user
export test_db_pass
export test_db_prefix
export test_db_host
export test_wp_version

export dev_admin_user
export dev_admin_pass
export dev_url
export dev_domain
export dev_wp_path

export stage_admin_user
export stage_admin_pass
export stage_url
export stage_domain
export stage_wp_path
