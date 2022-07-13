clear all;

% load data from RTbugfix_coded
PATH_CLEANED = '/mnt/data_fast/CNV_thingy/eeg_cleaned/'; 
PATH_EEGLAB = '/home/plkn/eeglab2022.0/';

% Subject list
% Get vhdr file list
fl = dir([PATH_CLEANED, '*.set']);

% Init eeglab
addpath(PATH_EEGLAB);
eeglab;

% Iterate datasets
elasto_erps = [];
cnv_amps = [];
for s = 1 : length(fl)

    % Load data
    EEG = pop_loadset('filename', fl(s).name, 'filepath', PATH_CLEANED, 'loadmode', 'all');

    % Get id as integer
    id = str2num(fl(s).name(3 : 4));

    % loop through events
    for speak_i = 1 : length(EEG.event)
        EEG.event(speak_i).speak = 'None';
    end
    nextline = 0;
    
    % write Bianca/ Kim info in extra column
    for e = 1 : length(EEG.event)

        % find COMBINE
        if strcmp(EEG.event(e).code, 'Combine') && ~isempty(EEG.event(e + 1).code)

            if nextline < length(EEG.event)
                nextline = e + 1;
            end
            
            % w�hrend in dieser n�chsten zeile nach dem combine kein combine auftaucht, schreib informationen rein und gehe danach eine zeile weiter.
            while ~strcmp(EEG.event(nextline).code, 'Combine')
                
                if strcmp(EEG.event(e).oldtype(end - 5), '1')

                    EEG.event(e).speak = 'Bianca';
                    EEG.event(nextline).speak = 'Bianca';

                elseif strcmp(EEG.event(e).oldtype(end - 5), '2')

                    EEG.event(e).speak = 'Kim';
                    EEG.event(nextline).speak = 'Kim';

                end
                
                % set counter up to continue while loop
                if nextline < length(EEG.event)
                    nextline = nextline + 1;
                else
                    break
                end

                %
                if strcmp(EEG.event(nextline).code, 'Combine')
                    % proceed, until next combine is found, then repeat w new combine
                    if nextline < length(EEG.event)
                        e = nextline; % e macht weiter, wo nextline aufh�rt
                    else
                        break
                    end
                end
                
            end

        end
    end
    
    % new latency S_Tr_3 for AVu trials
    % save old latency
    for savelat_i = 1:length(EEG.event)
        EEG.event(savelat_i).oldlatency =  EEG.event(savelat_i).latency;
    end
    
    % loop through events
    for e = 1 : length(EEG.event)

        % find S_Tr_3
        if strcmp(EEG.event(e).oldtype, 'S_Tr_3')

            % if Avu, take latency from 2 lines before (check if S_Tr_1)
            % check which speaker
            if strcmp(EEG.event(e).Av, 'Avu') && strcmp(EEG.event(e).speak, 'Bianca')

                if strcmp(EEG.event(e - 2).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 67 frames = 1340ms
                    EEG.event(e).latency = EEG.event(e - 2).latency + (1340 / (1000 / EEG.srate));
                elseif strcmp(EEG.event(e - 3).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 67 frames = 1340ms
                    EEG.event(e).latency = EEG.event(e - 3).latency + (1340 / (1000 / EEG.srate));
                elseif strcmp(EEG.event(e - 4).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 67 frames = 1340ms
                    EEG.event(e).latency = EEG.event(e - 4).latency + (1340 / (1000 / EEG.srate));
                else
                    error('did not find Trigger 1 here')                    
                end

            elseif strcmp(EEG.event(e).Av, 'Avu') && strcmp(EEG.event(e).speak, 'Kim')

                if strcmp(EEG.event(e - 2).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 42 frames = 840ms
                    EEG.event(e).latency = EEG.event(e - 2).latency + (840 / (1000 / EEG.srate));
                elseif strcmp(EEG.event(e - 3).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 42 frames = 840ms
                    EEG.event(e).latency = EEG.event(e - 3).latency + (840 / (1000 / EEG.srate));
                elseif strcmp(EEG.event(e - 4).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 42 frames = 840ms
                    EEG.event(e).latency = EEG.event(e - 4).latency + (840 / (1000 / EEG.srate));
                else
                    error('did not find Trigger 1 here')
                end
            end
        end
    end

    % Get SOAs for trials
    trialinfo = [];
    counter = 0;
    old_cnd = '';
    blk = 0;
    for e = 1 : length(EEG.event)

        % If liponset
        if strcmpi(EEG.event(e).type, '3')

            % Loop for tone onset
            f = e;
            while ~strcmpi(EEG.event(f).type, '4')
                f = f + 1;
            end

            % Get latencies
            lat_lip = EEG.event(e).latency;
            lat_tone = EEG.event(f).latency;

            % Save trial info
            if EEG.event(e).trial ==  EEG.event(f).trial

                % Check block
                if ~strcmpi(EEG.event(e).Av, old_cnd)
                    blk = blk + 1;
                    old_cnd = EEG.event(e).Av;
                end

                % Check target position
                if strcmpi(EEG.event(e).tarpos, 'li')
                    tarpos = 0;
                else
                    tarpos = 1;
                end

                % Get conditions
                if strcmpi(EEG.event(e).Av, 'Avk') % both
                    cnd = 1;
                elseif strcmpi(EEG.event(e).Av, 'Auv') % visu
                    cnd = 2;
                elseif strcmpi(EEG.event(e).Av, 'Avu') % audi
                    cnd = 3;
                end

                counter = counter + 1;
                trialinfo(counter, :) = [blk, NaN, tarpos, cnd, str2num(EEG.event(e).seq), lat_lip, lat_tone, floor(mod(lat_lip, EEG.pnts)), floor(mod(lat_tone, EEG.pnts)), lat_lip - lat_tone];
            end
        end
    end

    % Find standard target positions
    for bl = 1 : 6
        tmp = trialinfo(trialinfo(:, 1) == bl, 3);
        if sum(tmp) < (numel(tmp) / 2)
            trialinfo(trialinfo(:, 1) == bl, 2) = 0;
        else
            trialinfo(trialinfo(:, 1) == bl, 2) = 1;
        end
    end

    % Check if number of detected soas matches number of trials in data
    if ~(EEG.trials == size(trialinfo, 1))
        error('\n\nsomething went terribly wrong!!!!!!!!\n\n')
    end

    % Electrodes FC1, FCz, FC2, Fz, Cz as cluster
    front_clust_idx = [19, 63, 20, 23, 16];

    % Drop sus trials
    to_keep = trialinfo(:, 5) <= 1;
    trialinfo = trialinfo(to_keep, :);
    eeg_data = double(squeeze(mean(EEG.data(front_clust_idx, :, to_keep), 1)));

    % Loop trials and elasto
    n_frames = 300;
    bl_length = 400;
    bl_frames = bl_length * (EEG.srate / 1000);
    erp = zeros(EEG.trials, n_frames + bl_frames);
    cnv_amps_subject = [];
    for tr = 1 : size(trialinfo, 1)

        % Get data
        data_original = eeg_data(trialinfo(tr, 8) : trialinfo(tr, 9), tr);

        % Get baseline (100 ms)
        bl_original = eeg_data(trialinfo(tr, 8) - (100 * (EEG.srate / 1000)) : trialinfo(tr, 8) - 1, tr);

        % Get baseline for plotting (400 ms)
        bl_plot = eeg_data(trialinfo(tr, 8) - bl_frames : trialinfo(tr, 8) - 1, tr);

        % Get baseline average
        bl_value = mean(bl_original);

        % Get average of 100 ms before audio onset
        preaudio_value = mean(data_original(end - (100 * (EEG.srate / 1000)) : end));

        % Subtract baseline
        data_original_baselined = data_original - bl_value;
        bl_plot_baseline = bl_plot - bl_value;

        % Resample single trial erp
        erp(tr, :) = [bl_plot_baseline; resample(data_original_baselined, n_frames, length(data_original_baselined))];

        % Save start and end values
        cnv_amps_subject(tr, :) = [bl_value, preaudio_value];

    end

    % Average across conditions
    for cnd = 1 : 3
        for corr = 0 : 1
            elasto_erps(s, cnd, corr + 1, :) = mean(erp(trialinfo(:, 4) == cnd & trialinfo(:, 5) == corr, :), 1);
            cnv_amps(s, cnd, corr + 1, :) = mean(cnv_amps_subject(trialinfo(:, 4) == cnd & trialinfo(:, 5) == corr, :), 1);
        end
    end

end

% Parametrize cnv in time wins
cnv_amplitudes = [];
counter = 0;
for s = 1 : length(fl)

    % Get id
    id = str2num(fl(s).name(3 : 4));

    % Loop conditions
    for cnd = 1 : 3
        for corr = 0 : 1
            for win = 1 : 2

                counter = counter + 1;

                % Mena amplitudes
                %cnv_amp = mean(squeeze(elasto_erps(s, cnd, corr + 1, win : win + 59)));

                % Save to matrix
                %cnv_amplitudes(counter, :) = [id, cnd, corr, ceil(win / 60), cnv_amp];

                cnv_amplitudes(counter, :) = [id, cnd, corr, win, cnv_amps(s, cnd, corr + 1, win)];

            end
        end
    end
end

% Save
dlmwrite([PATH_CLEANED, 'cnv_amplitudes.csv'], cnv_amplitudes);

figure()
subplot(2, 2, 1)
pd = squeeze(mean(elasto_erps(:, 1, 1, :), 1))
plot(pd, 'r', 'LineWidth', 2)
hold on
pd = squeeze(mean(elasto_erps(:, 2, 1, :), 1))
plot(pd, 'g', 'LineWidth', 2)
pd = squeeze(mean(elasto_erps(:, 3, 1, :), 1))
plot(pd, 'k', 'LineWidth', 2)
title('standard')
xline(bl_frames)

subplot(2, 2, 2)
pd = squeeze(mean(elasto_erps(:, 1, 2, :), 1))
plot(pd, 'r', 'LineWidth', 2)
hold on
pd = squeeze(mean(elasto_erps(:, 2, 2, :), 1))
plot(pd, 'g', 'LineWidth', 2)
pd = squeeze(mean(elasto_erps(:, 3, 2, :), 1))
plot(pd, 'k', 'LineWidth', 2)
legend({'both', 'visu', 'audi'})
title('deviant')
xline(bl_frames)

subplot(2, 2, 3)
pd = squeeze(mean(cnv_amps(:, 1, 1, :), 1))
plot(pd, 'r', 'LineWidth', 2)
hold on
pd = squeeze(mean(cnv_amps(:, 2, 1, :), 1))
plot(pd, 'g', 'LineWidth', 2)
pd = squeeze(mean(cnv_amps(:, 3, 1, :), 1))
plot(pd, 'k', 'LineWidth', 2)
title('standard')
    
subplot(2, 2, 4)
pd = squeeze(mean(cnv_amps(:, 1, 2, :), 1))
plot(pd, 'r', 'LineWidth', 2)
hold on
pd = squeeze(mean(cnv_amps(:, 2, 2, :), 1))
plot(pd, 'g', 'LineWidth', 2)
pd = squeeze(mean(cnv_amps(:, 3, 2, :), 1))
plot(pd, 'k', 'LineWidth', 2)
legend({'both', 'visu', 'audi'})
title('deviant')
    
    

figure()
subplot(2, 2, 1)
pd = squeeze(mean(elasto_erps(:, 1, 1, :), 1))
plot(pd, 'k', 'LineWidth', 2)
hold on
pd = squeeze(mean(elasto_erps(:, 1, 2, :), 1))
plot(pd, 'm', 'LineWidth', 2)
title('both')
xline(bl_frames)

subplot(2, 2, 2)
pd = squeeze(mean(elasto_erps(:, 2, 1, :), 1))
plot(pd, 'k', 'LineWidth', 2)
hold on
pd = squeeze(mean(elasto_erps(:, 2, 2, :), 1))
plot(pd, 'm', 'LineWidth', 2)
title('visu')
legend({'std', 'dev'})
xline(bl_frames)

subplot(2, 2, 3)
pd = squeeze(mean(elasto_erps(:, 3, 1, :), 1))
plot(pd, 'k', 'LineWidth', 2)
hold on
pd = squeeze(mean(elasto_erps(:, 3, 2, :), 1))
plot(pd, 'm', 'LineWidth', 2)
title('audi')
xline(bl_frames)
