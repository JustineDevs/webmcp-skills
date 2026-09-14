#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

const repo = path.resolve(new URL('.', import.meta.url).pathname, '..');
const args = process.argv.slice(2);

function usage() {
  console.log(`Usage:
  scripts/webmcp-toolkit.mjs schema <tools.json|->
  scripts/webmcp-toolkit.mjs security <tools.json|->
  scripts/webmcp-toolkit.mjs eval <suite.json|->
  scripts/webmcp-toolkit.mjs design <DESIGN.md>
  scripts/webmcp-toolkit.mjs setup
  scripts/webmcp-toolkit.mjs doctor`);
}

function fail(message, code = 2) {
  console.error(`webmcp-toolkit: ${message}`);
  process.exit(code);
}

function readText(file) {
  if (!file || file === '-') return fs.readFileSync(0, 'utf8');
  return fs.readFileSync(file, 'utf8');
}

function readJson(file) {
  try {
    return JSON.parse(readText(file));
  } catch (error) {
    fail(`invalid JSON: ${error.message}`);
  }
}

function emit(report) {
  console.log(JSON.stringify(report, null, 2));
  if (report.status === 'fail' || report.status === 'invalid') process.exitCode = 1;
}

function normalizeTools(value) {
  if (Array.isArray(value)) return value;
  if (Array.isArray(value?.tools)) return value.tools;
  if (Array.isArray(value?.result?.tools)) return value.result.tools;
  if (Array.isArray(value?.data?.tools)) return value.data.tools;
  return [];
}

function schemaFindings(value) {
  const findings = [];
  const tools = normalizeTools(value);
  if (!tools.length) findings.push({severity: 'error', code: 'no_tools', message: 'No tool definitions were found.'});
  const names = new Set();
  for (const [index, tool] of tools.entries()) {
    const location = `tools[${index}]`;
    if (!tool || typeof tool !== 'object' || Array.isArray(tool)) {
      findings.push({severity: 'error', code: 'tool_not_object', location});
      continue;
    }
    if (typeof tool.name !== 'string' || !tool.name.trim()) findings.push({severity: 'error', code: 'missing_name', location});
    else {
      if (tool.name.length > 128) findings.push({severity: 'error', code: 'name_too_long', location});
      if (/\p{Cc}/u.test(tool.name) || /\s/.test(tool.name)) findings.push({severity: 'error', code: 'invalid_name', location, message: 'Tool names cannot contain whitespace or control characters.'});
      if (names.has(tool.name)) findings.push({severity: 'error', code: 'duplicate_name', location, message: tool.name});
      names.add(tool.name);
    }
    if (typeof tool.description !== 'string' || !tool.description.trim()) findings.push({severity: 'error', code: 'missing_description', location});
    const schema = typeof tool.inputSchema === 'string' ? (() => { try { return JSON.parse(tool.inputSchema); } catch { return null; } })() : tool.inputSchema;
    if (!schema || typeof schema !== 'object' || schema.type !== 'object') findings.push({severity: 'error', code: 'invalid_input_schema', location, message: 'inputSchema must be a JSON Schema object.'});
    else {
      if (schema.properties !== undefined && (!schema.properties || typeof schema.properties !== 'object' || Array.isArray(schema.properties))) findings.push({severity: 'error', code: 'invalid_properties', location});
      if (schema.required !== undefined && (!Array.isArray(schema.required) || schema.required.some(name => typeof name !== 'string'))) findings.push({severity: 'error', code: 'invalid_required', location});
      if (Array.isArray(schema.required) && schema.properties && schema.required.some(name => !(name in schema.properties))) findings.push({severity: 'error', code: 'required_not_defined', location});
    }
    if (tool.annotations !== undefined && (!tool.annotations || typeof tool.annotations !== 'object')) findings.push({severity: 'error', code: 'invalid_annotations', location});
    for (const key of ['readOnlyHint', 'untrustedContentHint']) if (tool.annotations?.[key] !== undefined && typeof tool.annotations[key] !== 'boolean') findings.push({severity: 'error', code: 'invalid_annotation', location, message: key});
    if (tool.origin !== undefined) {
      try { new URL(tool.origin); } catch { findings.push({severity: 'error', code: 'invalid_origin', location, message: tool.origin}); }
    }
  }
  return {tools: tools.length, findings};
}

function securityReport(value) {
  const base = schemaFindings(value);
  const findings = [...base.findings];
  const tools = normalizeTools(value);
  const injection = /(ignore\s+(all|previous)|system\s+message|developer\s+message|reveal\s+(secrets|prompt)|send\s+to\s+https?:\/\/)/i;
  const consequential = /\b(delete|purchase|buy|place|pay|transfer|send|publish|invite|grant|revoke|submit)\b/i;
  for (const [index, tool] of tools.entries()) {
    const location = `tools[${index}]`;
    const text = `${tool?.name || ''} ${tool?.title || ''} ${tool?.description || ''}`.replaceAll('_', ' ');
    if (injection.test(text)) findings.push({severity: 'error', code: 'prompt_injection_text', location, message: 'Metadata contains instruction-like or exfiltration language.'});
    if (consequential.test(text) && tool?.annotations?.readOnlyHint === true) findings.push({severity: 'error', code: 'write_marked_read_only', location, message: 'Consequential tool is marked read-only.'});
    if (consequential.test(text) && tool?.annotations?.readOnlyHint !== false) findings.push({severity: 'warning', code: 'confirmation_required', location, message: 'Consequential tool must require user confirmation immediately before execution.'});
    const schema = typeof tool?.inputSchema === 'object' ? tool.inputSchema : null;
    if (schema && schema.additionalProperties !== false) findings.push({severity: 'warning', code: 'open_schema', location, message: 'Set additionalProperties:false when the contract is closed.'});
    if (Array.isArray(tool?.exposedTo) && tool.exposedTo.some(origin => origin === '*' || origin === 'null')) findings.push({severity: 'error', code: 'broad_origin_exposure', location});
  }
  return {tools: tools.length, findings, status: findings.some(f => f.severity === 'error') ? 'fail' : findings.length ? 'pass_with_warnings' : 'pass'};
}

function evalReport(value) {
  const findings = [];
  const cases = Array.isArray(value) ? value : value?.cases;
  if (!Array.isArray(cases) || !cases.length) return {status: 'invalid', cases: 0, findings: [{severity: 'error', code: 'no_cases', message: 'An eval suite must contain cases.'}]};
  const ids = new Set();
  for (const [index, test] of cases.entries()) {
    const location = `cases[${index}]`;
    if (!test || typeof test !== 'object') { findings.push({severity: 'error', code: 'case_not_object', location}); continue; }
    if (!test.id || typeof test.id !== 'string' || ids.has(test.id)) findings.push({severity: 'error', code: 'invalid_case_id', location});
    ids.add(test.id);
    if (!test.goal || !test.initialState) findings.push({severity: 'error', code: 'missing_case_context', location});
    if (!Array.isArray(test.allowedTools)) findings.push({severity: 'error', code: 'missing_allowed_tools', location});
    const actual = test.actual;
    if (actual) {
      const calls = Array.isArray(actual.calls) ? actual.calls : [];
      const allowed = new Set(test.allowedTools || []);
      for (const call of calls) if (!allowed.has(call.tool)) findings.push({severity: 'error', code: 'tool_not_allowed', location, message: call.tool});
      for (const forbidden of test.mustNot || []) if (calls.some(call => call.tool === forbidden)) findings.push({severity: 'error', code: 'prohibited_tool_called', location, message: forbidden});
      for (const question of test.mustAsk || []) if (!(actual.asked || []).includes(question)) findings.push({severity: 'error', code: 'required_question_missing', location, message: question});
      if (test.success && actual.finalState !== test.success) findings.push({severity: 'warning', code: 'final_state_mismatch', location});
    } else {
      findings.push({severity: 'warning', code: 'not_executed', location, message: 'Case is defined but has no actual trace.'});
    }
  }
  return {status: findings.some(f => f.severity === 'error') ? 'fail' : findings.length ? 'pass_with_warnings' : 'pass', cases: cases.length, findings};
}

function parseFrontMatter(source) {
  if (!source.startsWith('---')) return {metadata: {}, body: source, findings: [{severity: 'error', code: 'missing_front_matter'}]};
  const end = source.indexOf('\n---', 3);
  if (end < 0) return {metadata: {}, body: source, findings: [{severity: 'error', code: 'unterminated_front_matter'}]};
  const raw = source.slice(4, end).split(/\r?\n/);
  const metadata = {};
  let currentList;
  for (const line of raw) {
    if (!line.trim()) continue;
    const list = line.match(/^\s*-\s+(.+)$/);
    if (list && currentList) { currentList.push(list[1].trim()); continue; }
    const pair = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!pair) continue;
    const [, key, value] = pair;
    if (!value) { metadata[key] = []; currentList = metadata[key]; }
    else { currentList = null; metadata[key] = value.replace(/^['"]|['"]$/g, ''); }
  }
  return {metadata, body: source.slice(end + 4), findings: []};
}

function designReport(file) {
  const source = readText(file);
  const parsed = parseFrontMatter(source);
  const findings = [...parsed.findings];
  if (!parsed.metadata.name) findings.push({severity: 'error', code: 'missing_name'});
  const headings = [...parsed.body.matchAll(/^#{1,2}\s+(.+)$/gm)].map(match => match[1].trim());
  const expected = ['Overview', 'Colors', 'Typography', 'Layout', 'Elevation & Depth', 'Shapes', 'Components', "Do's and Don'ts"];
  let last = -1;
  for (const section of headings) {
    const index = expected.indexOf(section);
    if (index >= 0 && index < last) findings.push({severity: 'error', code: 'section_order', message: section});
    if (index >= 0) last = index;
  }
  const references = [...source.matchAll(/\{([A-Za-z0-9_.-]+)\}/g)].map(match => match[1]);
  for (const reference of references) {
    const root = reference.split('.')[0];
    if (!(root in parsed.metadata)) findings.push({severity: 'warning', code: 'unresolved_reference', message: reference});
  }
  if (!/\b(hover|active|pressed|disabled|loading|success|empty|error|cancel)/i.test(parsed.body)) findings.push({severity: 'warning', code: 'missing_component_states'});
  if (!/\b(accessib|focus|keyboard|screen reader|aria)/i.test(parsed.body)) findings.push({severity: 'warning', code: 'missing_accessibility_contract'});
  return {status: findings.some(f => f.severity === 'error') ? 'fail' : findings.length ? 'pass_with_warnings' : 'pass', file, metadata: parsed.metadata, headings, references, findings};
}

function commandExists(command) {
  if (command === 'adb') {
    const roots = [process.env.ANDROID_HOME, process.env.ANDROID_SDK_ROOT, path.join(process.env.HOME || '', 'Android', 'Sdk')].filter(Boolean);
    if (roots.some(root => fs.existsSync(path.join(root, 'platform-tools', 'adb')))) return true;
  }
  const result = spawnSync('bash', ['-lc', `command -v ${command}`], {encoding: 'utf8'});
  return result.status === 0;
}

function setupReport() {
  const tools = ['node', 'agent-browser', 'npx', 'adb', 'xcrun', 'idb', 'osascript', 'powershell.exe', 'pwsh', 'xdotool', 'wmctrl'];
  const available = Object.fromEntries(tools.map(tool => [tool, commandExists(tool)]));
  const scripts = ['webmcp-agent-browser.sh', 'webmcp-chrome-devtools.sh', 'webmcp-android.sh', 'webmcp-ios.sh', 'webmcp-desktop.sh', 'webmcp-device.sh', 'webmcp-toolkit.sh'];
  const executable = Object.fromEntries(scripts.map(script => [script, Boolean(fs.existsSync(path.join(repo, 'scripts', script)) && (fs.statSync(path.join(repo, 'scripts', script)).mode & 0o111))]));
  return {status: available.node && available.npx && scripts.every(script => executable[script]) ? 'ready' : 'incomplete', platform: process.platform, available, executable};
}

function doctorReport() {
  const checks = [];
  const validate = spawnSync('bash', ['scripts/validate-skills.sh'], {cwd: repo, encoding: 'utf8'});
  checks.push({name: 'skill-validation', status: validate.status === 0 ? 'pass' : 'fail', output: (validate.stdout || validate.stderr).trim()});
  checks.push({name: 'setup', ...setupReport()});
  const fixtureChecks = [
    ['schema-fixture', path.join(repo, 'tests/fixtures/tools.json'), schemaFindings],
    ['security-fixture', path.join(repo, 'tests/fixtures/tools.json'), securityReport],
    ['eval-fixture', path.join(repo, 'tests/fixtures/evals.json'), evalReport],
    ['design-fixture', path.join(repo, 'tests/fixtures/DESIGN.md'), designReport],
  ];
  for (const [name, file, fn] of fixtureChecks) {
    try { const result = fn(name === 'design-fixture' ? file : readJson(file)); checks.push({name, status: result.status === 'fail' || result.status === 'invalid' ? 'fail' : 'pass', result}); }
    catch (error) { checks.push({name, status: 'fail', error: error.message}); }
  }
  return {status: checks.some(check => check.status === 'fail') ? 'fail' : 'pass', checks};
}

const command = args[0];
if (!command || command === '--help' || command === '-h') { usage(); process.exit(0); }
try {
  if (command === 'schema') {
    const result = schemaFindings(readJson(args[1] || '-'));
    emit({...result, status: result.findings.some(f => f.severity === 'error') ? 'fail' : 'pass'});
  }
  else if (command === 'security') emit(securityReport(readJson(args[1] || '-')));
  else if (command === 'eval') emit(evalReport(readJson(args[1] || '-')));
  else if (command === 'design') emit(designReport(args[1] || fail('design requires a DESIGN.md path')));
  else if (command === 'setup') emit(setupReport());
  else if (command === 'doctor') emit(doctorReport());
  else fail(`unknown command: ${command}`);
} catch (error) {
  fail(error.message);
}
