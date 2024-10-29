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
badeeg{cnt}{2} = {'A5' 'A7' 'A8' 'B13'};
badeeg{cnt}{3} = {'A5' 'A7' 'A8' 'A18' 'B13' 'C4' 'C6' 'D19' 'D22' 'D31'};
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
badeeg{cnt}{3} = {'A17' 'D9' 'D13' 'D17'};
badeeg{cnt}{4} = {'A10' 'B10' 'B18' 'D9' 'D32'};
badeeg{cnt}{5} = {'A2' 'A3' 'A25' 'A26' 'A32' 'B9' 'B14' 'C30' 'D7' 'D9' 'D23' 'D31'};
badeeg{cnt}{6} = {'B9' 'D9' 'D23'};
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
badeeg{cnt}{2} = {'A1' 'A2' 'A5' 'A7' 'A15' 'A16' 'A23' 'B4' 'B7' 'C6' 'D13' 'D23' 'D24' 'C7'};
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

cnt = cnt + 1;
fileName{cnt} = 'S6_degraded_20240628';
SID{cnt} = 'subj6';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'B24' 'B25' 'B29' 'B30' 'B31' 'D22' 'A13' 'A14' 'A15'  'D20' };
badeeg{cnt}{2} = {'B24' 'B25' 'B29' 'B30' 'B31' 'D22' 'D5'};
badeeg{cnt}{3} = {'B24' 'B25' 'B29' 'B30' 'B31' 'D22' 'A13' 'A14' 'A15' 'D19'};
badeeg{cnt}{4} = {'B24' 'B25' 'B29' 'B30' 'B31' 'D22' 'A13' 'A14' 'A15'};
badeeg{cnt}{5} = {'B24' 'B25' 'B29' 'B30' 'B31' 'D22' 'A13' 'A14' 'A15' 'A19' 'D5'};
badeeg{cnt}{6} = {'B24' 'B25' 'B29' 'B30' 'B31' 'D22' 'A13' 'A14' 'A15' 'A19'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S7_degraded_20240628';
SID{cnt} = 'subj7';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'A31' 'A32' 'B1' 'B2' 'C14' 'C32' 'D12' 'D24'};
badeeg{cnt}{2} = {'A31' 'A32' 'B1' 'B2' 'C14' 'C12' 'C30' 'C32'};
badeeg{cnt}{3} = {'A31' 'A32' 'B1' 'B2' 'C14' 'B18' 'C3' 'C7' 'C30' 'D20' 'D24'};
badeeg{cnt}{4} = {'A31' 'A32' 'B1' 'B2' 'C14' 'A17' 'B14' 'C7' 'C11' 'C30' 'D32'};
badeeg{cnt}{5} = {'A31' 'A32' 'B1' 'B2' 'C14' 'B14' 'C7' 'C8' 'C22' 'C30' 'D32'};
badeeg{cnt}{6} = {'A31' 'A32' 'B1' 'B2' 'C14' 'B13' 'B14' 'C7' 'C8' 'D32'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S8_degraded_20240701';
SID{cnt} = 'subj8';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'C32'};
badeeg{cnt}{2} = {'C32'};
badeeg{cnt}{3} = {'C32'};
badeeg{cnt}{4} = {'C32'};
badeeg{cnt}{5} = {'C32'};
badeeg{cnt}{6} = {'C32'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S9_degraded_20240703';
SID{cnt} = 'subj9';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'A27' 'B7' 'C8' 'C15' 'C16' 'C30'};
badeeg{cnt}{2} = {'A27' 'B7' 'C30'};
badeeg{cnt}{3} = {'A27' 'B7' 'C30'};
badeeg{cnt}{4} = {'A27' 'B7' 'C8' 'C30'};
badeeg{cnt}{5} = {'A27' 'B7' 'D19'};
badeeg{cnt}{6} = {'A27' 'B7'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S10_degraded_20240704';
SID{cnt} = 'subj10';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'A25' 'A8' 'A9' 'A10' 'A11' 'A12' 'A15' 'A24' 'B7' 'B11' 'B25' 'C3' 'D20' 'D31' 'D32'};
badeeg{cnt}{2} = {'A25' 'A8' 'A9' 'A10' 'A11' 'A12' 'A13' 'A14' 'A15' 'B11' 'B14' 'B25' 'C3' 'D19' 'D32' 'C20' 'D8'};
badeeg{cnt}{3} = {'A25' 'A8' 'A9' 'A10' 'A11' 'A12' 'A13' 'A14' 'A15' 'B11' 'B14' 'B25' 'C3' 'D19' 'D32' 'D8'};
badeeg{cnt}{4} = {'A25' 'A8' 'A9' 'A10' 'A11' 'A12' 'A15' 'A25' 'B11' 'B14' 'B25' 'C3' 'D19' 'D32' 'D8' 'D31'};
badeeg{cnt}{5} = {'A25' 'A8' 'A9' 'A10' 'A11' 'A12' 'A15' 'A25' 'A24' 'B11' 'B14' 'B25' 'C3' 'D19' '32' 'D9' 'C8' 'C20' 'C30' 'D7' 'D32'};
badeeg{cnt}{6} = {'A25' 'A8' 'A9' 'A10' 'A11' 'A12' 'A15' 'A25' 'A24' 'B11' 'B14' 'B25' 'C3' 'D8' 'D19' 'D32' 'C20'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S11_degraded_20240709';
SID{cnt} = 'subj11';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'A25'};
badeeg{cnt}{2} = {'C5' 'D24'};
badeeg{cnt}{3} = {'B11' 'B21'};
badeeg{cnt}{4} = {'C30'};
badeeg{cnt}{5} = {'A15' 'C7' 'C30' 'D1'};
badeeg{cnt}{6} = {'A15'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S12_degraded_20240711';
SID{cnt} = 'subj12';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'A25' 'B27' 'D5' 'D6' 'D7' 'D8' 'D9' 'D10' 'C30' 'D7'};
badeeg{cnt}{2} = {'A25' 'B27' 'B18' 'D8'};
badeeg{cnt}{3} = {'A25' 'B27' 'B18'};
badeeg{cnt}{4} = {'A25' 'B27' 'D8' 'C30' 'D9'};
badeeg{cnt}{5} = {'A25' 'B27' 'C30' 'D17'};
badeeg{cnt}{6} = {'A25' 'B27' 'C8' 'C9' 'C15' 'C16' 'C17' 'C18' 'C28' 'C29' 'C30' 'C31' 'D7' 'D26' 'D30'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S13_degraded_20240712';
SID{cnt} = 'subj13';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'A11' 'A24' 'A25' 'B18' 'B25' 'B27' 'B28' 'C3' 'C4' 'D28' 'D12' 'A16' 'C8' 'C9' 'C15' 'C16' 'C17' 'C18' 'C28' 'C29' 'C30' 'C31'};
badeeg{cnt}{2} = {'A11' 'A24' 'A25' 'B18' 'B25' 'B27' 'B28' 'C3' 'C4' 'D28' 'D12'};
badeeg{cnt}{3} = {'A11' 'A24' 'A25' 'B18' 'B25' 'B27' 'B28' 'C3' 'C4' 'D28' 'D12' 'A28' 'C8' 'C28' 'C29' 'C30' 'C31'};
badeeg{cnt}{4} = {'A11' 'A24' 'A25' 'B18' 'B25' 'B27' 'B28' 'C3' 'C4' 'D28' 'D12' 'C29' 'C30' 'C31'};
badeeg{cnt}{5} = {'A11' 'A24' 'A25' 'B18' 'B25' 'B27' 'B28' 'C3' 'C4' 'D28' 'D12' 'C29' 'C30' 'C31'};
badeeg{cnt}{6} = {'A11' 'A24' 'A25' 'B18' 'B25' 'B27' 'B28' 'C3' 'C4' 'D28' 'D12'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];

cnt = cnt + 1;
fileName{cnt} = 'S14_degraded_20240716';
SID{cnt} = 'subj14';
blocksin{cnt} = {'1' '2' '3' '4' '5' '6'};
blocksout{cnt} = {'1' '2' '3' '4' '5' '6'};
badeeg{cnt}{1} = {'A18' 'B29' 'B25' 'C6' 'C7'};
badeeg{cnt}{2} = {'B29' 'C6' 'D10' 'D11' 'D12' 'D19' 'D29'};
badeeg{cnt}{3} = {'B18' 'B29' 'C5' 'C6' 'C7' 'D10' 'D11' 'D12' 'D29'};
badeeg{cnt}{4} = {'B18' 'B25' 'B29' 'B30' 'C6' 'C7' 'D29'};
badeeg{cnt}{5} = {'B18' 'B24' 'B29' 'B30' 'C7' 'D12' 'D19' 'D29'};
badeeg{cnt}{6} = {'A32' 'B18' 'B22' 'B25' 'B29' 'B30' 'D29'};
badcomp{cnt}{1}.EEG = [];
badcomp{cnt}{2}.EEG = [];
badcomp{cnt}{3}.EEG = [];
badcomp{cnt}{4}.EEG = [];
badcomp{cnt}{5}.EEG = [];
badcomp{cnt}{6}.EEG = [];
