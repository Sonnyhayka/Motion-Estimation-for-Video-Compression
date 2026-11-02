# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

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
  chroma subsampling, and every error path.

### Changed

- Luma is now taken from `rgb2ycbcr` rather than the red channel that the
  supplementary help document used, so motion estimation runs on real luma.
- The `walk_qcif` clip now lives in `data/` alongside the code that reads it.
- Replaced `aviread`, which no longer exists in MATLAB, with `VideoReader`.
