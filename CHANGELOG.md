# Changelog

## [Unreleased]

### Added

- Frame loading for frames 16 to 20 of walk_qcif with YCbCr 4:2:0 conversion.
- I/P frame typing from the GOP anchor and size.
- Planar 4:2:0 YUV export.
- Macroblock and search window extraction.
- Full-search motion estimation per macroblock and per frame using minimum SAD.
- Signed residual frames and P-frame reconstruction.
- Motion vector plots and the full pipeline script for P-frames 17 to 20.
- Computational load counts per macroblock and per frame.
- Unit tests, Code Analyzer check and GitHub Actions CI.

### Changed

- Scripts moved into scripts/ and the input video into data/.
- Luma taken from rgb2ycbcr instead of the red channel.
- VideoReader used in place of the removed aviread.

### Fixed

- CI installs the Image Processing Toolbox and runs on Ubuntu 24.04.
- Exported figures keep black axis labels on a white background.

### Removed

- Course PDFs and notes.
