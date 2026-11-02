function p = hw3Params()
p.mbSize = 16;
p.searchWindow = 30;
p.searchRadius = (p.searchWindow - p.mbSize) / 2;
p.candidates = (2 * p.searchRadius + 1) ^ 2;

p.frameNumbers = 16:20;
p.iFrameIndex = 1;
p.gopSize = 6;
p.chromaFormat = '4:2:0';

p.gopAnchor = p.frameNumbers(p.iFrameIndex);
p.frameTypes = frameTypesFor(p.frameNumbers, p.gopAnchor, p.gopSize);
p.iFrame = p.frameNumbers(strcmp(p.frameTypes, 'I'));
p.pFrames = p.frameNumbers(strcmp(p.frameTypes, 'P'));

p.addsPerCandidate = 2 * p.mbSize ^ 2 - 1;
end
