# Motion Estimation for Video Compression

Full-search block-matching motion estimation in MATLAB, written for CompE 565 Homework 3.

The project uses frames 16 to 20 of the QCIF `walk_qcif` sequence (176x144, 4:2:0). Frame 16 is the I-frame, and P-frames 17 to 20 are all predicted from it (IPPPPP, GOP 6).

## What it does

- Extracts frames 16 to 20 and converts them to YCbCr 4:2:0.
- Finds a motion vector for every 16x16 macroblock with full search over a 30x30 window, using minimum SAD.
- Builds the residual (difference) frame for each P-frame and decodes the reconstructed frame.
- Plots the motion vectors with `quiver`.
- Counts the multiplications, additions and comparisons of the search.

Motion estimation runs on the luma (Y) plane. DCT and quantization are not part of this assignment.

## Requirements

MATLAB R2020a or newer with the Image Processing Toolbox.

## How to run

Open MATLAB in the project root and run:

```matlab
run(fullfile('scripts', 'step11_runFullPipeline.m'))
run(fullfile('scripts', 'step13_computeLoad.m'))
```

The first script runs the whole pipeline for P-frames 17 to 20. The second prints and saves the operation counts. The other scripts in `scripts/` run single steps of the pipeline.

Outputs are written to `results/`:

- `results/figures/`: motion vectors, residual, target and reconstructed frames.
- `results/frames/`: frame images, `.mat` data and `.csv` tables.
- `results/yuv/`: frames 16 to 20 as planar 8-bit YUV 4:2:0.

## Run the tests

```matlab
assertSuccess(runtests('tests'));
```

## Project layout

- `src/`: functions for loading frames, full search, residuals, reconstruction and operation counts.
- `scripts/`: scripts that run the pipeline step by step.
- `tests/`: unit tests.
- `data/`: the input video `walk_qcif.avi`.
- `docs/`: notes on the computational load.
- `results/`: generated output (not tracked by git).
