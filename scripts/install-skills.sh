#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/install-skills.sh [options]

Options:
  --runtime <copilot|claude|agents>  Install into the default folder for that runtime
  --target-root <path>               Install into a custom skills folder
  --mode <copy|link>                 Copy skill folders or symlink them (default: copy)
  --category <name>                  Install only one category
  --skill <name>                     Install only one skill
  --yes                              Overwrite non-managed existing installs without prompting
  -h, --help                         Show this help text
EOF
}

runtime="agents"
target_root=""
mode="copy"
category_filter=""
skill_filter=""
assume_yes=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime)
      runtime="${2:-}"
      shift 2
      ;;
    --target-root)
      target_root="${2:-}"
      shift 2
      ;;
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --category)
      category_filter="${2:-}"
      shift 2
      ;;
    --skill)
      skill_filter="${2:-}"
      shift 2
      ;;
    --yes)
      assume_yes=true
      shift
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

case "$runtime" in
  copilot|claude|agents)
    ;;
  *)
    printf 'Unsupported runtime: %s\n' "$runtime" >&2
    exit 1
    ;;
esac

case "$mode" in
  copy|link)
    ;;
  *)
    printf 'Unsupported mode: %s\n' "$mode" >&2
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
source_root="${repo_root}/skills"
state_dir=""
repo_id=""

if [[ ! -d "${source_root}" ]]; then
  printf 'Skills source folder not found: %s\n' "${source_root}" >&2
  exit 1
fi

if [[ -z "${target_root}" ]]; then
  case "$runtime" in
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

mkdir -p "${target_root}"
state_dir="${target_root}/.skills-repo-installer"
mkdir -p "${state_dir}"

repo_id="$(git -C "${repo_root}" config --get remote.origin.url 2>/dev/null || true)"
if [[ -z "${repo_id}" ]]; then
  repo_id="$(cd "${repo_root}" && pwd -P)"
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

state_file_for() {
  local skill_name="$1"
  printf '%s/%s.env' "${state_dir}" "${skill_name}"
}

write_state() {
  local skill_name="$1"
  local category_name="$2"
  local source_version="$3"
  local skill_dir="$4"
  local install_mode="$5"
  local state_file

  state_file="$(state_file_for "${skill_name}")"
  cat > "${state_file}" <<EOF
REPO_ID=${repo_id}
SKILL_NAME=${skill_name}
CATEGORY_NAME=${category_name}
SOURCE_VERSION=${source_version}
SOURCE_PATH=${skill_dir}
INSTALL_MODE=${install_mode}
EOF
}

remove_state() {
  local skill_name="$1"
  local state_file
  state_file="$(state_file_for "${skill_name}")"
  rm -f "${state_file}"
}

is_managed_install() {
  local skill_name="$1"
  local destination="$2"
  local skill_dir="$3"
  local state_file
  state_file="$(state_file_for "${skill_name}")"

  if [[ -f "${state_file}" ]]; then
    # shellcheck disable=SC1090
    source "${state_file}"
    if [[ "${REPO_ID:-}" == "${repo_id}" ]]; then
      return 0
    fi
  fi

  if [[ -L "${destination}" ]]; then
    local existing_target
    existing_target="$(readlink "${destination}")"
    if [[ "${existing_target}" == "${skill_dir}" ]]; then
      return 0
    fi
  fi

  return 1
}

get_existing_source_version() {
  local skill_name="$1"
  local state_file
  state_file="$(state_file_for "${skill_name}")"
  if [[ -f "${state_file}" ]]; then
    # shellcheck disable=SC1090
    source "${state_file}"
    printf '%s' "${SOURCE_VERSION:-}"
    return 0
  fi
  return 1
}

confirm_overwrite() {
  local destination="$1"
  local answer=""

  if [[ "${assume_yes}" == true ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    printf 'Refusing to overwrite unmanaged install at %s in non-interactive mode.\n' "${destination}" >&2
    printf 'Re-run with --yes to allow overwrite.\n' >&2
    return 2
  fi

  printf 'Skill already exists at %s and is not managed by this repository.\n' "${destination}" >&2
  printf 'Overwrite it? [y/N]: ' >&2
  read -r answer
  case "${answer}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

declare -a skill_dirs=()
while IFS= read -r -d '' skill_file; do
  skill_dirs+=("$(dirname "${skill_file}")")
done < <(find "${source_root}" -mindepth 3 -maxdepth 3 -type f -name SKILL.md -print0 | sort -z)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  printf 'No skills found under %s\n' "${source_root}" >&2
  exit 1
fi

matched_count=0
installed_count=0

for skill_dir in "${skill_dirs[@]}"; do
  category_name="$(basename "$(dirname "${skill_dir}")")"
  skill_name="$(basename "${skill_dir}")"
  skill_file="${skill_dir}/SKILL.md"

  if [[ -n "${category_filter}" && "${category_name}" != "${category_filter}" ]]; then
    continue
  fi

  if [[ -n "${skill_filter}" && "${skill_name}" != "${skill_filter}" ]]; then
    continue
  fi

  declared_name="$(extract_skill_name "${skill_file}")"
  if [[ -z "${declared_name}" ]]; then
    printf 'Missing name in %s\n' "${skill_file}" >&2
    exit 1
  fi

  if [[ "${declared_name}" != "${skill_name}" ]]; then
    printf 'Name mismatch in %s: folder is "%s" but SKILL.md declares "%s"\n' "${skill_file}" "${skill_name}" "${declared_name}" >&2
    exit 1
  fi

  matched_count=$((matched_count + 1))
  destination="${target_root}/${skill_name}"
  source_version="$(get_skill_version "${skill_file}")"
  if [[ -z "${source_version}" ]]; then
    printf 'Missing metadata.version in %s\n' "${skill_file}" >&2
    exit 1
  fi

  if [[ -e "${destination}" || -L "${destination}" ]]; then
    if is_managed_install "${skill_name}" "${destination}" "${skill_dir}"; then
      existing_version="$(get_existing_source_version "${skill_name}" || true)"
      if [[ "${mode}" == "copy" && -n "${existing_version}" && "${existing_version}" == "${source_version}" ]]; then
        printf 'Up-to-date %s/%s (version %s)\n' "${category_name}" "${skill_name}" "${source_version}"
        continue
      fi
      printf 'Updating managed install %s/%s\n' "${category_name}" "${skill_name}"
    else
      overwrite_status=0
      confirm_overwrite "${destination}" || overwrite_status=$?
      if [[ ${overwrite_status} -ne 0 ]]; then
        if [[ ${overwrite_status} -eq 2 ]]; then
          exit 1
        fi
        printf 'Skipped %s/%s\n' "${category_name}" "${skill_name}"
        continue
      fi
    fi
    rm -rf "${destination}"
    remove_state "${skill_name}"
  fi

  if [[ "${mode}" == "copy" ]]; then
    cp -R "${skill_dir}" "${destination}"
  else
    ln -s "${skill_dir}" "${destination}"
  fi

  write_state "${skill_name}" "${category_name}" "${source_version}" "${skill_dir}" "${mode}"
  printf 'Installed %s/%s -> %s\n' "${category_name}" "${skill_name}" "${destination}"
  installed_count=$((installed_count + 1))
done

if [[ ${matched_count} -eq 0 ]]; then
  printf 'No skills matched the provided filters.\n' >&2
  exit 1
fi

printf 'Done. Installed %d skill(s) into %s\n' "${installed_count}" "${target_root}"
