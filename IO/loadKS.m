function clusters = loadKS(folder,version,keep,fs)
% Input
%       folder: location of your data
%       version: dev or release. This will tell the program where to look
%       for the data

% Output: clusters: a struct with all the information you need

clusters=struct('clustID',[],'group',{},'spikeTimes',[],'shank',[],'maxChannel',[],'coordinates',[],'FR',[]);

%Load in from KiloSort
if strcmp(version,'release')
    load(fullfile(folder,'batches\KS_Output.mat'));
    spike_clust=readNPY(fullfile(folder,'batches\spike_clusters.npy'));
    clust_group=importdata(fullfile(folder,'batches\cluster_groups.csv'));
elseif strcmp(version,'dev')
    load(fullfile(folder,'KS_Output.mat'));
    spike_clust=readNPY(fullfile(folder,'spike_clusters.npy'));
    clust_group=importdata(fullfile(folder,'cluster_group.tsv'));
end
% get intan data
if isempty(fs)
    try
        frequency_parameters = read_Intan_RHD2000_frequency_parameters([folder,'info.rhd']);
        fs=frequency_parameters .amplifier_sample_rate;
    catch
        error('Cant find the info file, put it in folder or give me your fs')
    end
end
    
%Get Channel Map
load(ops.chanMap,'connected', 'xcoords', 'ycoords','kcoords','chanMap');
xcoords=xcoords(connected);
ycoords=ycoords(connected);
kcoords=kcoords(connected);
chanMap=chanMap(connected);

clustGroup=cell(length(clust_group) - 1, 1);
clustName=nan(length(clust_group) - 1, 1);
for i = 1:length(clust_group) - 1
    line = textscan(clust_group{i+1},'%d %s');
    clustGroup(i) = line{2};%label assigned to the cluster
    clustName(i) = line{1};%cluster id 
end

keptClusters= find(ismember(clustGroup,keep));%only take good
clusters(length(keptClusters)).clustID=[];%inialize it so that it goes faster
for i = 1:length(keptClusters)
    spikeI= spike_clust==clustName(keptClusters(i));%get indices of spike times
    spikeT = rez.st3(spikeI,1)/fs;
    %Find (channel) location of max waveform
    origC = unique(rez.st3(spikeI,2));
    meanTemplate = mean(rez.Wraw(:,:,origC),3);    
    [~,KS_channel] = max(mean(abs(meanTemplate ),2));
    clusters(i).group=clustGroup{keptClusters(i)};
    clusters(i).clustID=clustName(keptClusters(i));
    clusters(i).spikeTimes = unique(spikeT);%THROW A UNIQUE ON IT!!! kilosort will sometoimes double assign times
    clusters(i).maxChannel = chanMap(KS_channel) - 1;
    clusters(i).coordinates = [xcoords(KS_channel) ycoords(KS_channel)];
    clusters(i).shank=kcoords(KS_channel);
    clusters(i).FR=sum(spikeI)/range(spikeT);
end
figure(1);clf;
histogram([clusters.FR])
xlabel('FR (Hz)')
ylabel('# of neurons')
title('Distribution of Firing Rates')
for i=1:length(keep)
    disp(['# of ' keep{i} ': ' num2str(sum(strcmp({clusters.group},keep{i})))])
    type(strcmp({clusters.group},keep{i}))=i;
end
figure(2)
histogram(type)
set(gca,'xtick',1:i)
set(gca,'xticklabel',keep)
ylabel('# of neurons')