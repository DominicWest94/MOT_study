clearvars

%% Get folder names and subject list

es_batch_init;

%% Set-up variables (e.g. subject IDs and file paths)

stimulus_folder  = '../stimuli';
analysis_folder = fullfile(pathstem,'TRF');
analysis_folder_env = fullfile(pathstem,'TRF','env_encoding_figures');
analysis_folder_ph = fullfile(pathstem,'TRF','ph_encoding_figures');
fs_new = 64;

% Model hyperparameters
tmin = -100;
tmax = 900;
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
    stim{1,a} = env;
end

%% Load predictability data for all chapters
audio_list = dir(fullfile(stimulus_folder,'audio_*.mat'));
for a=1:numel(audio_list)
    % Get surprisal values
    audio_file = audio_list(a).name;
    load(fullfile(stimulus_folder,audio_file),'model');
    x = model.segments.surprisal;
%     audio_raw{a} = x; % for later plotting
    
    % Normalise data
    x = zscore(x,0,1);
    stim{2,a} = x;
end

%% Loop over subjects and chapters

for s=10:numel(SID)
    
    all_audio_stim_env = [];
    all_audio_stim_ph = [];
    all_visualLow_stim_env = [];
    all_visualLow_stim_ph = [];
    all_visualHigh_stim_env = [];
    all_visualHigh_stim_ph = [];
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
        current_stim = stim(:,chapter); % select stim data for current chapter
        current_stim_env = current_stim{1};
        current_stim_ph = current_stim{2};
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
        if triggerVals(5) == 200
            continue
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
        current_stim_env = [zeros(speechOnset-1,1); current_stim_env(:,1)];
        current_stim_ph = [zeros(speechOnset-1,1); current_stim_ph];
        
        %% Epoch data
        stim_epoch_env = {};
        stim_epoch_ph = {};
        resp_epoch = {};
        bad_epoch = [];
    
        epochDur = 10; % in seconds
        epochDur = floor(epochDur*fs_new); % convert to samples
        
        % Epoch trials here
        for e=1:length(MOTOnset)
            resp_epoch = [resp_epoch; resp(MOTOnset(e):MOTOnset(e)+epochDur-1,:)];
            stim_epoch_env = [stim_epoch_env; current_stim_env(MOTOnset(e):MOTOnset(e)+epochDur-1,:)];
            stim_epoch_ph = [stim_epoch_ph; current_stim_ph(MOTOnset(e):MOTOnset(e)+epochDur-1,:)];

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
            stim_epoch_env = stim_epoch_env(ind_good);
            stim_epoch_ph = stim_epoch_ph(ind_good);

        end

        % How many epochs after artefact rejection
        nEpochsGood = size(resp_epoch,1);
        fprintf('\nRejecting %d out of %d trials\n\n',nEpochsAll-nEpochsGood,nEpochsAll);
        
        % Gather all epochs by condition, across blocks
        if strcmp(condition,'Audio') == 1
            all_audio_stim_env = [all_audio_stim_env; stim_epoch_env];
            all_audio_stim_ph = [all_audio_stim_ph; stim_epoch_ph];
            all_audio_resp = [all_audio_resp; resp_epoch];

        else
            if strcmp(MOT_load,'Low') == 1
                all_visualLow_stim_env = [all_visualLow_stim_env; stim_epoch_env];
                all_visualLow_stim_ph = [all_visualLow_stim_ph; stim_epoch_ph];
                all_visualLow_resp = [all_visualLow_resp; resp_epoch];

            else
                all_visualHigh_stim_env = [all_visualHigh_stim_env; stim_epoch_env];
                all_visualHigh_stim_ph = [all_visualHigh_stim_ph; stim_epoch_ph];
                all_visualHigh_resp = [all_visualHigh_resp; resp_epoch];
            end
        end
    end
        
    %% Compute model across conditions
    % Run cross-validation for each condition (rather than per block, to
    % prevent over-fitting) - envelope
    cv_audio_env = mTRFcrossval(all_audio_stim_env,all_audio_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);
    cv_visualLow_env = mTRFcrossval(all_visualLow_stim_env,all_visualLow_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);
    cv_visualHigh_env = mTRFcrossval(all_visualHigh_stim_env,all_visualHigh_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);

    % Run cross-validation for each condition (rather than per block, to
    % prevent over-fitting) - phoneme surprisal
    cv_audio_ph = mTRFcrossval(all_audio_stim_ph,all_audio_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);
    cv_visualLow_ph = mTRFcrossval(all_visualLow_stim_ph,all_visualLow_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);
    cv_visualHigh_ph = mTRFcrossval(all_visualHigh_stim_ph,all_visualHigh_resp,fs_new,1,tmin,tmax,lambdas,'zeropad',0);
    
    % Average over conditions
    cv_avg_env.r = (cv_audio_env.r+cv_visualLow_env.r+cv_visualHigh_env.r)/3;
    cv_avg_ph.r = (cv_audio_ph.r+cv_visualLow_ph.r+cv_visualHigh_ph.r)/3;
    
    % Find optimal regularization value (after averaging over folds and channels)
    [rmax_env,idx_env] = max(squeeze(mean(mean(cv_avg_env.r,3),1)));
    [rmax_ph,idx_ph] = max(squeeze(mean(mean(cv_avg_ph.r,3),1)));
    
    % optimal lambda for subject across conditions
    subj_lambda_env = lambdas(idx_env);
    subj_lambda_ph = lambdas(idx_ph);
    
    % Audio model using participant lambda
    audio_model_env = mTRFtrain(all_audio_stim_env,all_audio_resp,fs_new,1,tmin,tmax,subj_lambda_env,'zeropad',0);
    audio_model_ph = mTRFtrain(all_audio_stim_ph,all_audio_resp,fs_new,1,tmin,tmax,subj_lambda_ph,'zeropad',0);
    
    % Visual Low model using participant lambda
    visualLow_model_env = mTRFtrain(all_visualLow_stim_env,all_visualLow_resp,fs_new,1,tmin,tmax,subj_lambda_env,'zeropad',0);
    visualLow_model_ph = mTRFtrain(all_visualLow_stim_ph,all_visualLow_resp,fs_new,1,tmin,tmax,subj_lambda_ph,'zeropad',0);
    
    % Visual High model using participant lambda
    visualHigh_model_env = mTRFtrain(all_visualHigh_stim_env,all_visualHigh_resp,fs_new,1,tmin,tmax,subj_lambda_env,'zeropad',0);
    visualHigh_model_ph = mTRFtrain(all_visualHigh_stim_ph,all_visualHigh_resp,fs_new,1,tmin,tmax,subj_lambda_ph,'zeropad',0);
    
    %% Plot model accuracies - envelope
    % Plot audio and envelope
%     figure(100);
%     subplot(3,1,1); plot([0:size(audio_raw{chapter},1)-1]/fs,audio_raw{chapter}); xlabel('Time (s)'); title('Original Speech Signal');
%     subplot(3,1,2); plot([0:size(current_stim,1)-1]/fs_new,current_stim); xlabel('Time (s)'); title('Broadband Envelope');
%     subplot(3,1,3); plot([0:size(resp,1)-1]/fs_new,resp); xlabel('Time (s)'); title('EEG');
%     saveas(100,fullfile(analysis_folder,['regressors_' subject2process '_b' blocks2process{b} '_chapter' num2str(chapter) '_' condition '_' MOT_load '.png']));

    % Plot correlation across lambdas for all conditions
    figure(1100);
    data2plot = mean(cv_avg_env.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (envelope) across folds across all conditions');
    grid on;
    
    % Plot correlation across lambdas for audio condition
    figure(1200);
    data2plot = mean(cv_audio_env.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (envelope) across folds for Audio condition');
    grid on;
    
    % Plot correlation across lambdas for visual low condition
    figure(1300);
    data2plot = mean(cv_visualLow_env.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (envelope) across folds for Visual (Low Load) condition');
    grid on;
    
    % Plot correlation across lambdas for visual high condition
    figure(1400);
    data2plot = mean(cv_visualHigh_env.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (envelope) across folds for Visual (High Load) condition');
    grid on;

    %% Plot model accuracies - phoneme surprisal
    % Plot audio and envelope
%     figure(100);
%     subplot(3,1,1); plot([0:size(audio_raw{chapter},1)-1]/fs,audio_raw{chapter}); xlabel('Time (s)'); title('Original Speech Signal');
%     subplot(3,1,2); plot([0:size(current_stim,1)-1]/fs_new,current_stim); xlabel('Time (s)'); title('Broadband Envelope');
%     subplot(3,1,3); plot([0:size(resp,1)-1]/fs_new,resp); xlabel('Time (s)'); title('EEG');
%     saveas(100,fullfile(analysis_folder,['regressors_' subject2process '_b' blocks2process{b} '_chapter' num2str(chapter) '_' condition '_' MOT_load '.png']));

    % Plot correlation across lambdas for all conditions
    figure(2100);
    data2plot = mean(cv_avg_ph.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (phoneme surprisal) across folds across all conditions');
    grid on;
    
    % Plot correlation across lambdas for audio condition
    figure(2200);
    data2plot = mean(cv_audio_ph.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (phoneme surprisal) across folds for Audio condition');
    grid on;
    
    % Plot correlation across lambdas for visual low condition
    figure(2300);
    data2plot = mean(cv_visualLow_ph.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (phoneme surprisal) across folds for Visual (Low Load) condition');
    grid on;
    
    % Plot correlation across lambdas for visual high condition
    figure(2400);
    data2plot = mean(cv_visualHigh_ph.r,3); % average over electrodes
    boxplot(data2plot);
    set(gca,'xticklabel',lambdas);
    ylabel('Correlation')
    xlabel('Lambda');   
    title('Model accuracy (phoneme surprisal) across folds for Visual (High Load) condition');
    grid on;

    %% Plot weights - envelope
    % Plot model weights for audio condition for subject
    figure(1500);
    data2plot = squeeze(mean(audio_model_env.w,1));
    plot(audio_model_env.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights (envelope) for Audio condition');
    
    % Plot model weights for visual low condition for subject
    figure(1600);
    data2plot = squeeze(mean(visualLow_model_env.w,1));
    plot(visualLow_model_env.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights (envelope) for Visual (Low Load) condition');
    
    % Plot model weights for visual high for subject
    figure(1700);
    data2plot = squeeze(mean(visualHigh_model_env.w,1));
    plot(visualHigh_model_env.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights (envelope) for Visual (High Load) condition');

    %% Plot weights - phoneme surprisal
    % Plot model weights for audio condition for subject
    figure(2500);
    data2plot = squeeze(mean(audio_model_ph.w,1));
    plot(audio_model_env.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights (phoneme surprisal) for Audio condition');
    
    % Plot model weights for visual low condition for subject
    figure(2600);
    data2plot = squeeze(mean(visualLow_model_ph.w,1));
    plot(visualLow_model_env.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights (phoneme surprisal) for Visual (Low Load) condition');
    
    % Plot model weights for visual high for subject
    figure(2700);
    data2plot = squeeze(mean(visualHigh_model_ph.w,1));
    plot(visualHigh_model_env.t,data2plot);
    xlabel('Lag (ms)');
    title('Model weights (phoneme surprisal) for Visual (High Load) condition');

    %% Permutation statistics

    %nullstats = mTRFpermute(stim_epoch,resp_epoch,fs,-1,'permute',tmin,tmax,lambda);

    %% Save data

    if ~isfolder(analysis_folder); mkdir(analysis_folder); end
    if ~isfolder(analysis_folder_env); mkdir(analysis_folder_env); end
    if ~isfolder(analysis_folder_ph); mkdir(analysis_folder_ph); end
    save(fullfile(analysis_folder,['allModelData_' subject2process '.mat']), ...
        'idx_env','idx_ph','rmax_env','rmax_ph','subj_lambda_env','subj_lambda_ph', ...
        'cv_audio_env','cv_audio_ph','cv_visualLow_env', 'cv_visualLow_ph','cv_visualHigh_env','cv_visualHigh_ph', ...
        'audio_model_env','audio_model_ph','visualLow_model_env','visualLow_model_ph','visualHigh_model_env','visualHigh_model_ph');
    saveas(1100,fullfile(analysis_folder_env,['env_modelAccuracy_' subject2process '_all.png']));
    saveas(1200,fullfile(analysis_folder_env,['env_modelAccuracy_' subject2process '_Audio.png']));
    saveas(1300,fullfile(analysis_folder_env,['env_modelAccuracy_' subject2process '_VisualLow.png']));
    saveas(1400,fullfile(analysis_folder_env,['env_modelAccuracy_' subject2process '_VisualHigh.png']));
    saveas(1500,fullfile(analysis_folder_env,['env_modelWeights_' subject2process '_Audio.png']));
    saveas(1600,fullfile(analysis_folder_env,['env_modelWeights_' subject2process '_VisualLow.png']));
    saveas(1700,fullfile(analysis_folder_env,['env_modelWeights_' subject2process '_VisualHigh.png']));
    saveas(2100,fullfile(analysis_folder_ph,['ph_modelAccuracy_' subject2process '_all.png']));
    saveas(2200,fullfile(analysis_folder_ph,['ph_modelAccuracy_' subject2process '_Audio.png']));
    saveas(2300,fullfile(analysis_folder_ph,['ph_modelAccuracy_' subject2process '_VisualLow.png']));
    saveas(2400,fullfile(analysis_folder_ph,['ph_modelAccuracy_' subject2process '_VisualHigh.png']));
    saveas(2500,fullfile(analysis_folder_ph,['ph_modelWeights_' subject2process '_Audio.png']));
    saveas(2600,fullfile(analysis_folder_ph,['ph_modelWeights_' subject2process '_VisualLow.png']));
    saveas(2700,fullfile(analysis_folder_ph,['ph_modelWeights_' subject2process '_VisualHigh.png']));

end
