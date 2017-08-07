reboot;
addpath(genpath('S:\Vigi\Matlab\OtherClustering\KiloSort'))
addpath(genpath('Extra'))
addpath Fcns
gpuDevice(1);
%% Run the core
%Here define the file that you want
id='MargotRA.m';run(fullfile('Extra/configFiles/',id));
[rez, DATA, uproj] = preprocessData(ops);
rez=fitTemplates(rez, DATA, uproj); 
rez=fullMPMU(rez,DATA);
% rez = merge_posthoc2(rez);%would be nice, but screws up clustering later.
% maybe do this for baseline testing??
rezToPhyV(rez,ops);
%% Send output to phy
% system(['activate phy & cd ' fullfile(ops.root,'batches') ' & phy template-gui params.py'])
% ['activate phy & cd ' fullfile(ops.root,'batches') ' & phy template-gui params.py']