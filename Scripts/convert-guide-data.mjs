import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const sourcePath = path.resolve(scriptDirectory, '../../work/davinci-guide/src/data.js');
const outputPath = path.resolve(scriptDirectory, '../INSCENEWorkbench/Resources/Content/guide-content.json');
const detailTranslationPath = path.resolve(scriptDirectory, 'guide-detail-translations.json');
const expectedCounts = { stages: 10, shortcuts: 61, recipes: 18, colorPasses: 6, exports: 8, emergencies: 12 };

const englishTranslations = {
  'stage-project': ['Set Up the Project', 'Create a project foundation that will not cause problems later.'],
  'stage-media': ['Import and Organize', 'Make every shot findable within ten seconds.'],
  'stage-rough': ['Rough Cut', 'Build a complete watchable story quickly.'],
  'stage-fine': ['Fine Cut', 'Make each edit serve emotion and meet delivery standards.'],
  'stage-audio': ['Audio', 'Keep dialogue effortless to hear and believable in the picture.'],
  'stage-color': ['Color', 'Establish a consistent, credible image before building a look.'],
  'stage-title': ['Titles and Graphics', 'Keep information accurate, readable, and suited to the delivery frame.'],
  'stage-qc': ['Full Program QC', 'Find mistakes before viewers and clients do.'],
  'stage-export': ['Export and Delivery', 'Deliver a playable, color-correct, traceable master.'],
  'stage-archive': ['Archive', 'Preserve the project, decisions, master, and recovery path.'],
  'nav-project': ['Project Manager', 'Return to the Project Manager.'], 'nav-media': ['Media Page', 'Manage, inspect, and import media.'],
  'nav-cut': ['Cut Page', 'Open the Cut page for fast assembly.'], 'nav-edit': ['Edit Page', 'Open the traditional nonlinear editing page.'],
  'nav-fusion': ['Fusion Page', 'Open the node-based compositing page.'], 'nav-color': ['Color Page', 'Open the Color page.'],
  'nav-fairlight': ['Fairlight Page', 'Open the professional audio page.'], 'nav-deliver': ['Deliver Page', 'Open rendering and delivery.'],
  'nav-settings': ['Project Settings', 'Open settings for the current project.'], 'play-space': ['Play / Stop', 'The essential playback toggle.'],
  'play-j': ['Reverse Playback', 'Press J repeatedly to increase reverse playback speed.'], 'play-k': ['Stop', 'The central stop key for J/K/L playback.'],
  'play-l': ['Forward Playback', 'Press L repeatedly to increase forward playback speed.'], 'frame-left': ['Previous Frame', 'Inspect an edit point or lip sync one frame at a time.'],
  'frame-right': ['Next Frame', 'Inspect flash frames and action one frame at a time.'], 'edit-prev': ['Previous Edit Point', 'Jump to the previous timeline edit point.'],
  'edit-next': ['Next Edit Point', 'Jump to the next timeline edit point.'], 'mark-in': ['Mark In', 'Set the start of a source or timeline selection.'],
  'mark-out': ['Mark Out', 'Set the end of a selection.'], 'mark-clip': ['Mark Clip', 'Set the current clip boundaries as in and out points.'],
  'marker-add': ['Add Marker', 'Press once to add a marker and again to edit it.'], 'tool-select': ['Selection Mode', 'Return to the standard selection arrow.'],
  'tool-trim': ['Trim Edit Mode', 'Trim with ripple, roll, slip, and slide behavior based on pointer position.'],
  'tool-blade': ['Blade Edit Mode', 'Use the blade tool; press A when you are done.'], 'split-playhead': ['Split at Playhead', 'Split selected tracks at the playhead without changing tools.'],
  'snap-toggle': ['Snapping Toggle', 'Disable temporarily for precise moves and restore afterward.'], 'edit-insert': ['Insert Edit', 'Insert at the playhead and push later material forward.'],
  'edit-overwrite': ['Overwrite Edit', 'Overwrite target tracks without changing timeline length.'], 'edit-replace': ['Replace Edit', 'Replace a shot by aligning source and timeline current frames.'],
  'edit-fit-fill': ['Fit to Fill', 'Retiming fills a timeline range with a source range.'], 'undo': ['Undo', 'Undo the most recent operation.'],
  'redo': ['Redo', 'Restore the operation you just undid.'], 'delete-ripple': ['Ripple Delete', 'Delete and close the gap; watch downstream sync.'],
  'trim-extend': ['Extend Edit to Playhead', 'Extend the nearest edit point to the playhead.'], 'edit-point': ['Select Nearest Edit Point', 'Select the edit point near the playhead for keyboard trimming.'],
  'transition-default': ['Add Default Transition', 'Add the default video transition at a selected edit.'], 'link-clips': ['Link / Unlink Clips', 'Toggle linking for selected audio and video.'],
  'node-serial': ['Add Serial Node', 'Add the common serial node after the current node.'], 'node-parallel': ['Add Parallel Node', 'Create parallel branches merged by a parallel mixer.'],
  'node-layer': ['Add Layer Node', 'Create a node structure composited in layer order.'], 'node-disable': ['Enable / Disable Current Node', 'Compare the current node before and after its adjustment.'],
  'grade-bypass': ['Bypass All Grades', 'Quickly compare the original image and full grade.'], 'highlight-toggle': ['Highlight Mode', 'View qualifier, window, or matte selections.'],
  'grab-still': ['Grab Still', 'Save the current grade to the Gallery for matching.'], 'render-queue': ['Add to Render Queue', 'Map a shortcut in Keyboard Customization when the layout has none.'],
  'full-screen': ['Full Screen Viewer', 'Confirm the shortcut in Keyboard Customization because context can vary.'], 'clear-in': ['Clear In', 'Clear only the in point.'],
  'clear-out': ['Clear Out', 'Clear only the out point.'], 'clear-inout': ['Clear In and Out', 'Clear the current range.'],
  'marker-next': ['Next Marker', 'Jump to the next timeline marker.'], 'edit-append': ['Append to Timeline End', 'Append to the current timeline regardless of playhead position.'],
  'edit-place-top': ['Place on Top Track', 'Place media on a new track above existing picture.'], 'select-all': ['Select All', 'Select every item in the current context.'],
  'deselect-all': ['Deselect All', 'Clear the current selection.'], 'timeline-start': ['Timeline Start', 'Jump to the first frame of the timeline.'],
  'timeline-end': ['Timeline End', 'Jump to the last frame of the timeline.'], 'delete-normal': ['Delete and Leave Gap', 'Remove a clip while preserving the timeline gap.'],
  'edit-side-toggle': ['Toggle Edit Point Side', 'Cycle left, right, and rolling edit points.'], 'find-media': ['Find Media', 'Find media in the current media pool or list context.'],
  'clip-grade-prev': ['Previous Clip', 'Move to the previous clip on the Color page.'], 'clip-grade-next': ['Next Clip', 'Move to the next clip on the Color page.'],
  'recipe-rough': ['15-Minute Rough Cut', 'Create a complete story without getting lost in detail.'], 'recipe-three-point': ['Three-Point Editing', 'Use three boundaries to place source precisely in the timeline.'],
  'recipe-four-point': ['Four-Point Editing / Fit to Fill', 'Make a source range fill a timeline range precisely.'], 'recipe-jcut': ['J Cut: Audio First', 'Let the next shot’s audio lead viewers into the new space.'],
  'recipe-lcut': ['L Cut: Picture Leaves, Audio Stays', 'Keep the previous shot’s audio over a reaction or new picture.'], 'recipe-match-frame': ['Match Frame to Find Source', 'Locate a timeline shot’s source while retaining the current frame.'],
  'recipe-replace': ['Replace Edit', 'Replace a current shot without changing its timeline position or duration.'], 'recipe-dialogue': ['Dialogue Cleanup and Continuity', 'Make edited dialogue sound like it belongs in one space.'],
  'recipe-speed': ['Natural Speed Changes', 'Give speed ramps motivation without visible stutter.'], 'recipe-stabilize': ['Stabilize a Shot', 'Reduce unintended shake while preserving intentional movement.'],
  'recipe-balance': ['Primary Correction', 'Use scopes to establish believable exposure, white balance, and saturation.'], 'recipe-match-shots': ['Shot Matching', 'Keep angles in one scene continuous in brightness, white balance, and saturation.'],
  'recipe-skin': ['Secondary Skin Correction', 'Correct skin without contaminating the background.'], 'recipe-nodes': ['Professional Node Structure', 'Separate technical, subject, and look adjustments for reuse and revision.'],
  'recipe-window': ['Windows and Tracking', 'Guide attention locally without leaving visible artifacts.'], 'recipe-denoise': ['Denoise, Sharpen, and Grain Order', 'Balance detail, noise, and texture.'],
  'recipe-qc': ['Three-Pass QC', 'Check story, technical details, and sound separately.'], 'recipe-archive': ['Recoverable Archive', 'Keep a project recoverable after months or on a different computer.'],
  'color-input': ['Input and Project Management', 'Keep input interpretation and output management consistent.'], 'color-balance': ['Primary Balance', 'Establish a credible baseline for exposure, white balance, and saturation.'],
  'color-match': ['Shot Matching', 'Maintain continuity between shots in the same scene.'], 'color-skin': ['Skin and Local Adjustments', 'Correct people without contaminating the background.'],
  'color-look': ['Look and Node Structure', 'Keep technical adjustments and creative looks independently reviewable.'], 'color-finish': ['Sharpening, Grain, and Pre-Export Check', 'Preserve detail and texture, then verify in the real delivery environment.'],
  'ex-review': ['WeChat Review', 'Send a fast review copy with a sensible size-to-quality balance.'], 'ex-web': ['Video Platforms', 'Upload for YouTube, Bilibili, and similar services.'],
  'ex-vertical': ['Vertical Short Video', 'Deliver a 9:16 version for Douyin, Reels, and similar platforms.'], 'ex-master': ['High-Quality Master', 'Preserve a master for long-term storage and future distribution versions.'],
  'ex-color': ['Hand Off to a Colorist', 'Preserve source quality, timecode, and handles.'], 'ex-broadcast': ['Broadcast Television', 'Follow the channel delivery specification exactly.'],
  'ex-dcp': ['Cinema DCP', 'Create a cinema package and perform formal quality control.'], 'ex-alpha': ['Graphics with Alpha', 'Deliver lower thirds, logo animation, or compositing elements with transparency.'],
  'em-offline': ['Media Offline', 'The image displays the red Media Offline warning.'], 'em-lag': ['Severe Playback Lag', 'The timeline drops frames or audio stutters.'],
  'em-sync': ['Audio Out of Sync', 'Lip sync drifts gradually even when the start is in sync.'], 'em-washed': ['Export Looks Washed Out or Bright', 'The Resolve image looks right but QuickTime or a platform looks brighter or washed out.'],
  'em-proxy': ['Proxy Switch Produces the Wrong Image', 'Shots are offset, offline, or exports still resemble low-resolution proxies.'], 'em-cache': ['Cache Is Wrong or Not Updating', 'You see an old effect or the cache repeatedly rebuilds.'],
  'em-subtitle': ['Subtitles Missing from Export', 'Subtitles are visible in the timeline but absent from the output.'], 'em-render': ['Render Fails or Stops on a Frame', 'A render errors, stops, or hangs at a fixed location.'],
  'em-audio': ['No Audio in the Export', 'The timeline plays sound but the export is silent or missing channels.'], 'em-black': ['Black or Flash Frame', 'A brief black frame appears at an edit.'],
  'em-save': ['Project Closed Unexpectedly or Was Damaged', 'A crash or mistaken change leaves no stable version.'], 'em-plugin': ['Missing Plug-ins or Fonts on Another Computer', 'Titles substitute fonts, effects fail, or the image differs.']
};
const englishDetailTranslations = JSON.parse(fs.readFileSync(detailTranslationPath, 'utf8'));

const sandbox = { window: {} };
vm.runInNewContext(fs.readFileSync(sourcePath, 'utf8'), sandbox, { filename: sourcePath });
const legacy = sandbox.window.GUIDE_DATA;

for (const [key, expected] of Object.entries(expectedCounts)) {
  if (!Array.isArray(legacy[key]) || legacy[key].length !== expected) throw new Error(`Expected ${expected} ${key}, found ${legacy[key]?.length ?? 0}`);
}

const allLegacyRecords = Object.values(legacy).flat();
const stableIDs = new Set(allLegacyRecords.map((record) => record.id));
if (stableIDs.size !== allLegacyRecords.length) throw new Error('Legacy source contains duplicate IDs');
for (const id of stableIDs) if (!englishTranslations[id]) throw new Error(`Missing English translation for ${id}`);
for (const id of Object.keys(englishTranslations)) if (!stableIDs.has(id)) throw new Error(`Translation references unknown ID ${id}`);

const localized = (id, value, translationIndex) => ({ zhHans: value, en: englishTranslations[id][translationIndex] });
const titled = (record, summary) => ({ title: localized(record.id, record.title, 0), summary: localized(record.id, summary, 1) });
const detailText = (id, field, value, index = 0) => {
  const translated = englishDetailTranslations[id]?.[field]?.[index];
  if (!translated) throw new Error(`Missing English detail translation for ${id}.${field}[${index}]`);
  return { zhHans: value, en: translated };
};
const detailTexts = (id, field, values = []) => values.map((value, index) => detailText(id, field, value, index));

const content = {
  contentVersion: 1,
  stages: legacy.stages.map((record) => ({ id: record.id, kind: 'stage', number: record.number, color: record.color, ...titled(record, record.goal), quickSteps: detailTexts(record.id, 'quickSteps', record.quickSteps), proSteps: detailTexts(record.id, 'proSteps', record.proSteps), shortcutIDs: record.shortcutIds, mistake: detailText(record.id, 'mistake', record.mistake), doneCheck: detailText(record.id, 'doneCheck', record.doneCheck), proNotes: detailTexts(record.id, 'proNotes', record.proNotes) })),
  shortcuts: legacy.shortcuts.map((record) => ({ id: record.id, kind: 'shortcut', category: detailText(record.id, 'category', record.category), stages: record.stages, ...titled(record, record.summary), mac: record.mac, win: record.win, menuZh: record.menuZh, menuEn: record.menuEn, level: record.level, flags: record.flags })),
  recipes: legacy.recipes.map((record) => ({ id: record.id, kind: 'recipe', category: detailText(record.id, 'category', record.category), ...titled(record, record.goal), scene: detailText(record.id, 'scene', record.scene), steps: detailTexts(record.id, 'steps', record.steps), risk: detailText(record.id, 'risk', record.risk), doneCheck: detailText(record.id, 'doneCheck', record.doneCheck), shortcutIDs: record.shortcutIds ?? [] })),
  colorPasses: legacy.colorPasses.map((record) => ({ id: record.id, kind: 'colorPass', ...titled(record, record.goal), steps: detailTexts(record.id, 'steps', record.steps), doneCheck: detailText(record.id, 'doneCheck', record.doneCheck), risk: detailText(record.id, 'risk', record.risk), shortcutIDs: record.shortcutIds, tools: detailTexts(record.id, 'tools', record.tools), scopes: detailTexts(record.id, 'scopes', record.scopes), commonMistakes: detailTexts(record.id, 'commonMistakes', record.commonMistakes) })),
  exports: legacy.exports.map((record) => ({ id: record.id, kind: 'export', ...titled(record, record.desc), specification: Object.entries(record.spec).map(([label, value], index) => ({ label: detailText(record.id, 'specificationLabels', label, index), value: detailText(record.id, 'specificationValues', value, index) })), risk: detailText(record.id, 'risk', record.risk), bitrate: detailText(record.id, 'bitrate', record.bitrate), subtitles: detailTexts(record.id, 'subtitles', record.subtitles), fileChecks: detailTexts(record.id, 'fileChecks', record.fileChecks) })),
  emergencies: legacy.emergencies.map((record) => ({ id: record.id, kind: 'emergency', ...titled(record, record.symptom), cause: detailText(record.id, 'cause', record.cause), fix: detailTexts(record.id, 'fix', record.fix), deep: detailText(record.id, 'deep', record.deep), prevent: detailText(record.id, 'prevent', record.prevent) })),
  playbooks: [], creators: [], sources: []
};

const sortKeys = (value) => Array.isArray(value) ? value.map(sortKeys) : value && typeof value === 'object'
  ? Object.fromEntries(Object.keys(value).sort().map((key) => [key, sortKeys(value[key])])) : value;
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(sortKeys(content), null, 2)}\n`);
console.log(Object.entries(expectedCounts).map(([key, count]) => `${key}=${count}`).join(' '));
