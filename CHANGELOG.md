# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- CI now installs Image Processing Toolbox so frame-loading tests can call
  `rgb2ycbcr`, and uses Ubuntu 24.04 to avoid the unsupported Ubuntu 26.04 runner.

### Added

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
