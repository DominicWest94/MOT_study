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

%% Get subject info and block order
prompt = {'Subject:','Block:',}; % condition: 1 - auditory, 2 - visual; MOTload: 1 - low, 2 - high
dlg_title = 'Input';
answer = inputdlg(prompt,dlg_title,1);
subject = str2num(answer{1});
block = str2num(answer{2});

if subject == 101 % practice block - audio
    condition = 1;
    MOTLoad = 2;
    chapter = 7;
    nTrials = 4;
elseif subject == 102 % practice block - MOT
    condition = 2;
    MOTLoad = 2;
    chapter = 8; % is actually continuation of chapter 7, but easier for coding
    nTrials = 10;
else
    load('blockOrder.mat')
    % Find the row index, assign Condition, MOTLoad and Chapter
    rowIndx = find([blockOrder{2:end,1}] == subject & [blockOrder{2:end,2}] == block) + 1;
    condition = blockOrder{rowIndx,3};
    MOTLoad = blockOrder{rowIndx,4};
    chapter = blockOrder{rowIndx,5};
    nTrials = 30;
end

if condition == 1
    conditionStr = 'Auditory';
else
    conditionStr = 'Visual';
end

if MOTLoad == 1
    MOTLoadStr = 'Low';
else
    MOTLoadStr = 'High';
end

fprintf('Block: %d, Condition: %s, Load: %s, Chapter: %d\n',block,conditionStr,MOTLoadStr,chapter);

%% Parameters
debugMode = 0; % setting this to 1 makes it easier to test on own computer (but don't use for actual experiment!)
ITI = 1.3 : .025 : 1.7;
fs = 48000;
nrchannels = 2;

% settings for MOT
speed     = 0.8;
objSize   = 14;
nDots     = 16;
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

triggerEEGOnset = uint8(255);
triggerEEGOffset = uint8(250);
triggerConditionAudio = uint8(95);
triggerConditionVisual = uint8(105);
triggerMOTLoadHigh = uint8(115);
triggerMOTLoadLow = uint8(125);
triggerChapter1 = uint8(135);
triggerChapter2 = uint8(145);
triggerChapter3 = uint8(155);
triggerChapter4 = uint8(165);
triggerChapter5 = uint8(175);
triggerChapter6 = uint8(185);
triggerSpeechOnset = uint8(195);
triggerSpeechOffset = uint8(205);
triggerResponseOnset = uint8(215);
triggerFeedbackOnset = uint8(225);
triggerMOTOnset = uint8(235);
triggerMOTOffset = uint8(245);

%% Select and randomise stimuli

% Generate random sequence of 1s and 0s for dot selection; 1 - target selected, 0 - target not selected
randOrder = randperm(nTrials);
tarSeq = mod(randOrder, 2);
% Timestamps of sentence repeats - penultimate row is practice audio
repeatsTimes = [57 126 200 261 315 375 430 483 545 612; 59 121 198 260 307 375 437 482 562 608;...
    63 121 185 244 305 373 435 494 555 601; 62 127 183 244 304 379 424 495 550 602;...
    67 126 188 245 312 366 424 485 549 612; 64 131 192 255 306 364 434 483 552 604;...
    22 42 60 0 0 0 0 0 0 0];
repeatsRange = 5; % within how many secs after start of repeat participant must indicate
repeatsKeyPresses = [];

%% Prepare data file
data = {'Subject','Block','Condition','MOT Load','Chapter','Target','Response','Correct','Sound onset','MOT onset','MOT offset'};

%% Prepare screen, inputs and sound
dw_ptb_prepare;
slack = Screen('GetFlipInterval', window)/2;
screenSf = Screen('NominalFrameRate',window); % screen refresh rate
screenDT = 1/screenSf;                        % delta t of the refresh rate
rect = Screen('Rect',window);
xMid = rect(3)/2;
yMid = rect(4)/2;
trackRect = [xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2];

Screen(window,'FillRect',bgcolor);
Screen('Flip', window);

%% Preload sound files into matlab workspace
audioCurrent = audioread([direxp stimFolder soundFileNames(chapter).name]);
audioCurrent = audioCurrent'; % Transpose for psychtoolbox
if condition == 1
    repeatsChapter = repeatsTimes(chapter,:); % get sentence repeat timestamps for current chapter
end

%% Present intro screen to participant

% display prompt
DrawFormattedText(window, ['Please fixate on the point at the centre of the screen during the task\n\n'...
                            'Try not to blink - trials will last 10 seconds so you can blink between trials\n\n'...
                            'Try to keep as still as possible throughout\n\n\n\n' ...
                            'To answer any questions, you will need to use the LEFT and RIGHT arrow keys\n\n'...
                            'Press any key to continue'], 'center', 'center', white);
Screen('Flip', window);
% wait for key press
KbStrokeWait;

%% Present beginning-of-block screen

% display prompt
if condition == 1 % attend to audio
    DrawFormattedText(window, ['Please pay attention only to the AUDIO\n\n\n\n' ...
                                'In this part of the experiment you will hear a section of an audiobook. ' ...
                                'Your task is to listen\n\n' ...
                                'Ignore any visual stimulation on screen. Simply continue to fixate at the centre of the screen\n\n' ...
                                'Sometimes a sentence in the audiobook will be repeated\n\n' ...
                                'As soon as you hear a repeat, press either the LEFT or RIGHT arrow key (place your fingers over these keys now)\n\n' ...
                                'Press any key to continue'], 'center', 'center', white);
else % attend to visual
    DrawFormattedText(window, ['Please pay attention only to the VISUAL task\n\n\n\n' ...
                                'You will see a collection of white dots appear on the screen. ' ...
                                'Some of the dots will briefly flash red\n\n' ...
                                'All of the dots will then start to move\n\n' ...
                                'Your task is to track the dots that flashed red, using your peripheral vision\n\n' ...
                                'Continue to fixate on the centre of the screen during this time\n\n' ...
                                'After a short period, all the dots will stop moving and one dot will turn green\n\n' ...
                                'You will be asked if this dot was one of the red dots you were asked to track\n\n' ...
                                'Answer using the LEFT or RIGHT arrow keys (place your fingers over these keys now)\n\n\n\n' ...
                                'Ignore any audio throughout, focusing only on the visual task\n\n\n\n' ...
                                'Press any key to continue'], 'center', 'center', white);
end
Screen('Flip', window);
% wait for key press
KbStrokeWait;

%% Final reminder to participant

% display prompt
DrawFormattedText(window, ['The experiment will begin on the next screen\n\n\n\n'...
                            'Remember:\n\n'...
                            '- Fixate on the centre of the screen during each trial\n\n' ...
                            '- Try not to blink during each trial\n\n'...
                            '- Stay as still as possible\n\n\n\n' ...
                            'Press any key to begin'], 'center', 'center', white);
Screen('Flip', window);
% wait for key press
KbStrokeWait;

%% Send initial triggers
IOPort('Write',handle,triggerEEGOnset); % start EEG recording
WaitSecs(0.3);

% Attention Condition
if condition == 1 % audio
    IOPort('Write',handle,triggerConditionAudio);
else              % visual
    IOPort('Write',handle,triggerConditionVisual);
end
WaitSecs(0.3);

% Chapter
if chapter == 1
    IOPort('Write',handle,triggerChapter1);
elseif chapter == 2
    IOPort('Write',handle,triggerChapter2);
elseif chapter == 3
    IOPort('Write',handle,triggerChapter3);
elseif chapter == 4
    IOPort('Write',handle,triggerChapter4);
elseif chapter == 5
    IOPort('Write',handle,triggerChapter5);
else
    IOPort('Write',handle,triggerChapter6);
end
WaitSecs(0.3);

% MOT Load
if MOTLoad == 1
    IOPort('Write',handle,triggerMOTLoadLow);
else
    IOPort('Write',handle,triggerMOTLoadHigh);
end

%% Trial loop here

% Fill the audio playback buffer with the audio data, doubled for stereo presentation
PsychPortAudio('FillBuffer', pahandle, audioCurrent);
WaitSecs(0.3);

% Start audio playback
tStartSoundCurrent = PsychPortAudio('Start', pahandle, 1, 0, waitForDeviceStart);

% Send EEG trigger at sound onset
IOPort('Write',handle,triggerSpeechOnset);

% Start listening for key presses
%[keyboardIndices, productNames, allInfos] = GetKeyboardIndices();
KbQueueCreate();
KbQueueStart();

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
    if MOTLoad == 1 % low load
        ixtar = ixr(1:2);
        ixdis = ixr(3:end);
    else            % high load
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

    % Send trigger at MOT onset
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
    % Send trigger at MOT offset
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
    
    if condition == 2 % visual
        % get response
        respToBeMade = true; 
        while respToBeMade == true
            % draw response screen
            DrawFormattedText(window, ['Was the green dot one of the ones you were asked to track?\n\n\n' ...
                                        'Yes (LEFT) ................... No (RIGHT)'], 'center', 'center', white);
            % flip to the screen
            Screen('Flip', window);
            % check the keyboard
            [~,keyCode] = KbWait;
            if keyCode(escapeKey)
                ShowCursor;
                sca;
                PsychPortAudio('Close', pahandle);                
                return
            elseif keyCode(leftKey)
                % send trigger at response
                IOPort('Write',handle,triggerResponseOnset);
                response = 1;
                respToBeMade = false;
            else
                % send trigger at response
                IOPort('Write',handle,triggerResponseOnset);
                response = 0;
                respToBeMade = false;
            end       
        end
        
        if response == tarSeq(trial)
            succTrial = 1;
        else
            succTrial = 0;
        end

        % Clear screen
        Screen('FillRect', window,bgcolor);
        Screen('FillRect', window,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box
        Screen('Flip', window);
        
        % Collect trial data
        data(1+trial,:) = [{subject},{block},{condition},{MOTLoad},{chapter},{tarSeq(trial)},{response},{succTrial},{tStartSoundCurrent},{MOTOnset},{MOTOffset}];

        % Calculate accuracy
        accRate = round(mean(cellfun(@mean, data(2:end,7)))*100,1);

        % Wait for a bit before showing written feedback
        WaitSecs(0.5);

        % Draw feedback text
        if response == tarSeq(trial)
            DrawFormattedText(window, 'Correct', 'center', 'center', white);
            IOPort('Write',handle,triggerFeedbackOnset);
        else
            DrawFormattedText(window, 'Incorrect', 'center', 'center', white);
            IOPort('Write',handle,triggerFeedbackOnset);
        end
        % flip to the screen
        Screen('Flip', window);
        % Wait for ITI before next trial
        WaitSecs(1+ITIcurrent);
        
    else        % Auditory only
        % Clear screen
        Screen('FillRect', window,bgcolor);
        Screen('FillRect', window,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box
        Screen('Flip', window);
        response = 0; % no response to trial, not doing visual task
        succTrial = 0; % no success or failure, not doing visual task

        % Wait for ITI before next trial
        WaitSecs(3+ITIcurrent);

        % Check if any key was pressed
        [pressed, ~, ~, lastPressTimes] = KbQueueCheck();
        if pressed
            % Find the last key press (if multiple keys were pressed)
            keyPressTime = max(lastPressTimes(lastPressTimes > 0)); % Only non-zero times
            repeatsCurrentTime = keyPressTime - tStartSoundCurrent;
            repeatsKeyPresses = [repeatsKeyPresses; repeatsCurrentTime];
            % Calculate accuracy of repeat detection
            if any(repeatsCurrentTime >= repeatsChapter & repeatsCurrentTime <= repeatsChapter + repeatsRange)
                repeatsCorrect = 1;
            else
                repeatsCorrect = 0;
            end
            fprintf('Key pressed at %d seconds into chapter. Correct: %d\n',repeatsCurrentTime,repeatsCorrect);
        end
        KbQueueFlush(); % clear all key presses from queue

        % Collect trial data
        data(1+trial,:) = [{subject},{block},{condition},{MOTLoad},{chapter},{tarSeq(trial)},{response},{succTrial},{tStartSoundCurrent},{MOTOnset},{MOTOffset}];
    end

    % Clear screen
    Screen('FillRect', window,bgcolor);
    Screen('FillRect', window,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box
    Screen('Flip', window);

    % Display progress to experimenter
    fprintf('Trial %d: Target %d, Response %d...\n',trial,tarSeq(trial),response);
end

% Stop audio playback
[~,~,~,tEndSoundCurrent] = PsychPortAudio('Stop',pahandle);
% Send trigger at sound offset
IOPort('Write',handle,triggerSpeechOffset);

KbQueueStop(); % Stop listening for key presses

%% End of block screen
if condition == 2 % visual
    DrawFormattedText(window, ['Accuracy: ' num2str(accRate) '%\n\n\n***END OF BLOCK***'], 'center', 'center', white);
else
    DrawFormattedText(window, '***END OF BLOCK***', 'center', 'center', white);
end
Screen('Flip', window);
WaitSecs(3);
IOPort('Write',handle,triggerEEGOffset);

%% Calculate hits and false alarms for audio condition
if condition == 1
    % Deal with possibly different sized arrays
    lenKP = length(repeatsKeyPresses);
    lenC = length(repeatsChapter);
    if lenKP > lenC
        repeatsChapter = [repeatsChapter; NaN(lenKP - lenC, 1)];
    elseif lenC > lenKP
        repeatsKeyPresses = [repeatsKeyPresses; NaN(lenC - lenKP, 1)];
    end
    repeatsAccuracy = [repeatsKeyPresses, repeatsChapter'];
    % Save repeats data for audio condition
    repeatsSave = ['repeats_subj' num2str(subject) '_b' num2str(block) '.mat'];
    save(repeatsSave,'repeatsKeyPresses', 'repeatsChapter', 'repeatsAccuracy', 'chapter', 'MOTLoad');
end

%% Shut down and save data
dw_ptb_close;
IOPort('CloseAll');

%% Note when script finished
tExpDur = toc(tExpStart)/60;
fprintf('\nTime taken = %f minutes\n',tExpDur);
