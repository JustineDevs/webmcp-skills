#!/usr/bin/env bash
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"
validator="${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py"
python_bin="${SKILL_VALIDATOR_PYTHON:-python3}"
fail() { printf 'validate-skills: %s\n' "$1" >&2; exit 1; }
if [[ "$python_bin" != */* ]]; then python_bin=$(command -v "$python_bin") || fail "validator interpreter not found: $python_bin"; fi
test -x "$python_bin" || fail "validator interpreter is not executable: $python_bin"
test -f "$validator" || fail "skill-creator validator not found: $validator"
"$python_bin" -c 'import yaml' 2>/dev/null || fail "PyYAML is unavailable for $python_bin"
test -x scripts/validate-skills.sh || fail 'validator is not executable'

skills=()
while IFS= read -r skill; do skills[${#skills[@]}]="$skill"; done < <(awk -F'|' '$3 ~ / skill / {gsub(/^[ \t]+|[ \t]+$/, "", $2); sub(/^\[/, "", $2); sub(/\]\(.*/, "", $2); gsub(/`/, "", $2); sub(/^\.codex\/skills\//, "", $2); sub(/\/$/, "", $2); print $2}' .codex/skills/catalog.md | sort)
test "${#skills[@]}" -eq 13 || fail "catalog must declare exactly thirteen skill rows"
fixed_skills='webmcp-agent-browser
webmcp-agents
webmcp-core
webmcp-declarative
webmcp-design-md
webmcp-evals
webmcp-frameworks
webmcp-maintainer
webmcp-runtime
webmcp-security
webmcp-service-workers
webmcp-setup
webmcp-tool-design'
test "$(printf '%s\n' "${skills[@]}" | sort)" = "$(printf '%s\n' "$fixed_skills" | sort)" || fail 'catalog skill names must match the fixed thirteen-skill allowlist'
actual=$(find .codex/skills -type f -name SKILL.md -print | sed -n 's#^\.codex/skills/\([^/]*\)/SKILL\.md$#\1#p' | sort)
expected=$(printf '%s\n' "${skills[@]}" | sort)
test "$actual" = "$expected" || fail "skill allowlist mismatch"

for skill in "${skills[@]}"; do
  file=".codex/skills/$skill/SKILL.md"
  "$python_bin" "$validator" ".codex/skills/$skill" >/dev/null || fail "quick_validate failed: $file"
  test -s "$file" || fail "empty skill: $file"
  rg -q '^## Authority and boundaries$' "$file" || fail "missing authority section: $file"
  ! rg -n '\[TODO:|\[YOUR_|<TODO>|placeholder text' "$file" || fail "unfinished scaffold: $file"
done

for term in 'index\.bs' normative 'host adapter' 'webmcp-runtime'; do rg -qi "$term" .codex/skills/webmcp-core/SKILL.md || fail "core marker: $term"; done
for term in 'Authority and boundaries' 'webmcp-runtime' capability native verify; do rg -qi "$term" .codex/skills/webmcp-agents/SKILL.md || fail "umbrella marker: $term"; done
for term in 'document.modelContext' agent-browser 'Chrome DevTools MCP' Lighthouse unsupported native 'Permissions Policy'; do rg -qi "$term" .codex/skills/webmcp-runtime/SKILL.md || fail "runtime marker: $term"; done
for term in snapshot ref 'operational guidance' 'not normative' structured verify; do rg -qi "$term" .codex/skills/webmcp-agent-browser/SKILL.md || fail "browser marker: $term"; done
rg -q 'declarative-api-explainer\.md' .codex/skills/webmcp-declarative/SKILL.md && rg -q TBD .codex/skills/webmcp-declarative/SKILL.md || fail 'declarative boundary'
rg -q 'docs/service-workers\.md' .codex/skills/webmcp-service-workers/SKILL.md && rg -q TBD .codex/skills/webmcp-service-workers/SKILL.md || fail 'worker boundary'
for term in 'user goal' schema recovery 'Output checklist'; do rg -qi "$term" .codex/skills/webmcp-tool-design/SKILL.md || fail "design marker: $term"; done
for term in Lexer AST Resolver Renderer 'DESIGN.md' 'UI↔UX' 'WebMCP tool'; do rg -qi "$term" .codex/skills/webmcp-design-md/SKILL.md || fail "design-md marker: $term"; done
for term in 'tool selection' 'chained calls' 'wrong-state' 'Output checklist'; do rg -qi "$term" .codex/skills/webmcp-evals/SKILL.md || fail "eval marker: $term"; done
for term in React Angular 'webmcp-types' lifecycle; do rg -qi "$term" .codex/skills/webmcp-frameworks/SKILL.md || fail "framework marker: $term"; done
for term in 'chrome://flags/#enable-webmcp-testing' origin trial 'progressive enhancement'; do rg -qi "$term" .codex/skills/webmcp-setup/SKILL.md || fail "setup marker: $term"; done
for term in untrusted 'Permissions Policy' AbortSignal confirmation host_permissions spotlighting classifier; do rg -qi "$term" .codex/skills/webmcp-security/SKILL.md || fail "security marker: $term"; done
for term in Makefile make 'make lint' 'make watch' CSSWG CONTRIBUTING.md index.bs; do rg -qi "$term" .codex/skills/webmcp-maintainer/SKILL.md || fail "maintainer marker: $term"; done

for path in index.bs Makefile w3c.json README.md declarative-api-explainer.md docs/service-workers.md docs/webmcp-explainer.md implementation-status.md security-privacy-questionnaire.md CONTRIBUTING.md LICENSE.md .gitignore .github/dependabot.yml .github/workflows/auto-publish.yml .pr-preview.json ARCHITECTURE.md .codex/skills/catalog.md scripts/validate-skills.sh scripts/test-adapters.sh scripts/webmcp-agent-browser.sh scripts/webmcp-android.sh scripts/webmcp-ios.sh scripts/webmcp-desktop.sh scripts/webmcp-device.sh scripts/webmcp-toolkit.mjs scripts/webmcp-toolkit.sh scripts/webmcp-chrome-devtools.sh tests/fixtures/webmcp-fixture.html tests/fixtures/webmcp-fixture.js tests/fixtures/tools.json tests/fixtures/evals.json tests/fixtures/DESIGN.md; do
  test -e "$path" || fail "missing catalog target: $path"
  rg -F -q "$path" .codex/skills/catalog.md || fail "uncataloged path: $path"
done
for executable in scripts/validate-skills.sh scripts/test-adapters.sh scripts/webmcp-agent-browser.sh scripts/webmcp-android.sh scripts/webmcp-ios.sh scripts/webmcp-desktop.sh scripts/webmcp-device.sh scripts/webmcp-toolkit.sh scripts/webmcp-chrome-devtools.sh; do
  test -x "$executable" || fail "adapter/validator is not executable: $executable"
done
for term in ADB screenshot 'UI hierarchy' tap swipe keyevent launch simctl idb macOS Windows Linux; do
  rg -qi "$term" .codex/skills/webmcp-runtime/SKILL.md || fail "native adapter marker: $term"
done
for term in schema security eval design setup doctor; do
  rg -qi "$term" .codex/skills/webmcp-runtime/SKILL.md || fail "toolkit marker: $term"
done
rg -q '^\| `\.omx/` \| excluded \|' .codex/skills/catalog.md || fail 'missing .omx exclusion'
rg -q '^\| `index\.html` \| excluded \|' .codex/skills/catalog.md || fail 'missing index.html exclusion'
grep -qx index.html .gitignore || fail 'index.html ignore rule missing'
if test -e index.html; then
  git check-ignore -q index.html || fail 'generated index.html is not ignored'
fi
if git ls-files --error-unmatch index.html >/dev/null 2>&1; then
  fail 'generated index.html is tracked'
fi
rg -q 'catalog\.md' ARCHITECTURE.md || fail 'architecture catalog mention missing'
for skill in "${skills[@]}"; do
  rg -q "\.codex/skills/$skill/SKILL\.md" ARCHITECTURE.md || fail "architecture link missing: $skill"
done
for stale in 'src/' 'app/' 'lib/' 'services/' 'models/'; do
  ! rg -qF "$stale" ARCHITECTURE.md || fail "stale application-layout reference: $stale"
done
"$python_bin" - <<'PY'
import os
import re
import subprocess
import sys
from pathlib import Path
import yaml

catalog = Path('.codex/skills/catalog.md')
rows = []
for line in catalog.read_text().splitlines():
    if not line.startswith('|') or line.startswith('| ---') or line.startswith('| Path '):
        continue
    cells = [cell.strip() for cell in line.strip('|').split('|')]
    if len(cells) != 6:
        raise SystemExit('catalog row must have six columns')
    path = re.sub(r'^\[\s*([^]]+?)\s*\]\([^)]*\)$', r'\1', cells[0]).strip('`')
    if path.startswith('/') or '\\' in path or any(part in {'.', '..'} for part in Path(path.rstrip('/')).parts):
        raise SystemExit(f'catalog path is not canonical: {path}')
    normalized = Path(path.rstrip('/')).as_posix() + ('/' if path.endswith('/') else '')
    if path != normalized:
        raise SystemExit(f'catalog path is not normalized: {path}')
    rows.append((path, *cells[1:]))
paths = [row[0] for row in rows]
if len(paths) != len(set(paths)):
    raise SystemExit('catalog contains duplicate paths')
if any(row[1] not in {'skill', 'directory', 'file', 'excluded'} for row in rows):
    raise SystemExit('catalog contains an invalid kind')
for path, kind, owner, role, status, notes in rows:
    if kind == 'directory' and not path.endswith('/'):
        raise SystemExit(f'directory path must end with slash: {path}')
    if kind not in {'directory', 'skill', 'excluded'} and path.endswith('/'):
        raise SystemExit(f'file/skill path must not end with slash: {path}')
    if kind != 'excluded' and not all((owner, role, status)):
        raise SystemExit(f'catalog row has empty ownership fields: {path}')
if not {' .omx/'.strip(), 'index.html'} <= set(paths):
    raise SystemExit('catalog is missing an exclusion row')
skills = {path.removeprefix('.codex/skills/').removesuffix('/') for path, kind, *_ in rows if kind == 'skill'}
actual = {str(path.parent.relative_to('.codex/skills')) for path in Path('.codex/skills').glob('*/SKILL.md')}
skill_dirs = {path.name for path in Path('.codex/skills').iterdir() if path.is_dir()}
if skills != actual or skill_dirs != skills or len(skills) != 13:
    raise SystemExit('catalog skill rows do not match the thirteen skill directories')
skill_rows = {path for path, kind, *_ in rows if kind == 'skill'}
if skill_rows != {f'.codex/skills/{skill}/' for skill in skills}:
    raise SystemExit('catalog skill rows must be canonical skill directories')
if any(path == f'.codex/skills/{skill}/SKILL.md' for path, *_ in rows for skill in skills):
    raise SystemExit('catalog must not duplicate an owned SKILL.md as a file row')
for skill in skills:
    frontmatter = Path('.codex/skills', skill, 'SKILL.md').read_text().split('---', 2)[1]
    metadata = yaml.safe_load(frontmatter) or {}
    if metadata.get('name') != skill:
        raise SystemExit(f'frontmatter name mismatch: {skill}')
allowed_owners = skills | {'workflow-runtime', 'build-output'}
for path, kind, owner, role, status, notes in rows:
    if kind != 'excluded' and owner not in allowed_owners:
        raise SystemExit(f'catalog row has unknown owner: {path}: {owner}')
    if kind == 'skill' and owner != path.removeprefix('.codex/skills/').removesuffix('/'):
        raise SystemExit(f'skill row owner mismatch: {path}: {owner}')
maintainer_paths = {
    '.agents/', '.agents/skills/', 'skills/', '.codex/', '.codex/skills/', '.codex/skills/catalog.md', '.github/', '.github/workflows/',
    '.github/dependabot.yml', '.github/workflows/auto-publish.yml', 'assets/', 'assets/openai.svg',
    'assets/openai-white.svg', 'docs/', 'ARCHITECTURE.md', 'CONTRIBUTING.md', 'LICENSE.md',
    'Makefile', 'implementation-status.md', 'w3c.json', '.gitignore', '.pr-preview.json',
    'scripts/', 'scripts/validate-skills.sh', 'scripts/test-adapters.sh', 'scripts/webmcp-agent-browser.sh',
    'scripts/webmcp-android.sh', 'scripts/webmcp-ios.sh', 'scripts/webmcp-desktop.sh', 'scripts/webmcp-device.sh',
    'scripts/webmcp-toolkit.mjs', 'scripts/webmcp-toolkit.sh', 'scripts/webmcp-chrome-devtools.sh', 'tests/', 'tests/fixtures/',
    'tests/fixtures/webmcp-fixture.html', 'tests/fixtures/webmcp-fixture.js', 'tests/fixtures/tools.json',
    'tests/fixtures/evals.json', 'tests/fixtures/DESIGN.md'
}
for path, kind, owner, role, status, notes in rows:
    if path in maintainer_paths and owner != 'webmcp-maintainer':
        raise SystemExit(f'maintainer ownership mismatch: {path}: {owner}')
exclusions = {path: (kind, owner, status, notes) for path, kind, owner, role, status, notes in rows if kind == 'excluded'}
if set(exclusions) != {'.omx/', 'index.html'}:
    raise SystemExit('catalog must contain exactly .omx/ and index.html exclusions')
if exclusions.get('.omx/') != ('excluded', 'workflow-runtime', 'excluded', 'Never product content'):
    raise SystemExit('invalid .omx exclusion metadata')
if exclusions.get('index.html') != ('excluded', 'build-output', 'excluded', 'Generate locally; do not commit'):
    raise SystemExit('invalid index.html exclusion metadata')
expected_owners = {
    'docs/service-workers.md': 'webmcp-service-workers',
    'docs/webmcp-explainer.md': 'webmcp-core',
    'declarative-api-explainer.md': 'webmcp-declarative',
    'index.bs': 'webmcp-core',
    'security-privacy-questionnaire.md': 'webmcp-security',
}
for path, kind, owner, role, status, notes in rows:
    expected = expected_owners.get(path, 'webmcp-maintainer') if kind != 'skill' else owner
    if kind != 'excluded' and owner != expected:
        raise SystemExit(f'catalog owner mismatch: {path}: {owner}, expected {expected}')
worktree_files = subprocess.check_output(
    ['git', 'ls-files', '--cached', '--others', '--exclude-standard'], text=True
).splitlines()
required = {
    file_path for file_path in worktree_files
    if not re.fullmatch(r'\.codex/skills/[^/]+/SKILL\.md', file_path)
    and not (Path(file_path).is_symlink() and Path(file_path).is_dir())
}
required |= {'ARCHITECTURE.md', '.codex/skills/catalog.md', 'scripts/validate-skills.sh'}
for file_path in worktree_files:
    if Path(file_path).is_symlink() and Path(file_path).is_dir():
        required.add(file_path + '/')
        continue
    parent = Path(file_path).parent
    while str(parent) not in {'.', ''}:
        required.add(str(parent) + '/')
        parent = parent.parent
catalog_paths = set(paths)
missing = sorted(required - catalog_paths - {'.omx/', 'index.html'})
if missing:
    raise SystemExit('uncataloged paths: ' + ', '.join(missing))
for path, kind, *_ in rows:
    if kind != 'excluded' and not Path(path.rstrip('/')).exists():
        raise SystemExit(f'catalog target does not exist: {path}')
allowed_files = {catalog.resolve()}
allowed_files.update((Path('.codex/skills', skill, 'SKILL.md')).resolve() for skill in skills)
orphaned = [str(path) for path in Path('.codex/skills').rglob('*') if path.is_file() and path.resolve() not in allowed_files]
if orphaned:
    raise SystemExit('orphaned skill files: ' + ', '.join(orphaned))
for source in [Path('ARCHITECTURE.md'), catalog] + [Path('.codex/skills', skill, 'SKILL.md') for skill in skills]:
    text = source.read_text()
    for target in re.findall(r'\]\(([^)#]+)(?:#[^)]*)?\)', text):
        if '://' in target or target.startswith('mailto:'):
            continue
        target_path = (source.parent / target).resolve()
        if not target_path.exists():
            raise SystemExit(f'broken local link in {source}: {target}')
PY
printf 'validate-skills: passed thirteen skills, catalog, boundaries, links, adapters, and output policy\n'
