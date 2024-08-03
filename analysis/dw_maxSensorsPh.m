%% Set paths and files

modelPath = fullfile(pathstem,'TRF','ph_encoding');
modelFiles = dir(fullfile(modelPath,'surprisal_modelAccuracy_subj*.mat'));

%% Loop for all participants

for s=1:numel(modelFiles) % loop through model data files

    load(fullfile(modelPath,modelFiles(s).name));
    % get r values across conditions
    sensorRaudio = squeeze(mean(mean(cv_audio.r,1),2));
    sensorRvisualHigh = squeeze(mean(mean(cv_visualHigh.r,1),2));
    sensorRvisualLow = squeeze(mean(mean(cv_visualLow.r,1),2));
    sensorRall = mean([sensorRaudio sensorRvisualHigh sensorRvisualLow],2);
    % get indices of sensors
    [~,indexR] = sort(sensorRall,'descend');
    % get top 20
    maxSensors = indexR(1:20)';
    % save
    save(fullfile(modelPath,['PhonemeSurprisal_maxSensors_subj' num2str(s) '.mat']),'maxSensors');

end
