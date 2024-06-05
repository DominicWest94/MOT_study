%% Set-up variables (e.g. subject IDs and file paths)

stimulus_folder  = '../stimuli';
analysis_folder = fullfile(pathstem,'TRF','env_encoding');
fs_new = 64;

% Model hyperparameters
tmin = -100;
tmax = 300;
lambdas = 10.^(-3:6);

%% Compute broadband envelopes for all chapters
audio_list = dir(fullfile(stimulus_folder,'audio_*.wav'));
stim = {};
for a=1:numel(audio_list)-1 % only do chapters 1-6, 7 is used for practice block in experiment
    % Get audio envelope
    audio_file = audio_list(a).name;
    [x, fs] = audioread(fullfile(stimulus_folder,audio_file));
    audio_raw{a} = x; % for later plotting
    env = mTRFenvelope(x,fs,fs_new);
    
    % Normalise data
    env = zscore(env,0,1);
    stim{a} = env;
end

%% Loop over subjects and chapters

for s=1:numel(SID)
    
    lambda = [];
    all_audio_stim = [];
    all_visualLow_stim = [];
    all_visualHigh_stim = [];
    all_audio_resp = [];
    all_visualLow_resp = [];
    all_visualHigh_resp = [];
        
    for b=1:numel(blocksout{s})
        
        subject2process = SID{s};
        blocks2process = blocksout{s};
        
        %% Prepare response data and stim data
        
        % Load Response Data
        filename = fullfile(pathstem,subject2process,sprintf('dicafMndspmeeg_%d.mat',b));  
        D = spm_eeg_load(filename);        
        resp = D(:,:); % data is a matrix of N channels x N timepoints
        
        % Get indices of EEG channels
        indChannels = D.selectchannels('EEG');
        
        % Get indices of EOG channels
        indChannelsEOG = D.selectchannels('EOG');
        
        % Reshape from N channels x N timepoints to N timepoints x N channels
        resp = permute(resp,[2 1]);
        
        % Resample if necessary
        if D.fsample~=fs_new
            resp = nt_resample(resp,fs_new,D.fsample);
        end
        
        % Get times of events
        events = D.events;
        indTriggers = find(ismember({events(:).type},'STATUS'));
        triggerVals = [events(indTriggers).value];
        triggerTimes = [events(indTriggers).time];
        
        % Extract stim info from triggers
        chapter = (triggerVals(3)-125)/10; % equation to convert trigger value to chapter number
        current_stim = stim{1,(chapter)}; % load broadband envelope for current chapter
        if triggerVals(2) == 95
            condition = 'Audio';
        else
            condition = 'Visual';
        end
        if triggerVals(4) == 125
            MOT_load = 'Low';
        else
            MOT_load = 'High';
        end

        % Triggers in seconds
        speechOnset = triggerTimes(triggerVals==195);
        MOTOnset = triggerTimes(triggerVals==235);
        MOTOffset = triggerTimes(triggerVals==245);

        % Convert to samples
        speechOnset = round(speechOnset*fs_new);
        MOTOnset = round(MOTOnset*fs_new);
        MOTOffset = round(MOTOffset*fs_new);

        % Select only EEG electrodes
        resp = resp(:,indChannels);
        
        % Normalise data
        resp = zscore(resp,0,1);
        
        % Pad stim data with zeros at start to align with EEG trigger values
        % (due to gap between EEG start and speech onset)
        current_stim = [zeros(speechOnset-1,2); current_stim];
        
        %% Epoch data
        stim_epoch = {};
        resp_epoch = {};
        bad_epoch = [];
    
        epochDur = 10; % in seconds
        epochDur = floor(epochDur*fs_new); % convert to samples
        
        % Epoch trials here
        for e=1:length(MOTOnset)
            resp_epoch = [resp_epoch; resp(MOTOnset(e):MOTOnset(e)+epochDur-1,:)];
            stim_epoch = [stim_epoch; current_stim(MOTOnset(e):MOTOnset(e)+epochDur-1,:)];

            % Artefact detection for current trial
            thresh = 2;
            prop = .1;
            summary = mean(abs(resp(MOTOnset(e):MOTOnset(e)+epochDur-1,:)),2); % take absolute and then mean across channels

            bad_samples = summary>thresh; % threshold data
            if (numel(find(bad_samples))/numel(bad_samples))>prop % if number of thresholded datapoints exceed specified proportion, will mark as bad
                bad_epoch = [bad_epoch; 1];
            else
                bad_epoch = [bad_epoch; 0];
            end 
        end
        
        % How many epochs before artefact rejection
        nEpochsAll = size(resp_epoch,1);

        % Artefact rejection
        if nEpochsAll > 10
            ind_good = find(~bad_epoch);
            resp_epoch = resp_epoch(ind_good);
            stim_epoch = stim_epoch(ind_good);
        end

        % How many epochs after artefact rejection
        nEpochsGood = size(resp_epoch,1);
        fprintf('\nRejecting %d out of %d trials\n\n',nEpochsAll-nEpochsGood,nEpochsAll);
        
        % Gather all epochs by condition, across blocks
        if strcmp(condition,'Audio') == 1
            all_audio_stim = [all_audio_stim; stim_epoch];
            all_audio_resp = [all_audio_resp; resp_epoch];

        else
            if strcmp(MOT_load,'Low') == 1
                all_visualLow_stim = [all_visualLow_stim; stim_epoch];
                all_visualLow_resp = [all_visualLow_resp; resp_epoch];

            else
                all_visualHigh_stim = [all_visualHigh_stim; stim_epoch];
                all_visualHigh_resp = [all_visualHigh_resp; resp_epoch];
            end
        end
    end
        
    %% Compute model across conditions
    % Run cross-validation for each condition (rather than per block, to
    % prevent over-fitting)
    cv_audio = mTRFcrossval(all_audio_stim,all_audio_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);
    cv_visualLow = mTRFcrossval(all_visualLow_stim,all_visualLow_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);
    cv_visualHigh = mTRFcrossval(all_visualHigh_stim,all_visualHigh_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);

    % Find optimal regularization value for audio (after averaging over folds and channels if present)
    [rmax_audio,idx_audio] = max(squeeze(mean(mean(cv_audio.r,3),1)));
    lambda = [lambda; lambdas(idx_audio)]; % save optimal lambda for condition
    
    % Find optimal regularization value for visual low load(after averaging over folds and channels if present)
    [rmax_visualLow,idx_visualLow] = max(squeeze(mean(mean(cv_visualLow.r,3),1)));
    lambda = [lambda; lambdas(idx_visualLow)];
    
    % Find optimal regularization value for visual high load (after averaging over folds and channels if present)
    [rmax_visualHigh,idx_visualHigh] = max(squeeze(mean(mean(cv_visualHigh.r,3),1)));
    lambda = [lambda; lambdas(idx_visualHigh)];
    
    subj_lambda = mode(lambda); % optimal lambda for subject across conditions
    
    % Audio model using participant lambda
    average_audio_model = mTRFtrain(all_audio_stim,all_audio_resp,fs_new,1,tmin,tmax,subj_lambda,'zeropad',0);
    
    % Visual Low model using participant lambda
    average_visualLow_model = mTRFtrain(all_visualLow_stim,all_visualLow_resp,fs_new,1,tmin,tmax,subj_lambda,'zeropad',0);
    
    % Visual High model using participant lambda
    average_visualHigh_model = mTRFtrain(all_visualHigh_stim,all_visualHigh_resp,fs_new,1,tmin,tmax,subj_lambda,'zeropad',0);
    
    %% Plot model accuracies
    % Plot audio and envelope
%     figure(100);
%     subplot(3,1,1); plot([0:size(audio_raw{chapter},1)-1]/fs,audio_raw{chapter}); xlabel('Time (s)'); title('Original Speech Signal');
%     subplot(3,1,2); plot([0:size(current_stim,1)-1]/fs_new,current_stim); xlabel('Time (s)'); title('Broadband Envelope');
%     subplot(3,1,3); plot([0:size(resp,1)-1]/fs_new,resp); xlabel('Time (s)'); title('EEG');
%     saveas(100,fullfile(analysis_folder,['regressors_' subject2process '_b' blocks2process{b} '_chapter' num2str(chapter) '_' condition '_' MOT_load '.png']));

    % Plot correlation across lambdas for audio condition
    figure(200);
    data2plot = mean(cv_audio.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy across folds for Audio condition');
    grid on;
    
    % Plot correlation across lambdas for visual low condition
    figure(300);
    data2plot = mean(cv_visualLow.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy across folds for Visual (Low Load) condition');
    grid on;
    
    % Plot correlation across lambdas for visual high condition
    figure(400);
    data2plot = mean(cv_visualHigh.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy across folds for Visual (High Load) condition');
    grid on;
    
    %% Plot weights
    % Plot model weights for audio condition for subject
    figure(500);
    data2plot = squeeze(mean(average_audio_model.w,1));
    plot(average_audio_model.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights for Audio condition');
    
    % Plot model weights for visual low condition for subject
    figure(600);
    data2plot = squeeze(mean(average_visualLow_model.w,1));
    plot(average_visualLow_model.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights for Visual (Low Load) condition');
    
    % Plot model weights for visual high for subject
    figure(700);
    data2plot = squeeze(mean(average_visualHigh_model.w,1));
    plot(average_visualHigh_model.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights for Visual (High Load) condition');


    %% Permutation statistics

    %nullstats = mTRFpermute(stim_epoch,resp_epoch,fs,-1,'permute',tmin,tmax,lambda);

    %% Save data

    if ~isfolder(analysis_folder); mkdir(analysis_folder); end
    save(fullfile(analysis_folder,['modelAccuracy_' subject2process '.mat']),'rmax_audio','rmax_visualLow','rmax_visualHigh','lambda','cv_audio','cv_visualLow','cv_visualHigh','lambdas','tmin','tmax','average_audio_model','average_visualLow_model','average_visualHigh_model');
    saveas(200,fullfile(analysis_folder,['modelAccuracy_' subject2process '_Audio' '.png']));
    saveas(300,fullfile(analysis_folder,['modelAccuracy_' subject2process '_VisualLow' '.png']));
    saveas(400,fullfile(analysis_folder,['modelAccuracy_' subject2process '_VisualHigh' '.png']));
    saveas(500,fullfile(analysis_folder,['modelWeights_' subject2process '_Audio' '.png']));
    saveas(600,fullfile(analysis_folder,['modelWeights_' subject2process '_VisualLow' '.png']));
    saveas(700,fullfile(analysis_folder,['modelWeights_' subject2process '_VisualHigh' '.png']));

end

