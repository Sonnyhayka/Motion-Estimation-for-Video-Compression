# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- CI now installs Image Processing Toolbox so frame-loading tests can call
  `rgb2ycbcr`, and uses Ubuntu 24.04 to avoid the unsupported Ubuntu 26.04 runner.

### Added

- Added `fullSearchFrame` to search every macroblock in a plane in one call, so
  a whole P frame can be predicted against the I frame instead of looping over
  blocks by hand. It returns the `[dx dy]` vectors, the minimum SAD for each
  block, and the selected reference blocks already placed at their target-grid
  positions, so the prediction can be compared with the target or written out
  without reassembling it.
- Added `fullSearchMacroblock` to run full search block matching for one
  macroblock, scoring every candidate in the search window with minimum SAD and
  returning the motion vector `mv = [dx dy]`, the minimum SAD, and the full SAD
  map. SAD is the sum of absolute differences from the HW3 PDF, not the
  `abs(sum(...))` shown in `MATLAB Help_Project 3.pdf`, which lets positive and
  negative errors cancel. Pixels are converted to `double` so `uint8` frames
  cannot saturate, and ties go to the displacement nearest zero so flat areas
  give the zero vector instead of the first candidate in scan order.
- Added `extractSearchWindow` to pull the search window for a macroblock out of
  the I frame using the same grid row and column as `extractMacroblock`,
  returning both the window and the top-left pixel `origin` that locates it.
  Knowing the origin lets the search turn any candidate position into a motion
  vector, and the window is clipped at the frame border instead of padded, so
  every candidate that stays inside the frame is still available. Interior
  blocks get the full 30x30 window while corners get 23x23 and edge blocks get
  23x30 or 30x23. These dimensions follow the HW3 PDF's centered window rather
  than the 22 pixel borders in `HW_3_SampleOutput.pdf`, which are inconsistent
  with a centered 30x30 window.
- Added `extractMacroblock` to pull one macroblock out of the target frame by
  1-based grid row and column, returning the block and its top-left pixel
  `origin`. It rejects planes that are not a whole number of blocks, so a
  4:2:0 chroma plane needs `mbSize = 8` instead of silently losing its right
  and bottom edges, and it converts integer-class indices to `double` so
  `int8` input cannot saturate into an empty block.
- Added `frameTypesFor` to type frames as I or P from clip numbering and the
  GOP anchor, so frame 16 is the I frame and a later GOP boundary at frame 22
  is found without hardcoding the loaded range.
- Added I/P typing to `hw3Params` (`gopAnchor`, `frameTypes`, `iFrame`,
  `pFrames`) so "IPPPP, GOP 6" is data the code can check rather than prose in
  a printout.
- Added `loadWalkSequence` typing fields (`frameTypes`, `iFrame`, `pFrames`,
  `referenceIndex`) plus a `loadWalkSequence:noIFrame` error, so a range
  without an I frame fails instead of silently predicting from a P frame.
- Added `writeYuv420` to write the extracted frames as planar 8-bit 4:2:0,
  38016 bytes per QCIF frame.
- Added `step03_extractFrames` to print the per-frame I/P table and write
  `results/yuv/walk_f16_20_yuv420p.yuv`, asserting the 190080 byte total.
- Added `results/yuv/` for generated bitstreams, ignored by git like the other
  result folders.
- Added `hw3Params` as the single source of truth for the assignment numbers
  (16x16 macroblocks, 30x30 centred search window, 225 candidate vectors, 511
  additions per SAD), so the motion estimation code cannot drift from
  `CompE 565_HW3.pdf`.
- Added `loadWalkSequence` to extract frames 16 to 20 of the `walk_qcif` clip
  and split them into luma plus 4:2:0 chroma, with clear errors for a missing
  file, indices past the end of the clip, and malformed frame lists.
- Added `setupProject` to prepare the path and results folders, so a fresh
  checkout reproduces the same environment every run.
- Added `step02_setup` to confirm the five frames load correctly and export
  preview images for inspection.
- Added `checkProjectCode` to run the MATLAB Code Analyzer across the project
  and report every finding in one pass.
- Added a unit test suite covering the spec constants, frame extraction,
  chroma subsampling, I/P typing, the `.yuv` byte count and plane round-trip,
  and every error path.
- Added a check that `walk_qcif.avi` is present and non-empty, so a checkout
  missing the clip fails with a clear message instead of a downstream error.
- Added a GitHub Actions workflow that runs the MATLAB test suite on every push
  and pull request to `main`, so a regression is caught before it is merged.

### Changed

- Frame structure is now derived from the GOP anchor in `hw3Params` instead of
  being printed as literal text, so the reported `IPPPP` and the typing the
  decoder will use cannot disagree.
- Luma is now taken from `rgb2ycbcr` rather than the red channel that the
  supplementary help document used, so motion estimation runs on real luma.
- The `walk_qcif` clip now lives in `data/` alongside the code that reads it,
  and the loader also accepts the clip at the project root, so older checkouts
  keep working.
- Replaced `aviread`, which no longer exists in MATLAB, with `VideoReader`.
- The `step02_setup` report now derives the search window, macroblock size, and
  SAD cost from `hw3Params` instead of hardcoding them, so the printed spec can
  no longer contradict the constants used by the search.
- Tests now add `src` to the path themselves, so `runtests('tests')` works from
  a fresh session without any manual setup.
- Code Analyzer failures in tests now list every offending file and line in a
  single message, making lint regressions quicker to locate.
