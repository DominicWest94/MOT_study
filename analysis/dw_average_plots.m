es_batch_init;

%% Set paths and files

modelPath = fullfile(pathstem,'TRF');
modelFiles = dir(fullfile(modelPath,'allModelData_subj*.mat'));

%% Initialise matrices

numParticipants = numel(modelFiles);
numConditions = 3;

weights_env = [];
weights_ph = [];
R_env = [];
R_ph = [];

%% Load all TRF data

for s = 1:numParticipants
    subject2process = SID{s};
    load(fullfile(modelPath, ['allModelData_' subject2process '.mat'])); % TRF data
    load(fullfile(modelPath, ['maxSensors_' subject2process '.mat'])); % max sensors

    % Get average r values from top 20 sensors - envelope
    R_env(s,1) = mean(sensorRaudio_env(:,maxSensors_env));
    R_env(s,2) = mean(sensorRvisualLow_env(:,maxSensors_env));
    R_env(s,3) = mean(sensorRvisualHigh_env(:,maxSensors_env));
    % Get average r values from top 20 sensors - phoneme surprisal
    R_ph(s,1) = mean(sensorRaudio_ph(:,maxSensors_ph));
    R_ph(s,2) = mean(sensorRvisualLow_ph(:,maxSensors_ph));
    R_ph(s,3) = mean(sensorRvisualHigh_ph(:,maxSensors_ph));

    % Extract envelope TRF weights for each condition
    weights_env(:,:,s,1) = squeeze(audio_model_env.w(1,:,maxSensors_env));
    weights_env(:,:,s,2) = squeeze(visualLow_model_env.w(1,:,maxSensors_env));
    weights_env(:,:,s,3) = squeeze(visualHigh_model_env.w(1,:,maxSensors_env));

    % Extract phoneme surprisal TRF weights for each condition
    weights_ph(:,:,s,1) = squeeze(audio_model_ph.w(1,:,maxSensors_ph));
    weights_ph(:,:,s,2) = squeeze(visualLow_model_ph.w(1,:,maxSensors_ph));
    weights_ph(:,:,s,3) = squeeze(visualHigh_model_ph.w(1,:,maxSensors_ph));

end

%% Compute the RMS of model weights

% Compute RMS across sensors and then average across participants and conditions
rms_env = mean(mean(rms(weights_env,2),3),4);
rms_ph = mean(mean(rms(weights_ph,2),3),4); 
avgRMS = mean(cat(2, rms_env, rms_ph), 2); % Combine envelope and phoneme RMS

%% Compute average model weights and r values for each condition

avgWeights_env = squeeze(mean(weights_env, 3)); % Average across participants
avgWeights_ph = squeeze(mean(weights_ph, 3)); % Average across participants

avgR_env = mean(R_env);
avgR_ph = mean(R_ph);

%% Plot model weights

timeLags = audio_model_env.t; % Assuming timeLags is consistent across all models

figure(100);
for condition = 1:numConditions
    subplot(numConditions, 1, condition);
    plot(timeLags, avgWeights_env(:,:,condition)); % Mean across sensors
    xlabel('Time Lag (ms)');
    ylabel('Model Weights');
    title(['Average envelope TRF for Condition ', num2str(condition)]);
    grid on;
end
sgtitle('Average TRF for each condition, Broadband Envelope');

figure(200);
for condition = 1:numConditions
    subplot(numConditions, 1, condition);
    plot(timeLags, avgWeights_ph(:,:,condition)); % Mean across sensors
    xlabel('Time Lag (ms)');
    ylabel('Model Weights');
    title(['Average phoneme surprisal TRF for Condition ', num2str(condition)]);
    grid on;
end
sgtitle('Average TRF for each condition, Phoneme Surprisal');

%% Plot RMS of model weights

figure(300);
plot(timeLags, avgRMS, 'LineWidth', 2);
xlabel('Time Lag (ms)');
ylabel('RMS Amplitude');
title('Averaged RMS Amplitude Across All Sensors, Conditions, and Participants');
grid on;
ylim([0, max(avgRMS) * 1.1]);

%% Plot model accuracies (top 20 sensors)

% Labels
factor1names = {'Envelope', 'Phoneme Surprisal'};
factor2names = {'Audio', 'Visual (Low)', 'Visual (High)'};

% Y-axis limits
mini = .01;
maxi = .1;

% Plot
figure(400);
r2plot_env_current = es_removeBetween(R_env);
r2plot_env_means = squeeze(mean(r2plot_env_current,1));
r2plot_env_sems = squeeze(std(r2plot_env_current,0,1)/sqrt(length(1:numParticipants)));
r2plot_ph_current = es_removeBetween(R_ph);
r2plot_ph_means = squeeze(mean(r2plot_ph_current,1));
r2plot_ph_sems = squeeze(std(r2plot_ph_current,0,1)/sqrt(length(1:numParticipants)));

plot(r2plot_env_means);
errorbar(r2plot_env_means(1:3),r2plot_env_sems(1:3),'-k','LineWidth',1); hold on
errorbar(r2plot_ph_means(1:3),r2plot_ph_sems(1:3),'--k','LineWidth',1);
set(gca,'xtick',1:3); set(gca,'xticklabel',factor2names); set(gca,'FontSize',15); ylim([mini maxi]); title('Model accuracy');
legend(factor1names);

%% Save plots
saveas(100, fullfile(modelPath, 'average_TRF_env.png'));
saveas(200, fullfile(modelPath, 'average_TRF_ph.png'));
saveas(300, fullfile(modelPath, 'average_combined_TRF_RMS.png'));
saveas(400, fullfile(modelPath, 'average_model_accuracies.png'));
