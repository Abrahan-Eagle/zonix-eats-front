#!/usr/bin/env python3
# ZonixPharma Front Skills Sync Script (JARVIS Powered)

import os
import re

AGENTS_FILE = 'AGENTS.md'
SKILLS_DIR = '.agents/skills'
SKILL_INDEX_FILE = os.path.join(SKILLS_DIR, 'SKILL_INDEX.md')
MANIFEST_FILE = os.path.join(SKILLS_DIR, '.global-sync-manifest')

def load_manifest_tiers():
    tiers = {}
    if not os.path.exists(MANIFEST_FILE):
        return tiers
    with open(MANIFEST_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.split('#', 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) >= 2:
                tiers[parts[0]] = parts[1]
    return tiers

def write_skill_index(skills, tiers):
    lines = [
        '# SKILL_INDEX — generado por sync.sh (no editar a mano)',
        '',
        'Índice compacto para Skill Bootstrap. Skills solo en `~/.cursor/skills/` no aparecen aquí.',
        '',
        '| Skill | Capa | Tier | Auto-invoke (muestra) |',
        '|-------|------|------|------------------------|',
    ]
    for s in skills:
        name = s['name']
        tier = tiers.get(name, 'local-only')
        auto = '; '.join(s['auto_invokes'][:2]) if s['auto_invokes'] else '—'
        if len(s['auto_invokes']) > 2:
            auto += '…'
        lines.append(f"| `{name}` | local | {tier} | {auto} |")
    content = '\n'.join(lines) + '\n'
    with open(SKILL_INDEX_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ {SKILL_INDEX_FILE} generado ({len(skills)} skills).")

def extract_yaml(content):
    match = re.search(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match: return None
    import yaml
    try:
        return yaml.safe_load(match.group(1))
    except Exception as e:
        print(f"YAML Parse Error: {e}")
        return None

def sync():
    print("🔄 JARVIS Sync (Python Engine): Generando tablas robustas para AGENTS.md...")

    if not os.path.exists(AGENTS_FILE):
        print(f"❌ Error: {AGENTS_FILE} not found.")
        return

    skills = []

    for root, dirs, files in os.walk(SKILLS_DIR):
        if 'SKILL.md' in files:
            path = os.path.join(root, 'SKILL.md')
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                data = extract_yaml(content)
                if data:
                    name = data.get('name', 'Unknown')
                    desc = data.get('description', '').strip().replace('\n', ' ').split('Trigger:')[0].strip()
                    auto_invoke_raw = data.get('metadata', {}).get('auto_invoke', [])

                    auto_invokes = []
                    if isinstance(auto_invoke_raw, list):
                        auto_invokes = auto_invoke_raw
                    elif isinstance(auto_invoke_raw, str) and auto_invoke_raw:
                        auto_invokes = [auto_invoke_raw]

                    rel_path = os.path.relpath(path, '.').replace('\\', '/')
                    skills.append({
                        'name': name,
                        'desc': desc,
                        'path': rel_path,
                        'auto_invokes': auto_invokes
                    })

    skills.sort(key=lambda x: x['name'])

    skills_md = "| Skill | Descripción | Ruta |\n|-------|-------------|------|\n"
    for s in skills:
        n = s['name']
        d = s['desc']
        p = s['path']
        if n.startswith('zonix-') or n == 'jarvis-core':
            skills_md += f"| **`{n}`** | **{d}** | [{p}]({p}) |\n"
        else:
            skills_md += f"| `{n}` | {d} | [{p}]({p}) |\n"

    auto_md = "| Acción | Skill |\n|--------|-------|\n"
    auto_entries = []
    for s in skills:
        for action in s['auto_invokes']:
            auto_entries.append((action, s['name']))

    auto_entries.sort(key=lambda x: x[0])
    for action, skill in auto_entries:
        auto_md += f"| {action} | `{skill}` |\n"

    with open(AGENTS_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    pat_skills = re.compile(r'(<!-- SKILLS-START -->\n).*?(\n<!-- SKILLS-END -->)', re.DOTALL)
    pat_auto = re.compile(r'(<!-- AUTO-INVOKE-START -->\n).*?(\n<!-- AUTO-INVOKE-END -->)', re.DOTALL)

    if pat_skills.search(content):
        content = pat_skills.sub(rf'\g<1>{skills_md.strip()}\g<2>', content)
        print("✅ Tabla de Skills actualizada.")
    else:
        print("⚠️ No se encontraron los marcadores <!-- SKILLS-START --> y <!-- SKILLS-END -->.")

    if pat_auto.search(content):
        content = pat_auto.sub(rf'\g<1>{auto_md.strip()}\g<2>', content)
        print("✅ Tabla de Auto-invoke actualizada.")
    else:
        print("⚠️ No se encontraron los marcadores <!-- AUTO-INVOKE-START --> y <!-- AUTO-INVOKE-END -->.")

    with open(AGENTS_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

    tiers = load_manifest_tiers()
    write_skill_index(skills, tiers)

    print("🎉 JARVIS Sync completado exitosamente.")

if __name__ == '__main__':
    sync()
