# Task 13: Full-search computational load

The search operates on Y only, with 16x16 macroblocks in a 176x144 QCIF
frame: `(176/16)*(144/16) = 99` macroblocks. A centered 30x30 search window
allows displacements from -7 to +7, giving `(30-16+1)^2 = 225` candidates
for an interior macroblock. All four P-frames (17-20) use I-frame 16.

## SAD and minimum-selection model

For each candidate, SAD computes 256 pixel subtractions, 256 absolute values,
and 255 accumulation additions. Thus it requires **511 additions/subtractions
and zero multiplications**. Absolute values are listed separately: their
machine implementation need not use a comparison. If a sign-test model for
`abs` is required, add 256 comparisons per candidate, with any conditional
negations counted separately.

For C candidates, the homework convention counts C comparisons to select the
minimum (equivalent to comparing each SAD against an initial infinity).
A reduction initialized with the first SAD needs exactly C-1 comparisons.
These are alternative conventions, not two costs to add together.

| Scope | MB count | Candidates | Multiplications | Additions/subtractions | Comparisons (homework) |
|---|---:|---:|---:|---:|---:|
| One interior MB | 1 | 225 | 0 | 114,975 | 225 |
| One edge MB, excluding corners | 1 | 120 | 0 | 61,320 | 120 |
| One corner MB | 1 | 64 | 0 | 32,704 | 64 |
| Frame, assuming 225 candidates at every MB | 99 | 22,275 | 0 | 11,382,525 | 22,275 |
| Frame, with implemented border clipping | 99 | 18,271 | 0 | 9,336,481 | 18,271 |

The implemented frame has 63 interior MBs, 32 edge MBs and 4 corner MBs:

```text
C_frame = 63*225 + 32*120 + 4*64 = 18,271
A_frame = 511*C_frame = 9,336,481
```

The clipped frame performs 4,677,376 absolute-value operations. Using C-1
instead of C comparisons per MB gives **18,172** minimum comparisons per
frame (224 per interior MB). The full-window model is a theoretical estimate;
the implementation skips out-of-frame candidates without padding. Clipping
reduces candidate scoring by about 18% for this geometry.

## Additional work in the current implementation

`fullSearchMacroblock` resolves equal SADs by the displacement nearest zero.
It computes `dy.^2 + dx.^2`, masks nonminimum SADs, and takes a second minimum.
This work runs for every MB, including when the best SAD is unique.

For a candidate grid R by K with C = R*K, this adds R+K coordinate squares
(counted as multiplication equivalents), C distance additions, C inequality
comparisons for the mask and C-1 comparisons for the second minimum. Including
the first C-1 SAD minimum comparisons gives:

```text
multiplications = R + K
additions/subtractions = 511*C + C = 512*C
comparisons = (C-1) + C + (C-1) = 3*C - 2
```

| Scope, including tie selection | Multiplication equivalents | Additions/subtractions | Comparisons |
|---|---:|---:|---:|
| One interior MB | 30 | 115,200 | 673 |
| One edge MB | 23 | 61,440 | 358 |
| One corner MB | 16 | 32,768 | 190 |
| One clipped P-frame | 2,690 | 9,354,752 | 54,615 |

These are scalar algorithmic counts, not measured MATLAB instructions or
timings. They exclude index/coordinate construction, loop control, input
validation, memory operations, conversions, residual generation, reconstruction,
loading and plotting. MATLAB may vectorize reductions or implement squares and
absolute values differently. The zero-multiplication result applies to SAD;
the current tie-selection calculation has the additional square operations above.

## Frame and sequence scope

The counts are identical for each searched P-frame because the search scores
every valid candidate without early termination, irrespective of pixel values.
I-frame 16 requires no motion search. Across P-frames 17-20, the clipped SAD
model totals 37,345,924 additions/subtractions and 73,084 homework comparisons.
Including tie selection gives 10,760 multiplication equivalents, 37,419,008
additions/subtractions and 218,460 comparisons across the four P-frames.
Chroma is excluded because this pipeline does not search Cb or Cr.

Run `step13_computeLoad` to reproduce the counts using the input video's
dimensions. It exports `full_search_load_per_mb.csv`,
`full_search_load_per_frame.csv` and `full_search_load.mat` to `results/frames/`.
The reusable `fullSearchLoad([height width], mbSize, radius)` also supports
other whole-block geometries, including radii larger than a block.
