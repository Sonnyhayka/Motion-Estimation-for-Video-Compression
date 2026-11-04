# CompE 565 HW3: Motion Estimation for Video Compression

Full search (exhaustive) block motion estimation on 5 frames of the `walk_qcif`
sequence, with residual frames, motion vector plots, and motion compensated
reconstruction.

## Quick start

```matlab
cd('path/to/Motion-Estimation-for-Video-Compression')
step02_setup          % set up folders, load frames 16 to 20, write previews
step03_extractFrames  % type the frames I/P and write a 4:2:0 .yuv artifact
step04_residualFrames % predict each P frame and save signed residuals and previews
```

`step02_setup` and `step03_extractFrames` bootstrap their own path, so they
work from the project root or via `run(...)` from anywhere.

## Layout

```
data/walk_qcif.avi     source clip (176x144 QCIF, 37 frames, 30 fps, RGB24)
src/hw3Params.m        spec constants from the HW3 PDF, single source of truth
src/frameTypesFor.m    I/P typing from clip numbering and the GOP anchor
src/setupProject.m     path and results folders, idempotent
src/loadWalkSequence.m reads frames 16 to 20, splits luma and 4:2:0 chroma
src/writeYuv420.m      writes the frames as planar 8-bit 4:2:0 (.yuv)
src/extractMacroblock.m pulls one macroblock out of a plane (16x16 luma, 8x8 chroma)
src/extractSearchWindow.m pulls the search window around a macroblock out of the I frame
src/fullSearchMacroblock.m full search block matching with minimum SAD for one macroblock
src/fullSearchFrame.m  full search across a frame, storing vectors and matched blocks
src/checkProjectCode.m Code Analyzer over src, tests and the root scripts
step02_setup.m         step 2 demo: load, report, export preview images
step03_extractFrames.m step 3 demo: type frames, write the 4:2:0 .yuv file
step04_residualFrames.m compute and save the four P-frame residuals
tests/                 unit tests, run with runtests('tests')
results/frames/        generated preview PNGs
results/yuv/           generated 4:2:0 bitstream, ignored by git
results/figures/       reserved for motion vector and residual plots
```

## Conventions

**Frame numbering.** The clip's frame 16 is index `1` in the loaded sequence.
`S.frameNumbers` maps back to the original clip (`[16 17 18 19 20]`).

**Colour.** The `.avi` is stored as RGB24, not native YUV. `loadWalkSequence`
runs `rgb2ycbcr` and exposes:

| Field | Size | Use |
|---|---|---|
| `rgb` | 144x176x3x5 `uint8` | colour previews |
| `Y` | 144x176x5 `double` | motion estimation |
| `Y8` | 144x176x5 `uint8` | writing images and video |
| `Cb420`, `Cr420` | 72x88x5 `double` | 4:2:0 chroma discussion |

The assignment's `MATLAB Help_Project 3.pdf` uses `cdata(:,:,1)`, the **red**
channel, as luma. That is not luma, so this project uses the real `rgb2ycbcr`
luma instead. Note also that `aviread` from that PDF was removed from MATLAB
long ago, so this project uses `VideoReader`.

**Macroblocks.** 16x16, so the QCIF frame holds `11 x 9 = 99` macroblocks
(144/16 = 9 rows, 176/16 = 11 columns). Derived at load time, not hardcoded.

`extractMacroblock(plane, row, col)` takes 1-based macroblock grid indices, row
first, and returns the block plus `origin = [row col]` of its top-left pixel.
Mind the order against the PDF's `d = (dx, dy)`: `dx` is the column offset and
`dy` the row offset. The plane must be a whole number of blocks. A 4:2:0 chroma
plane (72x88) is half size, so pass `mbSize = 8` and it lands on the same 9x11
grid as luma; the default 16 is rejected rather than silently dropping the
right and bottom edges.

**Search window.** `extractSearchWindow(plane, row, col)` takes the same grid
indices, so pass it the I frame plane and the macroblock position from the
target frame. It returns the window plus `origin = [row col]` of the window's
top left pixel, which together with the block's own origin gives the
displacement of any candidate. The window is the macroblock plus `w = 7` pixels
on every side, so 30x30 in the interior. At the frame edge it is clipped, not
padded, so it keeps every candidate that lies fully inside the frame: 23x23 at
the four corners, 23x30 on the top and bottom rows, and 30x23 on the left and
right columns. `HW_3_SampleOutput.pdf` lists 22 pixel borders (22x22, 30x22,
22x30), which does not follow from the HW3 PDF's centered 30x30 window, so the
code follows the HW3 PDF. For chroma pass `mbSize = 8` and a radius to match,
for example `extractSearchWindow(plane, row, col, 8, 3)`.

**Full search.** `[mv, minSad, sadMap] = fullSearchMacroblock(target, reference,
row, col)` takes the macroblock at grid position `(row, col)` of the target
frame, scores every position of that block inside the matching search window of
the reference (the I frame), and returns the best displacement. Candidates are
scored with SAD as the HW3 PDF defines it, the sum of the absolute pixel
differences. `MATLAB Help_Project 3.pdf` shows `abs(sum(...))`, which lets
positive and negative errors cancel, so it is not used. Pixels are converted to
`double` first so `uint8` frames cannot saturate.

`mv = [dx dy]` follows the PDF's `d = (dx, dy)`: `dx` is the column offset and
`dy` the row offset, and the best matching block in the reference starts at
`origin + [dy dx]`, where `origin` is the target block's top left pixel from
`extractMacroblock`. `sadMap` holds every SAD, with row `r` and column `c`
standing for `dy = r - 8` and `dx = c - 8` in the interior, so its size is the
candidate count: 15x15 = 225 in the interior and fewer at the frame edge, for
example 8x8 = 64 in a corner. Ties go to the displacement nearest zero, then to
the smaller `dx`, then to the smaller `dy`, so a flat area gives the zero vector
instead of the first candidate in scan order. For chroma pass `mbSize = 8` and a
radius to match.

**Frame search.** `[vectors, matched, minSads] = fullSearchFrame(target,
reference)` applies that search to every macroblock. `vectors` is a 9x11x2
array for QCIF, with `vectors(row,col,1)` holding `dx` and the second plane
holding `dy`. `matched` is a reference-class plane with each selected block
placed at the corresponding target-grid position; `minSads` is a 9x11 array.
The grid is derived from the plane size. Optional `mbSize` and `radius`
arguments allow the same operation on other whole-block planes. Pass each P
frame as `target` and the I frame as `reference`.

**Residuals.** The fourth output of `fullSearchFrame` is the signed `double`
array `residual = double(target) - double(matched)`, so negative differences
are preserved even for `uint8` inputs. `step04_residualFrames` applies this to
frames 17 to 20 using frame 16 as the reference. It saves the numeric residuals
and their clip frame numbers in `results/frames/residual_frames.mat`, and PNG
previews in the same folder. The previews map residuals from -255 to 255 onto
black to white; zero appears approximately mid-gray. The MAT file retains the
actual differences for subsequent reconstruction.

**Frame types.** Frame 16 is the I frame; 17 to 20 are P frames, all predicted
from frame 16.

| Clip frame | Type | Reference |
|---|---|---|
| 16 | I | none |
| 17 | P | 16 |
| 18 | P | 16 |
| 19 | P | 16 |
| 20 | P | 16 |

Typing comes from clip numbering, not from position in the loaded slice:
an I frame is any frame where `mod(frame - 16, 6) == 0`, so the next I frame
is 22. `hw3Params` exposes `frameTypes`, `iFrame`, `pFrames` and `gopAnchor`,
and `loadWalkSequence` carries them on `S` with `referenceIndex` pointing at
the I frame. Loading a range that contains no I frame is an error rather than
a silent misprediction.

**4:2:0 bitstream.** `writeYuv420` writes planar 8-bit I420, one frame after
another: `Y` (144x176 = 25344 B), then `Cb` (72x88 = 6336 B), then `Cr`
(72x88 = 6336 B). That is 38016 B per frame and 190080 B for the five frames
of this assignment.

## Status

- [x] **02** Project folder and `walk_qcif` loaded. No `.yuv` conversion was
      needed because the supplied `.avi` is already valid.
- [x] **03** Frames 16 to 20 extracted at 176x144 in 4:2:0, typed as I then
      four P frames, with the planar `.yuv` written to `results/yuv/`.
- [ ] 04 Exhaustive search (SAD), motion vectors, residual frames, reconstruction
- [ ] 05 Report: results, `quiver` plots, computational load analysis

## Spec, as fixed by `CompE 565_HW3.pdf`

`CompE 565_HW3.pdf` is the authoritative document. Where it disagrees with
`MATLAB Help_Project 3.pdf`, the HW3 PDF wins.

| Parameter | Value | Source wording |
|---|---|---|
| Search window | **30x30**, centered on the current macroblock | "using the search window of 30x30 pixels, which is centered on the current macroblock" |
| Search radius | **w = 7** | implied by centering a 30 wide window on a 16 wide block |
| Candidate vectors | **225** per macroblock | `(2w+1)^2 = (2*7+1)^2 = 15^2` |
| Macroblock | **16x16** | "Use a macroblock size of 16x16 pixels" |
| Matching criteria | **SAD**, minimum | "Use the minimum SAD (sum of absolute difference) method" |
| Frames | **16 to 20** (5 frames) | "from frame #16 to frame #20" |
| Chroma | **4:2:0** | "you should use the 4:2:0 format" |
| Frame structure | **IPPPPP**, GOP 6 | "IPPPPP structure with GOP size of 6 frames" |
| Reference for all P frames | **the I frame (frame 16)** | "predict all the P frames from the I frame" |
| DCT and quantisation | **not performed** | "You need not perform DCT and Quantization" |
| Adds per candidate | **511** | "SAD requires 2x256 - 1 = 511 additions/subtractions" |

### Two corrections to the secondary documents

**Search window.** `MATLAB Help_Project 3.pdf` says 32x32 with "8 pixels in each
direction". That is a different document and is superseded. Note that 30x30 is
arithmetically consistent with the HW3 PDF's own `(2w+1)^2` formula, whereas a
32x32 window centred on a 16x16 block would give w = 8 and 17x17 = 289
candidates, which no part of the HW3 PDF supports.

**Reference frame.** `MATLAB Help_Project 3.pdf` advises progressively making
the current frame the reference for the next (`ref = current`). The HW3 PDF
says "predict all the P frames from the I frame", so frames 17 to 20 all
reference frame 16. This is the non-progressive choice and the PDF governs.

### Erratum worth noting in the report

The HW3 PDF's illustrative paragraph says a 352x288 frame has "1,584 macroblock
motion vectors". That figure corresponds to **8x8** blocks, not 16x16:
`(352/8)*(288/8) = 1584`, whereas `(352/16)*(288/16) = 396`. For this
assignment's QCIF frame with 16x16 blocks the count is `(176/16)*(144/16) = 99`.
The PDF's own macroblock size, SAD cost, and `(2w+1)^2` formula are all used
consistently; only this one count is stale.
