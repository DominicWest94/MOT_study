%% Set up global variables and subject definitions

clearvars

% other parameters
fs = 2048; % Sampling rate at acquisition
fs_new = 256; % downsampled sampling rate

% add required paths
addpath('./spm12');
addpath('./NoiseTools');
addpath('./utilities');
addpath('./estools');
addpath('./nsltools');
%addpath('./mTRF_1.5');
addpath('./mtrf');

% define paths
rawpathstem = '../eeg_files/raw_eeg/';
pathstem = '../eeg_files/processed_eeg';
behaviourstem = '../behavioural_files';

% define subjects and blocks
cnt = 0; % never comment this

cnt = cnt + 1;
fileName{cnt} = 'S1_MOT_20240327';            % EEG file
SID{cnt} = 'subj1';                           % subject ID
blocksin{cnt} = {'1' '2' '3'};                % block numbers when imported
blocksout{cnt} = {'1' '2' '3'};               % block numbers when saved 
badeeg{cnt}{1} = {'A5' 'A8' 'B13' 'B18' 'D22'}; % bad electrode channels per block
badeeg{cnt}{2} = {'A5' 'A8' 'B13'};
badeeg{cnt}{3} = {'A5' 'A7' 'A8' 'A18' 'B13' 'C4' 'C6' 'D22' 'D31'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
% ppt had afro hair so unstable readings

cnt = cnt + 1;
fileName{cnt} = 'S2_MOT_20240327';
SID{cnt} = 'subj2';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'D9'};
badeeg{cnt}{2} = {'A17' 'A21' 'A32' 'D9'};
badeeg{cnt}{3} = {'A17' 'D9' 'D13'};
badeeg{cnt}{4} = {'A10' 'B10' 'B18' 'D9' 'D32'};
badeeg{cnt}{5} = {'D7' 'D9' 'D23'};
badeeg{cnt}{6} = {'D9' 'D23'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S3_MOT_20240507';
SID{cnt} = 'subj3';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'C8' 'C13' 'C21' 'C27' 'C29' 'D21'};
badeeg{cnt}{2} = {'A13' 'C16' 'D18' 'D6'};
badeeg{cnt}{3} = {'A1' 'C4' 'C13'};
badeeg{cnt}{4} = {'D18' 'D32'};
badeeg{cnt}{5} = {'A13'};
badeeg{cnt}{6} = {'A13' 'C24' 'C25' 'D3'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S4_MOT_20240508';
SID{cnt} = 'subj4';
blocksin{cnt} = {'1' '2' '3'};
blocksout{cnt} = {'1' '2' '3'};
badeeg{cnt}{1} = {'A2' 'A3' 'A7' 'B18' 'C6' 'C7' 'D1' 'D13' 'D23' 'D30'};
badeeg{cnt}{2} = {'A5' 'A7' 'A23' 'B7' 'C6' 'D13'};
badeeg{cnt}{3} = {'A2' 'A3' 'A5' 'A7' 'A23' 'A24' 'B4' 'C6' 'D1' 'D13'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S5_MOT_20240508';
SID{cnt} = 'subj5';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'D9' 'D21' 'D22' 'D23' 'D29'};
badeeg{cnt}{2} = {'B26' 'B27' 'D9' 'D21' 'D22' 'D23' 'D29'};
badeeg{cnt}{3} = {'B26' 'B27' 'D9' 'D22' 'D23' 'D29' 'D32'};
badeeg{cnt}{4} = {'B27' 'D9' 'D21' 'D22' 'D23'};
badeeg{cnt}{5} = {'A9' 'B26' 'B27' 'C9' 'C19' 'D9' 'D22' 'D23' 'D29'};
badeeg{cnt}{6} = {'B26' 'B27' 'D9' 'D21' 'D22' 'D23' 'D29' 'D32'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];
