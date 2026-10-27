# README presentation assets

[← Back to MacTextify](../README.md)

## Native screenshots

The two README images were composed from real window captures of the locally packaged MacTextify 0.3.0 app, running source revision `f251841ede4f642ca533d9d3995b5289ece502c4`, on 25 October 2026 (Australia/Melbourne). Product source was not modified for the captures.

Three synthetic PNGs — **Meeting recap**, **Project notes**, and **Reading list** — were created for this presentation. They contain invented, general-purpose text. The batch used **Live Text**, **Text (.txt)** and **New subfolder**. The app reported **Finished. 3 of 3 images available.** Each transcript was compared with its synthetic source text; all matched. SHA-256 checks confirmed that all three input images were unchanged.

The **Needs Review** row states are intentional: Live Text does not expose confidence scores. Successful extraction is not a claim that arbitrary OCR is error-free.

| Asset | Selection and treatment |
| --- | --- |
| [app-workspace.png](../assets/readme/app-workspace.png) | Completed batch with settings expanded, paired with the actual synthetic Project notes input. Chosen over the empty and queued states because it shows a successful result and the save controls. |
| [app-detail.png](../assets/readme/app-detail.png) | The same completed batch with settings collapsed, alongside the actual Project notes export open in TextEdit. The editor capture is cropped to the text area. |

Both compositions are 1760 × 1120 PNGs, displayed at up to 880 pixels in the README. The captures were scaled and arranged on neutral presentation backgrounds; captions, framing and surrounding typography were added. App controls, row states and recognized text were not redrawn or replaced. The dark surround of the second image is presentation framing, not a claim of a dark-mode app capture. No private study inputs or personal paths appear in these published images.

On 28 October 2026, the workspace composition was rendered again from the same native capture and synthetic input, changing its surrounding caption to “A folder of images.” for the broader image-to-text positioning. The original capture files and prior composition source were retained. The workflow diagram titles were also updated to “From images to text files” in both editable HTML sources and SVG exports; their geometry and processing steps are unchanged.

To make fresh captures, create synthetic images with large black text on white, add them with the native picker, choose a fresh local demo destination, and extract. Compare actual exports and input hashes. Capture the app window with settings expanded and collapsed; open one resulting text file in an editor. Keep the real **Needs Review** labels. Do not substitute a mock app interface or use private documents as fixtures.

## Workflow diagram

The diagram was authored with [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design), revision `0b9b10cab3dbf695642fa1a6c4b4f60df9083689`. It uses that project's architecture layout guidance, accessible SVG contract, self-check, geometry checker and SVG export helper. The MacTextify monochrome palette was approved for this project. System fonts match the native app; the diagram makes no font or other network requests.

- Editable sources: [light HTML](../assets/readme/workflow.html) and [dark HTML](../assets/readme/workflow-dark.html).
- README exports: [light SVG](../assets/readme/workflow.svg) and [dark SVG](../assets/readme/workflow-dark.svg).
- Four nodes describe inputs, local Apple OCR, exports/index, and saved recovery records. The native-app preservation note is scoped to the GUI; CLI archival remains optional.

Using a separately reviewed checkout of that pinned diagram-design revision, regenerate each SVG with:

```sh
python3 /path/to/diagram-design/skills/diagram-design/scripts/self_check.py --offline assets/readme/workflow.html
python3 /path/to/diagram-design/scripts/verify-geometry.py assets/readme/workflow.html
python3 /path/to/diagram-design/skills/diagram-design/scripts/export_svg.py assets/readme/workflow.html --system-fonts
```

Repeat with `workflow-dark.html`. The skill was used from a temporary checkout; no global installation is required by MacTextify.

The staged skill received a SkillSpector `--no-llm` scan and manual inspection before its helpers ran. The scan reported 24 findings and partial coverage, including parser limits, wording in sample diagrams, and profile persistence instructions. Manual triage of the used instructions and helpers found no credential reads, subprocess execution, installation hooks or destructive file operations in the helpers used here. The SVG helper reads the supplied HTML and writes the supplied export; the checkers read local files. This bounded inspection is not a clean bill of health for every sample, importer or future revision. The candidate was not installed globally.

## Design references

The centered identity and navigation draw on [Ponytail](https://github.com/dietrichgebert/ponytail). Restrained badge framing draws on [shieldcn](https://github.com/jal-co/shieldcn). The badges here are local SVG assets with static platform/license facts; there are no external badge, tracking, or star-count requests. Those references did not activate their skills or add their dependencies.
