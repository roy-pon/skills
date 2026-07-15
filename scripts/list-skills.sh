#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/list-skills.sh [options]

Options:
  --category <name>                  List only one category
  --skill <name>                     List only one skill
  --show-install-state               Show whether each skill is installed in target root
  --runtime <copilot|claude|agents>  Runtime used to resolve default target root (with --show-install-state)
  --target-root <path>               Custom target root for install state checks
  -h, --help                         Show this help text
EOF
}

category_filter=""
skill_filter=""
show_install_state=false
runtime="agents"
target_root=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category)
      category_filter="${2:-}"
      shift 2
      ;;
    --skill)
      skill_filter="${2:-}"
      shift 2
      ;;
    --show-install-state)
      show_install_state=true
      shift
      ;;
    --runtime)
      runtime="${2:-}"
      shift 2
      ;;
    --target-root)
      target_root="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "${runtime}" in
  copilot|claude|agents)
    ;;
  *)
    printf 'Unsupported runtime: %s\n' "${runtime}" >&2
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
source_root="${repo_root}/skills"

if [[ ! -d "${source_root}" ]]; then
  printf 'Skills source folder not found: %s\n' "${source_root}" >&2
  exit 1
fi

if [[ "${show_install_state}" == true && -z "${target_root}" ]]; then
  case "${runtime}" in
    copilot)
      target_root="${HOME}/.copilot/skills"
      ;;
    claude)
      target_root="${HOME}/.claude/skills"
      ;;
    agents)
      target_root="${HOME}/.agents/skills"
      ;;
  esac
fi

extract_skill_name() {
  local skill_file="$1"
  awk '
    /^---[[:space:]]*$/ {
      if (in_frontmatter == 0) {
        in_frontmatter = 1
        next
      }
      if (in_frontmatter == 1) {
        exit
      }
    }
    in_frontmatter == 1 && $0 ~ /^name:[[:space:]]*/ {
      value = $0
      sub(/^name:[[:space:]]*/, "", value)
      gsub(/^["'\''"]|["'\''"]$/, "", value)
      print value
      exit
    }
  ' "${skill_file}"
}

extract_skill_metadata_version() {
  local skill_file="$1"
  awk '
    /^---[[:space:]]*$/ {
      if (in_frontmatter == 0) {
        in_frontmatter = 1
        next
      }
      if (in_frontmatter == 1) {
        exit
      }
    }
    in_frontmatter == 1 && $0 ~ /^metadata:[[:space:]]*$/ {
      in_metadata = 1
      next
    }
    in_frontmatter == 1 && in_metadata == 1 {
      if ($0 ~ /^[^[:space:]]/) {
        in_metadata = 0
      } else if ($0 ~ /^[[:space:]]+version:[[:space:]]*/) {
        value = $0
        sub(/^[[:space:]]+version:[[:space:]]*/, "", value)
        gsub(/^["'\''"]|["'\''"]$/, "", value)
        print value
        exit
      }
    }
  ' "${skill_file}"
}

get_skill_version() {
  local skill_file="$1"
  local metadata_version=""

  metadata_version="$(extract_skill_metadata_version "${skill_file}")"
  printf '%s' "${metadata_version}"
}

declare -a skill_dirs=()
while IFS= read -r -d '' skill_file; do
  skill_dirs+=("$(dirname "${skill_file}")")
done < <(find "${source_root}" -mindepth 3 -maxdepth 3 -type f -name SKILL.md -print0 | sort -z)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  printf 'No skills found under %s\n' "${source_root}" >&2
  exit 1
fi

if [[ "${show_install_state}" == true ]]; then
  printf '%-20s %-30s %-24s %-10s %s\n' "CATEGORY" "SKILL" "VERSION" "INSTALLED" "SOURCE"
else
  printf '%-20s %-30s %-24s %s\n' "CATEGORY" "SKILL" "VERSION" "SOURCE"
fi

found_count=0
for skill_dir in "${skill_dirs[@]}"; do
  category_name="$(basename "$(dirname "${skill_dir}")")"
  skill_name="$(basename "${skill_dir}")"
  skill_file="${skill_dir}/SKILL.md"
  declared_name="$(extract_skill_name "${skill_file}")"

  if [[ -n "${category_filter}" && "${category_name}" != "${category_filter}" ]]; then
    continue
  fi

  if [[ -n "${skill_filter}" && "${skill_name}" != "${skill_filter}" ]]; then
    continue
  fi

  if [[ -z "${declared_name}" || "${declared_name}" != "${skill_name}" ]]; then
    printf 'Invalid skill metadata: %s\n' "${skill_file}" >&2
    exit 1
  fi

  version="$(get_skill_version "${skill_file}")"
  if [[ -z "${version}" ]]; then
    printf 'Missing metadata.version in %s\n' "${skill_file}" >&2
    exit 1
  fi
  source_rel="${skill_dir#${repo_root}/}"

  if [[ "${show_install_state}" == true ]]; then
    installed="no"
    if [[ -e "${target_root}/${skill_name}" || -L "${target_root}/${skill_name}" ]]; then
      installed="yes"
    fi
    printf '%-20s %-30s %-24s %-10s %s\n' "${category_name}" "${skill_name}" "${version}" "${installed}" "${source_rel}"
  else
    printf '%-20s %-30s %-24s %s\n' "${category_name}" "${skill_name}" "${version}" "${source_rel}"
  fi

  found_count=$((found_count + 1))
done

if [[ ${found_count} -eq 0 ]]; then
  printf 'No skills matched the provided filters.\n' >&2
  exit 1
fi
