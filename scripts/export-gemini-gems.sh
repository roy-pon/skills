#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/export-gemini-gems.sh [options]

Options:
  --target <gemini|notebooklm>        Export target format (default: gemini)
  --category <name>                  Export only one category
  --skill <name>                     Export only one skill
  --output-root <path>               Output folder (defaults to ./dist/<target>)
  --clean                            Remove output root before exporting
  -h, --help                         Show this help text
EOF
}

target="gemini"
category_filter=""
skill_filter=""
output_root=""
clean_output=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="${2:-}"
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
    --output-root)
      output_root="${2:-}"
      shift 2
      ;;
    --clean)
      clean_output=true
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

case "${target}" in
  gemini|notebooklm)
    ;;
  *)
    printf 'Unsupported target: %s\n' "${target}" >&2
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

if [[ -z "${output_root}" ]]; then
  output_root="${repo_root}/dist/${target}"
fi

if [[ "${clean_output}" == true ]]; then
  rm -rf "${output_root}"
fi
mkdir -p "${output_root}"

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

extract_skill_description() {
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
    in_frontmatter == 1 && $0 ~ /^description:[[:space:]]*/ {
      value = $0
      sub(/^description:[[:space:]]*/, "", value)
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

extract_skill_body() {
  local skill_file="$1"
  awk '
    /^---[[:space:]]*$/ {
      delim_count += 1
      next
    }
    delim_count >= 2 {
      print
    }
  ' "${skill_file}"
}

extract_display_name() {
  local agent_file="$1"
  if [[ ! -f "${agent_file}" ]]; then
    return 1
  fi

  awk '
    $0 ~ /^interface:[[:space:]]*$/ {
      in_interface = 1
      next
    }
    in_interface == 1 && $0 ~ /^[^[:space:]]/ {
      in_interface = 0
    }
    in_interface == 1 && $0 ~ /^[[:space:]]+display_name:[[:space:]]*/ {
      value = $0
      sub(/^[[:space:]]+display_name:[[:space:]]*/, "", value)
      gsub(/^["'\''"]|["'\''"]$/, "", value)
      print value
      exit
    }
  ' "${agent_file}"
}

title_from_skill_name() {
  local skill_name="$1"
  printf '%s' "${skill_name}" | awk -F'-' '{for (i=1; i<=NF; i++) {$i=toupper(substr($i,1,1)) substr($i,2)}; print $0}' OFS=' '
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "${value}"
}

csv_escape() {
  local value="$1"
  value="${value//\"/\"\"}"
  printf '"%s"' "${value}"
}

declare -a skill_dirs=()
while IFS= read -r -d '' skill_file; do
  skill_dirs+=("$(dirname "${skill_file}")")
done < <(find "${source_root}" -mindepth 3 -maxdepth 3 -type f -name SKILL.md -print0 | sort -z)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  printf 'No skills found under %s\n' "${source_root}" >&2
  exit 1
fi

index_file="${output_root}/index.csv"
if [[ "${target}" == "gemini" ]]; then
  printf 'category,skill_name,title,version,description,gem_json_path,instructions_path\n' > "${index_file}"
else
  printf 'category,skill_name,title,version,description,manifest_path,overview_path,playbook_path\n' > "${index_file}"
fi

matched_count=0
exported_count=0

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

  description="$(extract_skill_description "${skill_file}")"
  if [[ -z "${description}" ]]; then
    printf 'Missing description in %s\n' "${skill_file}" >&2
    exit 1
  fi

  version="$(extract_skill_metadata_version "${skill_file}")"
  if [[ -z "${version}" ]]; then
    printf 'Missing metadata.version in %s\n' "${skill_file}" >&2
    exit 1
  fi

  display_name="$(extract_display_name "${skill_dir}/agents/openai.yaml" || true)"
  if [[ -z "${display_name}" ]]; then
    display_name="$(title_from_skill_name "${skill_name}")"
  fi

  matched_count=$((matched_count + 1))

  out_skill_dir="${output_root}/${skill_name}"
  rm -rf "${out_skill_dir}"
  mkdir -p "${out_skill_dir}"

  core_instructions="$(extract_skill_body "${skill_file}")"

  declare -a reference_files=()
  while IFS= read -r -d '' reference_file; do
    reference_files+=("${reference_file}")
  done < <(find "${skill_dir}/references" -type f -name '*.md' -print0 2>/dev/null | sort -z)

  if [[ "${target}" == "gemini" ]]; then
    instructions_file="${out_skill_dir}/instructions.txt"
    {
      printf '# %s\n\n' "${display_name}"
      printf 'Skill name: %s\n' "${skill_name}"
      printf 'Category: %s\n' "${category_name}"
      printf 'Version: %s\n' "${version}"
      printf 'Description: %s\n\n' "${description}"
      printf '## Core instructions\n\n'
      printf '%s\n' "${core_instructions}"

      if [[ ${#reference_files[@]} -gt 0 ]]; then
        printf '\n## References\n'
        for reference_file in "${reference_files[@]}"; do
          reference_rel="${reference_file#${skill_dir}/}"
          printf '\n### %s\n\n' "${reference_rel}"
          cat "${reference_file}"
          printf '\n'
        done
      fi
    } > "${instructions_file}"

    instructions_content="$(cat "${instructions_file}")"
    instructions_rel="${instructions_file#${output_root}/}"
    gem_json_file="${out_skill_dir}/gem.json"
    cat > "${gem_json_file}" <<EOF
{
  "skill_name": "$(json_escape "${skill_name}")",
  "category": "$(json_escape "${category_name}")",
  "version": "$(json_escape "${version}")",
  "title": "$(json_escape "${display_name}")",
  "description": "$(json_escape "${description}")",
  "instructions_file": "$(json_escape "${instructions_rel}")",
  "instructions": "$(json_escape "${instructions_content}")"
}
EOF

    gem_json_rel="${gem_json_file#${output_root}/}"
    printf '%s,%s,%s,%s,%s,%s,%s\n' \
      "$(csv_escape "${category_name}")" \
      "$(csv_escape "${skill_name}")" \
      "$(csv_escape "${display_name}")" \
      "$(csv_escape "${version}")" \
      "$(csv_escape "${description}")" \
      "$(csv_escape "${gem_json_rel}")" \
      "$(csv_escape "${instructions_rel}")" >> "${index_file}"
  else
    overview_file="${out_skill_dir}/overview.md"
    playbook_file="${out_skill_dir}/playbook.md"
    references_dir="${out_skill_dir}/references"
    mkdir -p "${references_dir}"

    printf '# %s\n\n' "${display_name}" > "${overview_file}"
    printf 'Skill name: %s\n' "${skill_name}" >> "${overview_file}"
    printf 'Category: %s\n' "${category_name}" >> "${overview_file}"
    printf 'Version: %s\n\n' "${version}" >> "${overview_file}"
    printf '## Description\n\n' >> "${overview_file}"
    printf '%s\n' "${description}" >> "${overview_file}"

    {
      printf '# %s playbook\n\n' "${display_name}"
      printf '## Core instructions\n\n'
      printf '%s\n' "${core_instructions}"
    } > "${playbook_file}"

    references_json='['
    for reference_file in "${reference_files[@]}"; do
      reference_rel_from_refs="${reference_file#${skill_dir}/references/}"
      if [[ "${references_json}" != "[" ]]; then
        references_json="${references_json}, "
      fi
      references_json="${references_json}\"$(json_escape "references/${reference_rel_from_refs}")\""
      target_reference_path="${references_dir}/${reference_rel_from_refs}"
      mkdir -p "$(dirname "${target_reference_path}")"
      cp "${reference_file}" "${target_reference_path}"
    done
    references_json="${references_json}]"

    manifest_file="${out_skill_dir}/manifest.json"
    cat > "${manifest_file}" <<EOF
{
  "target": "notebooklm",
  "skill_name": "$(json_escape "${skill_name}")",
  "category": "$(json_escape "${category_name}")",
  "version": "$(json_escape "${version}")",
  "title": "$(json_escape "${display_name}")",
  "description": "$(json_escape "${description}")",
  "overview_file": "overview.md",
  "playbook_file": "playbook.md",
  "references": ${references_json}
}
EOF

    manifest_rel="${manifest_file#${output_root}/}"
    overview_rel="${overview_file#${output_root}/}"
    playbook_rel="${playbook_file#${output_root}/}"
    printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$(csv_escape "${category_name}")" \
      "$(csv_escape "${skill_name}")" \
      "$(csv_escape "${display_name}")" \
      "$(csv_escape "${version}")" \
      "$(csv_escape "${description}")" \
      "$(csv_escape "${manifest_rel}")" \
      "$(csv_escape "${overview_rel}")" \
      "$(csv_escape "${playbook_rel}")" >> "${index_file}"
  fi

  printf 'Exported %s/%s (%s) -> %s\n' "${category_name}" "${skill_name}" "${target}" "${out_skill_dir}"
  exported_count=$((exported_count + 1))
done

if [[ ${matched_count} -eq 0 ]]; then
  printf 'No skills matched the provided filters.\n' >&2
  exit 1
fi

printf 'Done. Exported %d skill(s) into %s\n' "${exported_count}" "${output_root}"
printf 'Index: %s\n' "${index_file}"
