function PreprocessMEGDataBeforeEpochs_1Subj(pathstem,rawpathstem,subject,fileName,blocksin,badeeg,badcomp,fs_new)

fprintf('\nPreprocessing subject %s\n',subject);

%% Get current subject path

subjectPath = fullfile(pathstem,subject);
subjectPathRaw = fullfile(rawpathstem,subject);

if ~exist(subjectPath,'dir')
    mkdir(subjectPath);
end

for b=1:length(blocksin)

    %% Convert to SPM
    S = [];
    S.dataset = fullfile(subjectPathRaw,spm_select('list', subjectPathRaw, [fileName '_' blocksin{b} '.bdf']));
    S.outfile = fullfile(subjectPath,['spmeeg_' blocksin{b} '.mat']);
    S.channels = {'EEG' 'EXG1' 'EXG2' 'EXG3' 'EXG4' 'EXG5' 'EXG6' 'STATUS'};
    S.timewin = [];
    S.blocksize = 3276800;
    S.checkboundary = 1;
    S.eventpadding = 0;
    S.saveorigheader = 0;
    S.conditionlabels = {'Undefined'};
    S.inputformat = [];
    S.mode = 'continuous';
    D = spm_eeg_convert(S);
    
    % Set bad EEG channels and save
    chanind_bad = D.indchannel(badeeg{b});
    if ~isempty(chanind_bad)
        D = D.badchannels(chanind_bad,1);
        D.save;
    end
    clear chanind_bad
    
    %% Downsample
    
    S = [];
    S.D = fullfile(subjectPath,D.fname);
    S.fsample_new = fs_new;
    D = spm_eeg_downsample_nt(S);
    
    %% Denoise
    % 1) remove mean from each sensor
    % 2) mark bad channels
    % 3) detrend data to remove slow drifts (similar to highpass filtering)
    % 4) remove components relating to line noise (50Hz) 
    
    S = [];
    S.D = fullfile(subjectPath,D.fname);
    S.modality = {'EEG'};
    D = spm_eeg_denoise_interpolateBadChannels(S);
    es_plotPreprocess_EEG(spm_eeg_load(S.D),D);
    
    %% Reference EEG
    
    inputFile = fullfile(subjectPath,D.fname);
    
    % Load data and find good EEG channels
    D = spm_eeg_load(inputFile);
    if ~isempty(D.badchannels)
        chanind_EEG = setdiff(D.selectchannels('EEG'),D.badchannels);
    else
        chanind_EEG = D.selectchannels('EEG');
    end
    
    % Work out total number of EEG channels and make channel labels for new file
    nChannels_EEG = numel(D.selectchannels('EEG')); % when working out number of channels, include both good and bad
    chanlabels_new = [D.chanlabels(D.selectchannels('EEG')) 'VEOG' 'HEOG'];
    
    % Make montage matrix T
    T = eye(numel(D.selectchannels('EEG'))+2,D.nchannels);
    
    % Rereference to average (being careful to exclude bad EEG channels!)
    for ch=1:length(chanind_EEG)
        T(chanind_EEG(ch),chanind_EEG(ch)) = 1-(1/length(chanind_EEG));
        T(chanind_EEG(ch),setdiff(chanind_EEG,chanind_EEG(ch))) = -1/length(chanind_EEG);
    end
    
%     % Rereference to mastoid
%     chanind_mastoid = D.selectchannels({'EXG5' 'EXG6'});
%     for ch=1:length(chanind_EEG)
%         T(chanind_EEG(ch),chanind_EEG(ch)) = 1;
%         T(chanind_EEG(ch),chanind_mastoid) = [-.5 -.5];
%     end    
    
    % Make VEOG from bipolar channels
    chanind_VEOG = D.selectchannels({'EXG1' 'EXG2'});
    T(nChannels_EEG+1,nChannels_EEG+1) = 0;
    T(nChannels_EEG+1,chanind_VEOG) = [1 -1];
    
    % Make HEOG from bipolar channels
    chanind_HEOG = D.selectchannels({'EXG3' 'EXG4'});
    T(nChannels_EEG+2,nChannels_EEG+2) = 0;
    T(nChannels_EEG+2,chanind_HEOG) = [1 -1];
    
    % We are now ready to use SPM's montage function to do the rereferencing
    S = [];
    S.D = inputFile;
    S.mode = 'write';
    S.blocksize = 655360;
    S.prefix = 'M';
    S.montage.tra = T;
    S.montage.labelorg = D.chanlabels;
    S.montage.labelnew = chanlabels_new;
    S.keepothers = 1;
    S.keepsensors = 1;
    S.updatehistory = 1;
    D = spm_eeg_montage(S);
    clear inputFile T chandind_EEG ch
    es_plotPreprocess_EEG(spm_eeg_load(S.D),D);

    %% Highpass filter
    
    S = [];
    S.D = fullfile(subjectPath,['Mndspmeeg_' blocksin{b} '.mat']);
    S.prefix = 'f';
    S.band = 'high';
    S.freq = .5;
    S.type = 'firws';
    S.save = 1;
    S.updatehistory = 1;
    D = spm_eeg_filter(S);
    es_plotPreprocess_EEG(spm_eeg_load(S.D),D);

    %% ICA to remove components that have high correlation with EOG
    
    S = [];
    S.D{1} = fullfile(subjectPath,D.fname);
    S.modality = {'EEG'};
    S.comp2reject = badcomp{b};
    D = spm_eeg_ica(S);
    es_plotPreprocess_EEG(spm_eeg_load(S.D{1}),D);
    
    %% Downsample further to 64 Hz
    
    S = [];
    S.D = fullfile(subjectPath,D.fname);
    S.fsample_new = 64;
    D = spm_eeg_downsample_nt(S);
    
    %% Plot topos
    es_plotTopo;
    
end

fprintf('\nPreprocessing finished!\n');

end