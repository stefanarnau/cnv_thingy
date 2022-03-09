

clear all;

% Output paths
PATH_PLOT = '/mnt/data_fast/CNV_thingy/plots/';
PATH_VEUSZ = '/mnt/data_fast/CNV_thingy/veusz/';
PATH_EEGLAB = '/home/plkn/eeglab2021.1/';

% Init fieldtrip
ft_path = '/home/plkn/fieldtrip-master/';
addpath(ft_path);
ft_defaults;

% Init eeglab
addpath(PATH_EEGLAB);
eeglab;

% Load data file
cnv_file = '/mnt/data_fast/CNV_thingy/CNV_data.mat';
load(cnv_file);

% The order of things
new_order_labels = {...
'Fp1',...
'Fp2',...
'AF7',...
'AF3',...
'AF4',...
'AF8',...
'F9',...
'F5',...
'F3',...
'F1',...
'Fz',...
'F2',...
'F4',...
'F6',...
'F10',...
'FT9',...
'FT7',...
'FC3',...
'FC1',...
'FCz',...
'FC2',...
'FC4',...
'FT8',...
'FT10',...
'T7',...
'C5',...
'C3',...
'C1',...
'Cz',...
'C2',...
'C4',...
'C6',...
'T8',...
'TP9',...
'TP7',...
'CP3',...
'CP1',...
'CPz',...
'CP2',...
'CP4',...
'TP8',...
'TP10',...
'P9',...
'P7',...
'P5',...
'P3',...
'P1',...
'Pz',...
'P2',...
'P4',...
'P6',...
'P8',...
'P10',...
'PO9',...
'PO7',...
'PO3',...
'POz',...
'PO4',...
'PO8',...
'PO10',...
'O1',...
'Oz',...
'O2',...
};

% Get original chanloc labels
chanlocs_labels = {};
for ch = 1 : length(chanlocs)
    chanlocs_labels{end + 1} = chanlocs(ch).labels;
end

% Get new order indices
new_order_idx = [];
for ch = 1 : length(chanlocs)
    new_order_idx(end + 1) = find(strcmpi(new_order_labels{ch}, chanlocs_labels));
end

% Install new order
erps = CNV_permute(:, :, new_order_idx, :); % CNV_permute has dims: subject x condition x channel x time
chanlocs = chanlocs(new_order_idx);

% Restructure coordinates
chanlabs = {};
coords = [];
for c = 1 : numel(chanlocs)
    chanlabs{c} = chanlocs(c).labels;
    coords(c, :) = [chanlocs(c).X, chanlocs(c).Y, chanlocs(c).Z];
end

% A sensor struct
sensors = struct();
sensors.label = chanlabs;
sensors.chanpos = coords;
sensors.elecpos = coords;

% Prepare neighbor struct
cfg                 = [];
cfg.elec            = sensors;
cfg.feedback        = 'no';
cfg.method          = 'triangulation'; 
neighbours          = ft_prepare_neighbours(cfg);

% A template for GA structs
cfg=[];
cfg.keepindividual = 'yes';
ga_template = [];
ga_template.dimord = 'chan_time';
ga_template.label = chanlabs;
ga_template.time = [-1800 : 2 : 0];

% Conditions:
% 1: AUV_std - visually relevant - standard
% 2: AUV_dev - visually relevant - deviant
% 3: AVK_std - both relevant - standard
% 4: AVK_dev - both relevant - deviant
% 5: AVU_std - auditory relevant - standard
% 6: AVU_dev - auditory relevant - deviant 

% Visu relevant
GA = {};
for s = 1 : size(erps, 1)
    chan_time_data = squeeze(mean(squeeze(erps(s, [1, 2], :, :)), 1));
    ga_template.avg = chan_time_data;
    GA{s} = ga_template;
end 
GA_visu_std_dev = ft_timelockgrandaverage(cfg, GA{1, :});

% Both relevant
GA = {};
for s = 1 : size(erps, 1)
    chan_time_data = squeeze(mean(squeeze(erps(s, [3, 4], :, :)), 1));
    ga_template.avg = chan_time_data;
    GA{s} = ga_template;
end 
GA_both_std_dev = ft_timelockgrandaverage(cfg, GA{1, :});

% Audi relevant
GA = {};
for s = 1 : size(erps, 1)
    chan_time_data = squeeze(mean(squeeze(erps(s, [5, 6], :, :)), 1));
    ga_template.avg = chan_time_data;
    GA{s} = ga_template;
end 
GA_audi_std_dev = ft_timelockgrandaverage(cfg, GA{1, :});

% Testparams
testalpha  = 0.01;
voxelalpha  = 0.01;
nperm = 1000;

% Set config
cfg = [];
cfg.tail             = 1;
cfg.statistic        = 'depsamplesFmultivariate';
cfg.alpha            = testalpha;
cfg.neighbours       = neighbours;
cfg.minnbchan        = 2;
cfg.method           = 'montecarlo';
cfg.correctm         = 'cluster';
cfg.clustertail      = 1;
cfg.clusteralpha     = voxelalpha;
cfg.clusterstatistic = 'maxsum';
cfg.numrandomization = nperm;
cfg.computecritval   = 'yes'; 
cfg.ivar             = 1;
cfg.uvar             = 2;

% Set up design
n_subjects = size(erps, 1);
design = zeros(2, n_subjects * 3);
design(1, :) = [ones(1, n_subjects), 2 * ones(1, n_subjects), 3 * ones(1, n_subjects)];
design(2, :) = [1 : n_subjects, 1 : n_subjects, 1 : n_subjects];
cfg.design           = design;

% The test
[stat] = ft_timelockstatistics(cfg, GA_visu_std_dev, GA_both_std_dev, GA_audi_std_dev);

% Save averages
dlmwrite([PATH_VEUSZ, 'visu_average.csv'], squeeze(mean(GA_visu_std_dev.individual, 1)));
dlmwrite([PATH_VEUSZ, 'both_average.csv'], squeeze(mean(GA_both_std_dev.individual, 1)));
dlmwrite([PATH_VEUSZ, 'audi_average.csv'], squeeze(mean(GA_audi_std_dev.individual, 1)));

% Calculate effect sizes
n_chans = numel(chanlocs);
apes = [];
df_effect = 2;
for ch = 1 : n_chans
    petasq = (squeeze(stat.stat(ch, :)) * df_effect) ./ ((squeeze(stat.stat(ch, :)) * df_effect) + (n_subjects - 1));
    apes(ch, :) = petasq - (1 - petasq) .* (df_effect / (n_subjects - 1));
end

% Save effect sizes
dlmwrite([PATH_VEUSZ, 'effect_sizes.csv'], apes);

% Plot effect size topos
cmap = 'jet';        
clim = [-0.75, 0.75];  
for t = -1500 : 300 : 0
    figure('Visible', 'off'); clf;
    [tidx_val, tidx_pos] = min(abs(stat.time - t));
    pd = apes(:, tidx_pos);
    topoplot(pd, chanlocs, 'plotrad', 0.7, 'intrad', 0.7, 'intsquare', 'on', 'conv', 'off', 'electrodes', 'on');
    colormap(cmap);
    caxis(clim);
    saveas(gcf, [PATH_VEUSZ, 'topo_', num2str(t), 'ms', '.png']);
end

% Set cluster threshold
sig = find([stat.posclusters.prob] <= 0.01);

% Get significant clusters
for cl = 1 : numel(sig)

    % Get indices of cluster 
    idx = stat.posclusterslabelmat == sig(cl);

    % Get pval of cluster
    pval = round(stat.posclusters(sig(cl)).prob, 3);

    % Save cluster contour
    dlmwrite([PATH_VEUSZ, 'cluster_', num2str(cl), '_contour.csv'], idx);

end

% Get age indices
idx_age = zeros(1, length(subject_idx));
for s = 1 : length(subject_idx)
    if strcmpi(subject_idx{s}(end) , 'j')
        idx_age(s) = 1;
    elseif strcmpi(subject_idx{s}(end) , 'a')
        idx_age(s) = 2;
    end
end

% Select channels
channel_idx = [];
channels = {'Fz', 'FC1', 'FCz', 'FC2', 'Cz'};
for ch = 1 : length(channels)
    channel_idx(end + 1) = find(strcmp({chanlocs.labels}, channels{ch}));
end

% Calculate erps
erp_y_visu_std = squeeze(mean(erps(idx_age == 1, 1, channel_idx, :), [1, 2, 3]));
erp_y_visu_dev = squeeze(mean(erps(idx_age == 1, 2, channel_idx, :), [1, 2, 3]));
erp_y_both_std = squeeze(mean(erps(idx_age == 1, 3, channel_idx, :), [1, 2, 3]));
erp_y_both_dev = squeeze(mean(erps(idx_age == 1, 4, channel_idx, :), [1, 2, 3]));
erp_y_audi_std = squeeze(mean(erps(idx_age == 1, 5, channel_idx, :), [1, 2, 3]));
erp_y_audi_dev = squeeze(mean(erps(idx_age == 1, 6, channel_idx, :), [1, 2, 3]));
erp_o_visu_std = squeeze(mean(erps(idx_age == 2, 1, channel_idx, :), [1, 2, 3]));
erp_o_visu_dev = squeeze(mean(erps(idx_age == 2, 2, channel_idx, :), [1, 2, 3]));
erp_o_both_std = squeeze(mean(erps(idx_age == 2, 3, channel_idx, :), [1, 2, 3]));
erp_o_both_dev = squeeze(mean(erps(idx_age == 2, 4, channel_idx, :), [1, 2, 3]));
erp_o_audi_std = squeeze(mean(erps(idx_age == 2, 5, channel_idx, :), [1, 2, 3]));
erp_o_audi_dev = squeeze(mean(erps(idx_age == 2, 6, channel_idx, :), [1, 2, 3]));

% Save erps
dlmwrite([PATH_VEUSZ, 'erp_y_visu_std.csv'], erp_y_visu_std);
dlmwrite([PATH_VEUSZ, 'erp_y_visu_dev.csv'], erp_y_visu_dev);
dlmwrite([PATH_VEUSZ, 'erp_y_both_std.csv'], erp_y_both_std);
dlmwrite([PATH_VEUSZ, 'erp_y_both_dev.csv'], erp_y_both_dev);
dlmwrite([PATH_VEUSZ, 'erp_y_audi_std.csv'], erp_y_audi_std);
dlmwrite([PATH_VEUSZ, 'erp_y_audi_dev.csv'], erp_y_audi_dev);
dlmwrite([PATH_VEUSZ, 'erp_o_visu_std.csv'], erp_o_visu_std);
dlmwrite([PATH_VEUSZ, 'erp_o_visu_dev.csv'], erp_o_visu_dev);
dlmwrite([PATH_VEUSZ, 'erp_o_both_std.csv'], erp_o_both_std);
dlmwrite([PATH_VEUSZ, 'erp_o_both_dev.csv'], erp_o_both_dev);
dlmwrite([PATH_VEUSZ, 'erp_o_audi_std.csv'], erp_o_audi_std);
dlmwrite([PATH_VEUSZ, 'erp_o_audi_dev.csv'], erp_o_audi_dev);

% Save time
dlmwrite([PATH_VEUSZ, 'erp_time.csv'], stat.time);