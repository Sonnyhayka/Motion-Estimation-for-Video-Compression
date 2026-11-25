# Motion Estimation for Video Compression

Full-search block-matching motion estimation in MATLAB for CompE 565 Homework 3.

The project takes frames 16 to 20 of the walk_qcif sequence (176x144, YCbCr 4:2:0) and predicts P-frames 17 to 20 from I-frame 16. For each 16x16 macroblock it finds the motion vector with minimum SAD over a 30x30 search window, then builds the residual frames, reconstructs the P-frames, plots the motion vectors and counts the operations used by the search. Motion estimation runs on the luma plane only.

Requires MATLAB R2020a or newer with the Image Processing Toolbox. Run scripts/step11_runFullPipeline.m for the full pipeline and scripts/step13_computeLoad.m for the operation counts. Results are written to results/. Run the tests with runtests('tests').
