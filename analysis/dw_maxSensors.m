%% Set paths and files

modelPath = fullfile(pathstem,'TRF');
modelFiles = dir(fullfile(modelPath,'allModelData_subj*.mat'));

%% Loop for all participants

for s=1:numel(modelFiles) % loop through model data files
    subject2process = SID{s};
    %% Max Sensors for envelope TRF
    load(fullfile(modelPath, ['allModelData_' subject2process '.mat']));
    % get r values across conditions and trials
    sensorRaudio_env = squeeze(mean(cv_audio_env.r,1)); % get average r across trials
    sensorRaudio_env = sensorRaudio_env(idx_env,:); % select only r values for index of subj lambda
    sensorRvisualHigh_env = squeeze(mean(cv_visualHigh_env.r,1));
    sensorRvisualHigh_env = sensorRvisualHigh_env(idx_env,:);
    sensorRvisualLow_env = squeeze(mean(cv_visualLow_env.r,1));
    sensorRvisualLow_env = sensorRvisualLow_env(idx_env,:);
    sensorRall_env = mean([sensorRaudio_env;sensorRvisualHigh_env;sensorRvisualLow_env],1);
    % get indices of sensors
    [~,indexR_env] = sort(sensorRall_env,'descend');
    % get top 20
    maxSensors_env = indexR_env(1:20)';
    
    %% Max Sensors for phoneme surprisal TRF
    % get r values across conditions and trials
    sensorRaudio_ph = squeeze(mean(cv_audio_ph.r,1)); % get average r across trials
    sensorRaudio_ph = sensorRaudio_ph(idx_ph,:); % select only r values for index of subj lambda
    sensorRvisualHigh_ph = squeeze(mean(cv_visualHigh_ph.r,1));
    sensorRvisualHigh_ph = sensorRvisualHigh_ph(idx_ph,:);
    sensorRvisualLow_ph = squeeze(mean(cv_visualLow_ph.r,1));
    sensorRvisualLow_ph = sensorRvisualLow_ph(idx_ph,:);
    sensorRall_ph = mean([sensorRaudio_ph;sensorRvisualHigh_ph;sensorRvisualLow_ph],1);
    % get indices of sensors
    [~,indexR_ph] = sort(sensorRall_ph,'descend');
    % get top 20
    maxSensors_ph = indexR_ph(1:20)';

    % save
    save(fullfile(modelPath,['maxSensors_subj' num2str(s) '.mat']),'maxSensors_env','maxSensors_ph', ...
        'sensorRaudio_env','sensorRvisualLow_env','sensorRvisualHigh_env', ...
        'sensorRaudio_ph','sensorRvisualLow_ph','sensorRvisualHigh_ph');

end
