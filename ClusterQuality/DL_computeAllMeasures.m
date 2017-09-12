

function [cgs, uQ, cR, isiV] = DL_computeAllMeasures(baseFilename, shankIndex)

cgs = readKwikCGs(baseFilename, shankIndex);

[cids, uQ, cR] = sqKwik.maskedClusterQuality(baseFilename, shankIndex);

isiV = sqKwik.isiViolations(baseFilename, shankIndex);