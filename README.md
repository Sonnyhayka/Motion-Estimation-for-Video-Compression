# CompE 565 HW3: Motion Estimation for Video Compression

Full-search motion estimation on frames 16-20 of `data/walk_qcif.avi`.
Frames are 176x144 pixels, with 16x16 macroblocks and a centered 30x30
search window (radius 7). Frames 17-20 use frame 16 as their I-frame
reference in an IPPPPP structure with GOP size 6. Matching uses minimum
SAD; DCT and quantization are omitted.

Requires MATLAB with Image Processing Toolbox. Run from the project root:

```matlab
step11_runFullPipeline
step13_computeLoad
```

Results are saved under `results/`:

- `figures/`: motion vectors, residuals, targets and reconstructions as PNG and FIG.
- `frames/`: preview images, numeric MAT files, pipeline summary and operation counts.
- `yuv/`: the five source frames as planar 8-bit 4:2:0 YUV.

Motion estimation, residuals and reconstruction cover luma (Y) only.
Cb/Cr are subsampled and exported, without motion compensation or reconstruction.
The pipeline checks exact Y reconstruction for all four P-frames.

Individual steps are available in the root `step*.m` scripts; shared functions
are in `src/`. See [computational load](docs/computational_load.md) for counting conventions.

Run the tests:

```matlab
assertSuccess(runtests('tests'));
```

Assignment sources: [homework](CompE%20565_HW3.pdf),
[sample output](HW_3_SampleOutput.pdf) and
[MATLAB help](MATLAB%20Help_Project%203.pdf).
Where the examples conflict, the homework's 30x30 window, fixed I-frame
reference and `sum(abs(...))` SAD definition take precedence. Search windows
are clipped at frame boundaries.
