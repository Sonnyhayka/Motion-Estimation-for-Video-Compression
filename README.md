# CompE 565 HW3: Motion Estimation for Video Compression

Full search (exhaustive) block motion estimation on 5 frames of the `walk_qcif`
sequence, with residual frames, motion vector plots, and motion compensated
reconstruction.

## Quick start

```matlab
cd('path/to/Motion-Estimation-for-Video-Compression')
step02_setup          % set up folders, load frames 16 to 20, write previews
```

`step02_setup` bootstraps its own path, so it works from the project root or
via `run(...)` from anywhere.

## Layout

```
data/walk_qcif.avi     source clip (176x144 QCIF, 37 frames, 30 fps, RGB24)
src/hw3Params.m        spec constants from the HW3 PDF, single source of truth
src/setupProject.m     path and results folders, idempotent
src/loadWalkSequence.m reads frames 16 to 20, splits luma and 4:2:0 chroma
src/checkProjectCode.m Code Analyzer over src, tests and the root scripts
step02_setup.m         step 2 demo: load, report, export preview images
tests/                 unit tests, run with runtests('tests')
results/frames/        generated preview PNGs
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

## Status

- [x] **02** Project folder and `walk_qcif` loaded. No `.yuv` conversion was
      needed because the supplied `.avi` is already valid.
- [ ] 03 Exhaustive search (SAD), motion vectors, residual frames, reconstruction
- [ ] 04 Report: results, `quiver` plots, computational load analysis

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
