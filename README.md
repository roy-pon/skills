# Skills repository

This repository stores reusable AI skills in version control.

It is organized for humans by category, while the installer publishes each skill into a runtime-specific personal skills folder.

## Repository structure

```text
skills/
  <category>/
    <skill-name>/
      SKILL.md
      references/
      agents/
      scripts/
      assets/
scripts/
  install-skills.sh
  list-skills.sh
  new-skill.sh
```

Example:

```text
skills/
  productivity/
    english-writer/
      SKILL.md
      references/style-profile.md
      agents/openai.yaml
```

## Important rule

Categories only exist inside this repository.

Installed skills are copied or linked into a flat destination such as `~/.agents/skills`, so every skill name must be globally unique across the whole repo.

## Install skills

By default, the installer publishes all skills to `~/.agents/skills`.

```bash
./scripts/install-skills.sh
```

Other supported runtimes:

```bash
./scripts/install-skills.sh --runtime claude
./scripts/install-skills.sh --runtime agents
```

You can also install to a custom folder:

```bash
./scripts/install-skills.sh --target-root /some/path/skills
```

### Overwrite behavior

- If a target skill already exists and was installed by this repository before, the installer updates it automatically.
- If a target skill already exists but is not recognized as managed by this repository, the installer asks for confirmation before overwriting.
- In non-interactive runs, unmanaged installs are not overwritten unless you pass:

```bash
./scripts/install-skills.sh --yes
```

## Update skills

Skill versions are stored in `SKILL.md` frontmatter under:

```yaml
metadata:
  version: "1.2.3"
```

`metadata.version` is required by this repository's scripts.

### Recommended for easiest updates on your own machine

Use link mode:

```bash
./scripts/install-skills.sh --mode link
```

This creates symlinks from your runtime skills folder back to this repository. After that, updating the repo with `git pull` makes the latest skill files available immediately.

### Copy mode

If you prefer plain copied files:

```bash
./scripts/install-skills.sh --mode copy
```

Then update with:

```bash
git pull
./scripts/install-skills.sh --mode copy
```

## List skills

List all skills in this repository:

```bash
./scripts/list-skills.sh
```

List one category:

```bash
./scripts/list-skills.sh --category productivity
```

Include installed state for a runtime target:

```bash
./scripts/list-skills.sh --show-install-state --runtime agents
```

## Install only part of the repo

Install one category:

```bash
./scripts/install-skills.sh --category productivity
```

Install one skill:

```bash
./scripts/install-skills.sh --skill english-writer
```

Filters can be combined:

```bash
./scripts/install-skills.sh --runtime agents --category productivity --skill english-writer
```

## Export skills for Gemini Gems or NotebookLM

Export skills into a Gemini-ready bundle (default target):

```bash
./scripts/export-gemini-gems.sh
```

By default this writes to `dist/gemini` with:

- `dist/gemini/<skill>/instructions.txt` (combined SKILL + references content)
- `dist/gemini/<skill>/gem.json` (Gem metadata + full instructions payload)
- `dist/gemini/index.csv` (flat import index for all exported skills)

Useful options:

```bash
./scripts/export-gemini-gems.sh --category productivity
./scripts/export-gemini-gems.sh --skill english-writer
./scripts/export-gemini-gems.sh --output-root /tmp/gemini-export --clean
./scripts/export-gemini-gems.sh --target notebooklm
```

NotebookLM target output (default root: `dist/notebooklm`):

- `dist/notebooklm/<skill>/overview.md`
- `dist/notebooklm/<skill>/playbook.md`
- `dist/notebooklm/<skill>/references/*.md` (copied from skill references)
- `dist/notebooklm/<skill>/manifest.json`
- `dist/notebooklm/index.csv`

## Add a new skill

Create a scaffold in one command:

```bash
./scripts/new-skill.sh \
  --category productivity \
  --skill meeting-summarizer \
  --description "Summarize meeting notes into actionable decisions and owners." \
  --version "0.1.0"
```

Optional argument hint:

```bash
./scripts/new-skill.sh \
  --category productivity \
  --skill meeting-summarizer \
  --description "Summarize meeting notes into actionable decisions and owners." \
  --version "0.1.0" \
  --argument-hint "meeting notes or transcript"
```

Overwrite an existing scaffold:

```bash
./scripts/new-skill.sh --category productivity --skill meeting-summarizer --description "..." --version "0.1.0" --force
```

After scaffolding:

1. Edit `SKILL.md`
2. Set or bump `metadata.version` when you release updates
3. Expand `references/usage.md` with detailed workflow notes
4. Re-run the installer

## Current skills

- `productivity/english-writer`
- `productivity/humanizer`
- `productivity/tldr`

## Notes

- The installer stores management metadata in `<target-root>/.skills-repo-installer/` so it can identify repository-managed installs and compare versions.
- The installer validates that each `SKILL.md` contains a `name` that matches its folder name.
- This repo layout is optimized for maintaining many skills in multiple categories without forcing the runtime installation layout to match the source layout.
