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
for s = 1 : length(fl)

    % Load data
    EEG = pop_loadset('filename', fl(s).name, 'filepath', PATH_CLEANED, 'loadmode', 'all');

    % Get id as integer
    id = str2num(fl(s).name(3 : 4));
    
    %loop through events
    for speak_i = 1:length(EEG.event)
        EEG.event(speak_i).speak = 'None';
    end
    nextline = 0;
    
    % write Bianca/ Kim info in extra column
    for i = 1:length(EEG.event)
        % find COMBINE
        if strcmp(EEG.event(i).code,'Combine') && ~isempty(EEG.event(i+1).code)
            if nextline < length(EEG.event)
                nextline = i + 1;
            end
            
            % w�hrend in dieser n�chsten zeile nach dem combine kein combine auftaucht, schreib informationen rein und gehe danach eine zeile weiter.
            while ~strcmp(EEG.event(nextline).code,'Combine')
                
                if strcmp(EEG.event(i).oldtype(end-5), '1')
                    EEG.event(i).speak = 'Bianca';
                    EEG.event(nextline).speak = 'Bianca';
                elseif strcmp(EEG.event(i).oldtype(end-5), '2')
                    EEG.event(i).speak = 'Kim';
                    EEG.event(nextline).speak = 'Kim';
                end
                
                % set counter up to continue while loop
                if nextline < length(EEG.event)
                    nextline = nextline + 1;
                else
                    break
                end
                %
                if strcmp(EEG.event(nextline).code,'Combine')
                    % proceed, until next combine is found, then repeat w new combine
                    if nextline < length(EEG.event)
                        i = nextline; %i macht weiter, wo nextline aufh�rt
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
    for newlat_i = 1 : length(EEG.event)

        % find S_Tr_3
        if strcmp(EEG.event(newlat_i).oldtype, 'S_Tr_3')

            % if Avu, take latency from 2 lines before (check if S_Tr_1)
            % check which speaker
            if strcmp(EEG.event(newlat_i).Av, 'Avu') && strcmp(EEG.event(newlat_i).speak, 'Bianca')

                if strcmp(EEG.event(newlat_i-2).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 67 frames = 1340ms
                    EEG.event(newlat_i).latency = EEG.event(newlat_i-2).latency + 1340;
                elseif strcmp(EEG.event(newlat_i-3).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 67 frames = 1340ms
                    EEG.event(newlat_i).latency = EEG.event(newlat_i-3).latency + 1340;
                elseif strcmp(EEG.event(newlat_i-4).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 67 frames = 1340ms
                    EEG.event(newlat_i).latency = EEG.event(newlat_i-4).latency + 1340;
                else
                    error_msg(subj,newlat_i) = 1
                    error('did not find Trigger 1 here')                    
                end

            elseif strcmp(EEG.event(newlat_i).Av, 'Avu') && strcmp(EEG.event(newlat_i).speak, 'Kim')

                if strcmp(EEG.event(newlat_i-2).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 42 frames = 840ms
                    EEG.event(newlat_i).latency = EEG.event(newlat_i-2).latency + 840;
                elseif strcmp(EEG.event(newlat_i-3).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 42 frames = 840ms
                    EEG.event(newlat_i).latency = EEG.event(newlat_i-3).latency + 840;
                elseif strcmp(EEG.event(newlat_i-4).oldtype,  'S_Tr_1')
                    % overwrite latency
                    % onset lip movement: 42 frames = 840ms
                    EEG.event(newlat_i).latency = EEG.event(newlat_i-4).latency + 840;
                else
                    error_msg(subj,newlat_i) = 1
                    error('did not find Trigger 1 here')
                end
            end
        end
    end

    lat_lip = [];
    lat_stim = [];
    for e = 1 : length(EEG.event)

        if strcmpi(EEG.event(e).type, '3')
            lat_lip(end + 1) = EEG.event(e).latency;
        end

        if strcmpi(EEG.event(e).code, 'Combine')
            lat_stim(end + 1) = EEG.event(e).latency;
        end

    end

    aa=bb
    
    
    
    
    %EEG=pop_saveset(EEG,'filename',[SUBJECT{subj} '_cleaned_newSTr3.set'],'filepath',PATHOUT);
end
    
    
    
