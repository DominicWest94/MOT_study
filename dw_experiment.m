%% Clear the workspace and set directories
clear all;
close all;
sca;

direxp = 'C:\Experiments\Dominic';
cd(direxp)
stimFolder = '\stimuli\'; % stimuli folder
soundFileNames = dir('stimuli\*.wav'); % audio files
locList = dir('stimuli\MOTlocs\*.mat'); % MOT files

%% Initialise random number generator
rng('default');

%% Note when script started
tExpStart = tic;

%% Get subject and block numbers
prompt = {'Subject:','Block:','Condition:','Chapter:'}; % condition: 1 - auditory, 2 - low load, 3 - high load
dlg_title = 'Input';
answer = inputdlg(prompt,dlg_title,1);
subject = str2num(answer{1});
block = str2num(answer{2});
condition = str2num(answer{3});
chapter = str2num(answer{4});

nTrials = 60;

%% Parameters
debugMode = 0; % setting this to 1 makes it easier to test on own computer (but don't use for actual experiment!)
ITI = 1.3 : .025 : 1.7;
fs = 48000;
nrchannels = 2;

% settings for MOT
speed     = 0.8;
objSize   = 14;
nDots     = 14;
fixSize   = 4; % size of the fixation box (well, half of it - the distance from the middle to edge horizontally/vertically)
qFrame    = 1; % width of frame around each tracking quadrant
fixCol    = [255 255 0]; % color of fixation box
frameCol  = [128 128 128];
tarCol    = [230 50 0];
taskCol   = [0 255 0];
trackSize = [500 500]; % size of MOT box
bgcolor  = 0;

% Keyboard information
KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');

%% Initialise EEG triggers

% configure serial port for triggers
[handle, errmsg] = IOPort('OpenSerialPort', 'COM3', ' BaudRate=115200 DataBits=8 StopBits=1 Parity=None');

triggerSpeechOnset = uint8(255);
triggerSpeechOffset = uint8(245);
triggerFeedbackOnset = uint8(235);
triggerMOTOnset = uint8(225);
triggerMOTOffset = uint8(215);

%% Select and randomise stimuli

% Generate random sequence of 1s and 0s for dot selection; 1 - target selected, 0 - target not selected
randOrder = randperm(nTrials);
tarSeq = mod(randOrder, 2);

%% Prepare data file
data = {'Subject','Block','Condition','Chapter','Target','Response','Sound onset','MOT onset','MOT offset'};

%% Prepare screen, inputs and sound
dw_ptb_prepare;
slack = Screen('GetFlipInterval', window)/2;
screenSf = Screen('NominalFrameRate',window); % screen refresh rate
screenDT = 1/screenSf;                         % delta t of the refresh rate
rect = Screen('Rect',window);
xMid = rect(3)/2;
yMid = rect(4)/2;
trackRect = [xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2];

Screen(window,'FillRect',bgcolor);
Screen('Flip', window);

%% Preload sound files into matlab workspace
audioCurrent = audioread([direxp stimFolder soundFileNames(chapter).name]);
audioCurrent = audioCurrent'; % Transpose for psychtoolbox

%% Present intro screen to participant

% display prompt
DrawFormattedText(window, ['Please fixate on the point at the center of the screen during the task (blinks are OK)\n\n' ...
                            'Try to keep as still as possible throughout\n\n\n\n' ...
                            'To answer any questions on screen, use the LEFT and RIGHT arrow keys\n\n'...
                            'Press any key to continue'], 'center', 'center', white);
Screen('Flip', window);
% wait for key press
KbStrokeWait;

%% Present beginning-of-block screen

% display prompt
if condition == 1 % attend to audio
    DrawFormattedText(window, ['Please pay attention only to the AUDITORY stimulation\n\n\n\n' ...
                                'In the following you will hear a section of an audiobook\n\n' ...
                                'Your task is to listen\n\n' ...
                                'IGNORE any visual stimulation\n\n' ...
                                'During each trial, fixate at the center of the screen\n\n\n\n' ...
                                'Press any key to begin'], 'center', 'center', white);
else % attend to visual
    DrawFormattedText(window, ['Please pay attention only to the VISUAL stimulation\n\n\n\n' ...
                                'You will see multiple white dots appear on the screen\n\n' ...
                                'Some of the dots will briefly flash red\n\n' ...
                                'All of the dots will then start to move\n\n' ...
                                'Your task is to track the dots that flashed red, while fixating at the middle of the screen\n\n\n\n' ...
                                'After a short period, all the dots will stop moving and one dot will turn green\n\n' ...
                                'You will be asked if this dot was one of the red dots you were asked to track\n\n\n\n' ...
                                'IGNORE any audio stimulation\n\n\n\n' ...
                                'Press any key to begin'], 'center', 'center', white);
end
Screen('Flip', window);
% wait for key press
KbStrokeWait;

%% Trial loop here

% Fill the audio playback buffer with the audio data, doubled for stereo presentation
PsychPortAudio('FillBuffer', pahandle, audioCurrent);
WaitSecs(1);

% Start audio playback
tStartSoundCurrent = PsychPortAudio('Start', pahandle, 1, 0, waitForDeviceStart);
% Send EEG trigger at sound onset
IOPort('Write',handle,triggerSpeechOnset);

for trial=1:nTrials % Loop for one block

    % Get ITI
    indRandom = randperm(length(ITI));
    ITIcurrent = ITI(indRandom(1));

    % Load locations of dots
    load([direxp stimFolder 'MOTlocs\' locList(trial).name]);

    % Get all dot positions for the trial
    dotPos = cat(1,locs(1,:,:)+trackRect(1)-objSize, locs(2,:,:)+trackRect(2)-objSize, locs(1,:,:)+trackRect(1)+objSize, locs(2,:,:)+trackRect(2)+objSize);

    % get target and distractor indices
    [~,ixr] = sort(rand([1 size(dotPos,2)]));
    if condition == 1 % auditory only
        randLoad = randi(2);
        if randLoad == 1 % random low load       
            ixtar = ixr(1:2);
            ixdis = ixr(3:end);
        else            % random high load
            ixtar = ixr(1:5);
            ixdis = ixr(6:end);
        end
    elseif condition == 2 % low load
        ixtar = ixr(1:2);
        ixdis = ixr(3:end);
    else                  % high load
        ixtar = ixr(1:5);
        ixdis = ixr(6:end);
    end

    % draw which dots to track
    Screen('FillRect', window,bgcolor);
    Screen('FillRect', window,black,[xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2]);
    Screen('FillOval', window, white, dotPos(:,ixdis,1), objSize);
    Screen('FillOval', window, tarCol, dotPos(:,ixtar,1), objSize);
    Screen('FrameRect', window,frameCol,trackRect,qFrame); % drawn frame around the dot area
    Screen('FillRect', window,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box
    Screen('Flip', window);
    WaitSecs(2);

    % Send EEG trigger at MOT onset
    IOPort('Write',handle,triggerMOTOnset);
    % present MOT
    flipTime = Screen('Flip', window);
    MOTOnset = flipTime;
    for fi = 1 : size(dotPos,3)
        Screen('FillRect',window,bgcolor);
        Screen('FillRect',window,black,[xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2]);

        Screen('FillOval', window, white, dotPos(:,:,fi), objSize);
        Screen('FrameRect', window,frameCol,trackRect,qFrame); % drawn frame around the dot area
        Screen('FillRect', window,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box

        flipTime(fi) = Screen('Flip', window, flipTime(end) + screenDT - slack,0);
    end
    % Send EEG trigger at MOT offset
    IOPort('Write',handle,triggerMOTOffset);

    % which dot to highlight for the task
    if tarSeq(trial) == 1 % target out of the marked dots
        [~,ixr] = sort(rand([1 length(ixtar)]));
        ixmark  = ixtar(ixr(1));
    else  % target out of the distractor dots
        [~,ixr] = sort(rand([1 length(ixdis)]));
        ixmark  = ixdis(ixr(1));
    end

    % get colored dot drawn for the task
    Screen('FillRect', window,bgcolor);
    Screen('FillRect', window,black,[xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2]);
    Screen('FillOval', window, white, dotPos(:,~ismember(1:size(dotPos,2),ixmark),end), objSize);
    Screen('FillOval', window, taskCol, dotPos(:,ismember(1:size(dotPos,2),ixmark),end), objSize);
    Screen('FrameRect', window,frameCol,trackRect,qFrame); % drawn frame around the dot area
    Screen('FillRect', window,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box
    flipTime = Screen('Flip', window);
    MOTOffset = flipTime;
    WaitSecs(1);
    
    if condition == 2 || 3 % MOT task
        % get response
        respToBeMade = true;
    
        while respToBeMade == true
            % draw response screen
            DrawFormattedText(window, ['Was the green dot one of the ones you were asked to track?\n\n\n' ...
                                        'Yes ................... No'], 'center', 'center', white);
            % flip to the screen
            Screen('Flip', window);
            % check the keyboard
            [~,keyCode] = KbWait;
            if keyCode(escapeKey)
                ShowCursor;
                sca;
                return
            elseif keyCode(leftKey)
                response = 1;
                respToBeMade = false;
            else
                response = 0;
                respToBeMade = false;
            end       
        end

        % Clear screen
        Screen('FillRect',window,black);
        Screen('Flip', window);
        
        % Wait for a bit before showing written feedback
        WaitSecs(0.5);
    
        % Draw feedback text
        if response == tarSeq(trial)
            DrawFormattedText(window, 'Correct', 'center', 'center', white);
        else
            DrawFormattedText(window, 'Incorrect', 'center', 'center', white);
        end
        % flip to the screen
        Screen('Flip', window);
        WaitSecs(2);
        % send trigger at written feedback onset
        IOPort('Write',handle,triggerFeedbackOnset);
    else        % Auditory only
        response = 3; % no response
    end

    % Clear screen
    Screen('FillRect',window,black);
    Screen('Flip', window);

    % Wait for ITI before next trial
    WaitSecs(ITIcurrent);

    % Collect data
    data(1+trial,:) = [{subject},{block},{condition},{chapter},{tarSeq(trial)},{response},{tStartSoundCurrent},{MOTOnset},{MOTOffset}];

    % Display progress to experimenter
    fprintf('\nTrial %d: Target %d, Response %d...\n',trial,tarSeq(trial),response);
end

% Stop audio playback
[~,~,~,tEndSoundCurrent] = PsychPortAudio('Stop',pahandle,1);
% Send EEG trigger at sound offset
IOPort('Write',handle,triggerSpeechOffset);

%% End of block screen
DrawFormattedText(window, '***END OF BLOCK***','center', 'center', white);
Screen('Flip', window);
WaitSecs(4);

%% Shut down and save data
dw_ptb_close;
IOPort('CloseAll');

%% Note when script finished
tExpDur = toc(tExpStart)/60;
fprintf('\nTime taken = %f minutes\n',tExpDur);
