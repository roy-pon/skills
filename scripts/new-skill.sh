#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/new-skill.sh [options]

Options:
  --category <name>                  Skill category (e.g. productivity)
  --skill <name>                     Skill name (must match SKILL.md name)
  --description <text>               Skill discovery description
  --version <text>                   Skill version for metadata.version (default: 0.1.0)
  --argument-hint <text>             Optional argument hint for slash invocation
  --force                            Overwrite an existing skill folder
  -h, --help                         Show this help text
EOF
}

category=""
skill_name=""
description=""
version="0.1.0"
argument_hint=""
force=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category)
      category="${2:-}"
      shift 2
      ;;
    --skill)
      skill_name="${2:-}"
      shift 2
      ;;
    --description)
      description="${2:-}"
      shift 2
      ;;
    --version)
      version="${2:-}"
      shift 2
      ;;
    --argument-hint)
      argument_hint="${2:-}"
      shift 2
      ;;
    --force)
      force=true
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

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
skills_root="${repo_root}/skills"

if [[ ! -d "${skills_root}" ]]; then
  printf 'Skills root not found: %s\n' "${skills_root}" >&2
  exit 1
fi

if [[ -z "${category}" || -z "${skill_name}" || -z "${description}" ]]; then
  printf 'Missing required options. --category, --skill, and --description are required.\n\n' >&2
  usage >&2
  exit 1
fi

if [[ ! "${category}" =~ ^[a-z0-9-]+$ ]]; then
  printf 'Invalid category "%s". Use lowercase letters, numbers, and hyphens only.\n' "${category}" >&2
  exit 1
fi

if [[ ! "${skill_name}" =~ ^[a-z0-9-]+$ ]]; then
  printf 'Invalid skill name "%s". Use lowercase letters, numbers, and hyphens only.\n' "${skill_name}" >&2
  exit 1
fi

if [[ -z "${version}" ]]; then
  printf 'Invalid version. --version must be non-empty.\n' >&2
  exit 1
fi

skill_dir="${skills_root}/${category}/${skill_name}"
if [[ -e "${skill_dir}" ]]; then
  if [[ "${force}" == false ]]; then
    printf 'Skill folder already exists: %s\n' "${skill_dir}" >&2
    printf 'Re-run with --force to overwrite it.\n' >&2
    exit 1
  fi
  rm -rf "${skill_dir}"
fi

mkdir -p "${skill_dir}/references" "${skill_dir}/scripts" "${skill_dir}/assets" "${skill_dir}/agents"

skill_title="$(printf '%s' "${skill_name}" | awk -F'-' '{for (i=1; i<=NF; i++) {$i=toupper(substr($i,1,1)) substr($i,2)}; print $0}' OFS=' ')"
escaped_description="$(printf '%s' "${description}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
escaped_argument_hint="$(printf '%s' "${argument_hint}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
escaped_version="$(printf '%s' "${version}" | sed 's/\\/\\\\/g; s/"/\\"/g')"

if [[ -n "${argument_hint}" ]]; then
  cat > "${skill_dir}/SKILL.md" <<EOF
---
name: ${skill_name}
description: "${escaped_description}"
metadata:
  version: "${escaped_version}"
argument-hint: "${escaped_argument_hint}"
---

# ${skill_title}

## When to use

- Add trigger phrases that help the model discover this skill.
- Explain the situations where this skill is the right choice.

## Workflow

1. Describe the first step clearly.
2. Reference supporting files as needed, for example \`./references/usage.md\`.
3. Describe expected output format and quality bar.

## References

- [Usage notes](./references/usage.md)
EOF
else
  cat > "${skill_dir}/SKILL.md" <<EOF
---
name: ${skill_name}
description: "${escaped_description}"
metadata:
  version: "${escaped_version}"
---

# ${skill_title}

## When to use

- Add trigger phrases that help the model discover this skill.
- Explain the situations where this skill is the right choice.

## Workflow

1. Describe the first step clearly.
2. Reference supporting files as needed, for example \`./references/usage.md\`.
3. Describe expected output format and quality bar.

## References

- [Usage notes](./references/usage.md)
EOF
fi

cat > "${skill_dir}/references/usage.md" <<EOF
# ${skill_title} usage notes

Add detailed instructions, constraints, and examples for this skill.
EOF

cat > "${skill_dir}/agents/openai.yaml" <<EOF
interface:
  display_name: "${skill_title}"
  short_description: "${escaped_description}"
  default_prompt: "Use \$${skill_name} to help with this task."
EOF

printf 'Created skill scaffold at %s\n' "${skill_dir}"
printf 'Next steps:\n'
printf '  1) Edit %s/SKILL.md\n' "${skill_dir}"
printf '  2) Edit %s/references/usage.md\n' "${skill_dir}"
printf '  3) Run ./scripts/list-skills.sh\n'
