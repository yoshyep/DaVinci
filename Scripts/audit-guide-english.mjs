import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const contentPath = path.resolve(scriptDirectory, '../INSCENEWorkbench/Resources/Content/guide-content.json');
const content = JSON.parse(fs.readFileSync(contentPath, 'utf8'));

const expectedCounts = {
  stages: 144,
  shortcuts: 61,
  recipes: 157,
  colorPasses: 74,
  exports: 184,
  emergencies: 72
};

const pairs = [];
const collect = (domain, id, field, values) => {
  const localizedValues = Array.isArray(values) ? values : [values];
  localizedValues.forEach((value, index) => {
    if (!value || typeof value.zhHans !== 'string' || typeof value.en !== 'string') {
      throw new Error(`Invalid localized value at ${id}.${field}[${index}]`);
    }
    pairs.push({ domain, path: `${id}.${field}[${index}]`, zhHans: value.zhHans, en: value.en });
  });
};

for (const record of content.stages) {
  for (const field of ['quickSteps', 'proSteps', 'mistake', 'doneCheck', 'proNotes']) {
    collect('stages', record.id, field, record[field]);
  }
}
for (const record of content.shortcuts) collect('shortcuts', record.id, 'category', record.category);
for (const record of content.recipes) {
  for (const field of ['category', 'scene', 'steps', 'risk', 'doneCheck']) {
    collect('recipes', record.id, field, record[field]);
  }
}
for (const record of content.colorPasses) {
  for (const field of ['steps', 'doneCheck', 'risk', 'tools', 'scopes', 'commonMistakes']) {
    collect('colorPasses', record.id, field, record[field]);
  }
}
for (const record of content.exports) {
  record.specification.forEach((entry, index) => {
    collect('exports', record.id, `specificationLabels.${index}`, entry.label);
    collect('exports', record.id, `specificationValues.${index}`, entry.value);
  });
  for (const field of ['risk', 'bitrate', 'subtitles', 'fileChecks']) {
    collect('exports', record.id, field, record[field]);
  }
}
for (const record of content.emergencies) {
  for (const field of ['cause', 'fix', 'deep', 'prevent']) {
    collect('emergencies', record.id, field, record[field]);
  }
}

for (const [domain, expected] of Object.entries(expectedCounts)) {
  const actual = pairs.filter((pair) => pair.domain === domain).length;
  if (actual !== expected) throw new Error(`Expected ${expected} ${domain} detail pairs, found ${actual}`);
}
if (pairs.length !== 692) throw new Error(`Expected 692 detail pairs, found ${pairs.length}`);

const prohibitedPatterns = [
  ['proxy translated as agent', /\bagent\b/i],
  ['film grain translated as particles', /\bparticles?\b/i],
  ['codec label translated as coding', /\bcoding\b/i],
  ['bitrate translated as code rate', /\bcode rate\b/i],
  ['codec profile translated as encoding gear', /\bencoding gear\b/i],
  ['handles translated as credits', /\bcredits\b/i],
  ['sidecar subtitles called plug-ins', /plug-in (?:methods?|SRT)|burning\/plugging/i],
  ['subtitle burn-in called burning', /\bburning\b/i],
  ['scopes translated as an oscilloscope', /\boscilloscope\b/i],
  ['proxy originals called original film', /\boriginal film\b/i],
  ['flattened media called flat film', /\b(?:flat|plain) film\b/i],
  ['clip gain translated as segment gain', /\bsegment gain\b/i],
  ['perceived loudness called subjective loudness', /\bsubjective loudness\b/i],
  ['handles called front and rear margins', /\bfront and rear margin\b/i],
  ['picture lock called screen lock', /\bscreen lock\b/i],
  ['reframing called refactoring', /\brefactoring\b/i],
  ['reframed shots called reconstructed footage', /\breconstructed footage\b/i],
  ['temporal or spatial NR called time/spatial domain NR', /\b(?:time|spatial) domain noise reduction\b/i],
  ['machine-translated black-level phrase', /black level manufacturing|manufacturing comparison/i],
  ['invisible Unicode spacing', /[\u200B-\u200D\uFEFF]/u]
];

for (const [description, pattern] of prohibitedPatterns) {
  const match = pairs.find((pair) => pattern.test(pair.en));
  if (match) throw new Error(`${description} at ${match.path}: ${match.en}`);
}

const allEnglish = pairs.map((pair) => pair.en).join('\n');
const terminologyChecklist = [
  ['editing', [/three-point editing/i, /Source Viewer/, /Match Frame/, /retime/i]],
  ['audio', [/clip gain/i, /room tone/i, /track-to-bus/i]],
  ['grading/scopes/nodes', [/Waveform/, /RGB Parade/, /Vectorscope/, /bypassed/i]],
  ['color management', [/DaVinci YRGB Color Managed/, /Color Space Transform/, /output transform/i]],
  ['grain/noise reduction', [/film grain/i, /temporal noise reduction/i, /spatial noise reduction/i]],
  ['subtitles', [/burn-in/i, /sidecar/i, /embedded/i]],
  ['export/delivery/QC', [/render queue/i, /delivery/i, /\bQC\b/]],
  ['codec/profile/bitrate', [/container/i, /codec profile/i, /bitrate/i]],
  ['handles', [/handles/i]],
  ['proxy/original media/relink', [/proxy media/i, /original media/i, /relink/i]],
  ['conform/round-trip', [/conforms/i, /round-trip/i]]
];

for (const [domain, patterns] of terminologyChecklist) {
  for (const pattern of patterns) {
    if (!pattern.test(allEnglish)) throw new Error(`Missing ${domain} terminology matching ${pattern}`);
  }
}

const counts = Object.keys(expectedCounts).map((domain) => `${domain}=${expectedCounts[domain]}`).join(' ');
console.log(`pairs=${pairs.length} ${counts}`);
console.log(`terminology=${terminologyChecklist.map(([domain]) => domain).join('; ')}`);
console.log(`professional-English audit passed: ${prohibitedPatterns.length} prohibited-pattern checks`);
