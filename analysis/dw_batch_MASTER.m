%% Set up global variables and subject definitions

clearvars

es_batch_init;

% load SPM
%spm('EEG'); % better to do this manually after starting Matlab so that spm isn't loaded each time scripts are run (takes time)

%% Preprocess continuous data (prior to epoching)

for s=1:length(fileName)
    PreprocessMEGDataBeforeEpochs_1Subj(pathstem,rawpathstem,SID{s},fileName{s},blocksin{s},badeeg{s},badcomp{s},fs_new);
end

%% Epoching and mTRF modelling

dw_batch_encoding_env;
dw_batch_encoding_phoneme;

%% Refined mTRF modelling
dw_maxSensorsEnv;
dw_maxSensorsPh;
dw_batch_encoding_env_MaxSensors;
dw_batch_encoding_phoneme_MaxSensors;
