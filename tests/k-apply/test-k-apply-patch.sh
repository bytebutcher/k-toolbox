#!/usr/bin/env bash

# Get the directory of the script and set root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Define manifests to ignore
MANIFEST_IGNORE_LIST=(
  "service-template.yaml" # Ignored. Does not have patch files.
)

# Function to print test summary
print_test_summary() {
  local pass_count=$1
  local fail_count=$2
  local warn_count=$3
  local total=$((pass_count + fail_count + warn_count))

  echo
  echo "=============================="
  echo "         Test Summary         "
  echo "=============================="

  if [ $total -eq 0 ]; then
    echo "No tests were run."
  else
    local pass_percentage=$(((pass_count * 100) / total))
    local fail_percentage=$((($fail_count * 100) / total))
    local warn_percentage=$((($warn_count * 100) / total))
    printf "%-10s %5d (%3d%%)\n" "Passed:" $pass_count $pass_percentage
    printf "%-10s %5d (%3d%%)\n" "Failed:" $fail_count $fail_percentage
    printf "%-10s %5d (%3d%%)\n" "Warnings:" $warn_count $warn_percentage
    echo "------------------------------"
    printf "%-10s %5d\n" "Total:" $total
  fi

  echo "=============================="
  echo
}

# Function to run a single test
run_test() {
  local manifest="$1"
  local patch_file="$2"
  if python3 k-apply.py -f "$manifest" -p "$patch_file" --dry-run=server; then
    echo "PASS: $manifest with $patch_file"
    return 0
  else
    echo "FAIL: $manifest with $patch_file"
    return 1
  fi
}

# Function to check if a manifest should be ignored
should_ignore_manifest() {
  local manifest_name=$(basename "$1")
  for ignored in "${MANIFEST_IGNORE_LIST[@]}"; do
    if [[ "$manifest_name" == "$ignored" ]]; then
      return 0 # True, should ignore
    fi
  done
  return 1 # False, should not ignore
}

# Main function
main() {
  cd "$ROOT_DIR"

  local pass_count=0
  local fail_count=0
  local warn_count=0

  while IFS= read -r -d '' manifest; do
    if should_ignore_manifest "$manifest"; then
      echo "Ignoring manifest: $(basename "$manifest")"
      continue
    fi
    while IFS= read -r -d '' escalation; do
      local escalation_name=$(basename "$escalation")
      local manifest_base=$(basename "${manifest%%-*}")
      local patch_file="$escalation/$manifest_base/$escalation_name-$manifest_base.yaml"

      if [[ -f "$patch_file" ]]; then
        if run_test "$manifest" "$patch_file"; then
          ((pass_count++))
        else
          ((fail_count++))
        fi
      else
        echo "WARN: $patch_file does not exist"
          ((warn_count++))
      fi
    done < <(find manifests/ -mindepth 1 -maxdepth 1 -type d -print0)
  done < <(find manifests/ -maxdepth 1 -type f -print0)

  print_test_summary $pass_count $fail_count $warn_count
  [[ $fail_count -eq 0 ]]
}

# Run main function
main "$@"
