function p = hw3Params()
%HW3PARAMS Parameters fixed by the CompE 565 HW3 assignment PDF.
%
% Single source of truth for the numbers quoted in the assignment so the
% search code never silently drifts from the spec.

p.mbSize = 16; % macroblock 16x16
p.searchWindow = 30; % "search window of 30x30 pixels"
p.searchRadius = (p.searchWindow - p.mbSize) / 2; % w = 7
p.candidates = (2 * p.searchRadius + 1) ^ 2; % (2w+1)^2 = 225

p.frameNumbers = 16:20; % "from frame #16 to frame #20"
p.iFrameIndex = 1; % frame 16 is the I frame
p.gopSize = 6; % "GOP size of 6 frames"
p.chromaFormat = '4:2:0';

% "SAD requires 2x256 - 1 = 511 additions/subtractions"
p.addsPerCandidate = 2 * p.mbSize ^ 2 - 1;
end
