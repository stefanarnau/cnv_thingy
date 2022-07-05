% overwriting S_Tr_3 to be more accurate for visually unspecific (ba)
% condition

% load data from RTbugfix_coded
PATHIN = 'E:\Experiment 1 NEUES DESIGN\Auswertung_EEGLab\LateralTarget\all_ic\'; %! Path, where coded data should end up
PATHOUT = 'E:\Experiment 1 NEUES DESIGN\Auswertung_EEGLab\LateralTarget\all_ic\rev1_newTr3\'; %! Path, where recoded data should end up
SUBJECT = {
    'VP01_j'
    'VP02_j'
    'VP03_j'
    'VP04_j'
    'VP05_j'
    'VP06_j'
    'VP07_j'
    'VP08_j'
    'VP09_j'
    'VP10_j'
    'VP11_j'
    'VP12_j'
    % 'VP13_a'
    % 'VP14_j'
    % 'VP15_j' % raus weil below chance bei au-unspec std
    'VP16_a'
    'VP17_j'
    % 'VP18_j'
    % 'VP19_a'
    'VP20_j'
    'VP21_j'
    'VP22_a'
    % 'VP23_a' %hat nur missing bei deviants, dropout???
    'VP24_a'
    'VP25_a'
    'VP26_j'
    'VP27_a'
    'VP28_a'
    'VP29_j'
    'VP30_j'
    'VP32_a'
    'VP34_j'
    'VP35_j'
    'VP36_a'
    'VP38_a'
    'VP39_a'
    'VP40_a'
    'VP41_a'
    'VP42_j'
    'VP43_a'
    % 'VP45_a' Instruktionen falsch verstanden im Lat. Teil
    'VP46_a'
    'VP47_a'
    'VP48_a'
    'VP49_a'
    'VP50_a'
    };     %hier ggf. weitere VPs einfügen

for subj=1:length(SUBJECT)
    clear ALLEEG;
    clear EEG;
    clear CURRENTSET;
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % start EEGlab using MATLAB
    pop_editoptions('option_storedisk',0); %keep more than 1 dataset at a time
    
    EEG = pop_loadset([SUBJECT{subj} '_cleaned.set'],PATHIN);
    
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
            
            % während in dieser nächsten zeile nach dem combine kein combine auftaucht, schreib informationen rein und gehe danach eine zeile weiter.
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
                        i = nextline; %i macht weiter, wo nextline aufhört
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
    for newlat_i = 1:length(EEG.event)
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
    EEG=pop_saveset(EEG,'filename',[SUBJECT{subj} '_cleaned_newSTr3.set'],'filepath',PATHOUT);
end
    
    
    
