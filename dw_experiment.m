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
nTrials = 30;

load('blockOrder.mat')
% Find the row index, assign Condition, MOTLoad and Chapter
rowIndx = find([blockOrder{2:end,1}] == subject & [blockOrder{2:end,2}] == block) + 1;
condition = blockOrder{rowIndx,3};
MOTLoad = blockOrder{rowIndx,4};
chapter = blockOrder{rowIndx,5};

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
speed     = 0.8; % check if this is correct
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
oneKey = KbName('1');
twoKey = KbName('2');
threeKey = KbName('3');
fourKey = KbName('4');

%% Initialise EEG triggers

% configure serial port for triggers
[handle, errmsg] = IOPort('OpenSerialPort', 'COM3', ' BaudRate=115200 DataBits=8 StopBits=1 Parity=None');

triggerEEGOnset = uint8(255);
triggerEEGOffset = unint8(250);
triggerConditionAudio = unint8(95);
triggerConditionVisual = unint8(105);
triggerMOTLoadHigh = unint8(115);
triggerMOTLoadLow = unint8(125);
triggerChapter1 = unint8(135);
triggerChapter2 = unint8(145);
triggerChapter3 = unint8(155);
triggerChapter4 = unint8(165);
triggerChapter5 = unint8(175);
triggerChapter6 = unint8(185);
triggerSpeechOnset = unint8(195);
triggerSpeechOffset = uint8(205);
triggerResponseOnset = uint8(215);
triggerFeedbackOnset = unit8(225);
triggerMOTOnset = uint8(235);
triggerMOTOffset = uint8(245);

%% Select and randomise stimuli

% Generate random sequence of 1s and 0s for dot selection; 1 - target selected, 0 - target not selected
randOrder = randperm(nTrials);
tarSeq = mod(randOrder, 2);

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

%% Present intro screen to participant

% display prompt
DrawFormattedText(window, ['Please fixate on the point at the centre of the screen during the task\n\n'...
                            'Try not to blink - trials will last 10 seconds so you can blink between trials\n\n'...
                            'Try to keep as still as possible throughout\n\n\n\n' ...
                            'To answer any questions, you will need to use the LEFT and RIGHT arrow keys and numbers 1 to 4\n\n'...
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
                                'Ignore any visual stimulation, but continue to fixate at the centre of the screen\n\n' ...
                                'You will occasionally be asked questions about the audiobook\n\n' ...
                                'Answer these questions using the number keys, from 1 to 4' ...
                                'Press any key to continue'], 'center', 'center', white);
else % attend to visual
    DrawFormattedText(window, ['Please pay attention only to the VISUAL stimulation\n\n\n\n' ...
                                'You will see multiple white dots appear on the screen\n\n' ...
                                'Some of the dots will briefly flash red\n\n' ...
                                'All of the dots will then start to move\n\n' ...
                                'Your task is to track the dots that flashed red, using your peripheral vision\n\n' ...
                                'Continue to fixate on the centre of the screen\n\n' ...
                                'After a short period, all the dots will stop moving and one dot will turn green\n\n' ...
                                'You will be asked if this dot was one of the red dots you were asked to track\n\n\n\n' ...
                                'Answer using the LEFT or RIGHT arrow keys' ...
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
                            '- Fixate on the cross at the centre of the screen during each trial\n\n' ...
                            '- Try not to blink during each trial\n\n'...
                            '- Stay as still as possible\n\n\n\n' ...
                            'Press any key to begin'], 'center', 'center', white);
Screen('Flip', window);
% wait for key press
KbStrokeWait;

%% Send initial triggers
IOPort('Write',handle,triggerEEGOnset); % start EEG recording
WaitSecs(0.5);

% Attention Condition
if condition == 1 % audio
    IOPort('Write',handle,triggerConditionAudio);
else              % visual
    IOPort('Write',handle,triggerConditionVisual);
end
WaitSecs(0.5);

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
WaitSecs(0.5);

% MOT Load
if MOTLoad == 1
    IOPort('Write',handle,triggerMOTLoadLow);
else
    IOPort('Write',handle,triggerMOTLoadHigh);
end

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
    WaitSecs(1);

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
        Screen('FillRect',window,black);
        Screen('Flip', window);
        
        % Collect data
        data(1+trial,:) = [{subject},{block},{condition},{chapter},{tarSeq(trial)},{response},{succTrial},{tStartSoundCurrent},{MOTOnset},{MOTOffset}];

        % Calculate accuracy
        accRate = round(mean(cellfun(@mean, data(2:end,7)))*100,1);

        % Wait for a bit before showing written feedback
        WaitSecs(0.5);

        % Draw feedback text
        if response == tarSeq(trial)
            if mod(trial,5) == 0
                DrawFormattedText(window, ['Correct\n\n\nAccuracy: ' num2str(accRate) '%'], 'center', 'center', white);
                IOPort('Write',handle,triggerFeedbackOnset);
            else
                DrawFormattedText(window, 'Correct', 'center', 'center', white);
                IOPort('Write',handle,triggerFeedbackOnset);
            end
        else
            if mod(trial,5) == 0
                DrawFormattedText(window, ['Incorrect\n\n\nAccuracy: ' num2str(accRate) '%'], 'center', 'center', white);
                IOPort('Write',handle,triggerFeedbackOnset);
            else
                DrawFormattedText(window, 'Incorrect', 'center', 'center', white);
                IOPort('Write',handle,triggerFeedbackOnset);
            end
        end
        % flip to the screen
        Screen('Flip', window);
        WaitSecs(1);
        
    else        % Auditory only
        if mod(trial,5) == 0
            respToBeMade = true;
            while respToBeMade == true
                % draw response screen
                DrawFormattedText(window, ['How many characters, in total, have spoken in the last 60 seconds?\n\n\n' ...
                                           'Answer using the number keys:' ...
                                           '1   2   3   4'], 'center', 'center', white);
                % flip to the screen
                Screen('Flip', window);
                % check the keyboard
                [~,keyCode] = KbWait;
                if keyCode(escapeKey)
                    ShowCursor;
                    sca;
                    PsychPortAudio('Close', pahandle);
                    return
                elseif keyCode(oneKey)
                    % send trigger at response
                    IOPort('Write',handle,triggerResponseOnset);
                    response = 1;
                    respToBeMade = false;
                elseif keyCode(twoKey)
                    % send trigger at response
                    IOPort('Write',handle,triggerResponseOnset);
                    response = 2;
                    respToBeMade = false;
                elseif keyCode(threeKey)
                    % send trigger at response
                    IOPort('Write',handle,triggerResponseOnset);
                    response = 3;
                    respToBeMade = false;
                else
                    % send trigger at response
                    IOPort('Write',handle,triggerResponseOnset);
                    response = 4;
                    respToBeMade = false;
                end       
            end
        else
            response = 0; % no response needed
        end
        succTrial = 0; % auditory only, so no 'success' rate

        % Collect data
        data(1+trial,:) = [{subject},{block},{condition},{MOTLoad},{chapter},{tarSeq(trial)},{response},{succTrial},{tStartSoundCurrent},{MOTOnset},{MOTOffset}];

    end

    % Clear screen
    Screen('FillRect',window,black);
    Screen('Flip', window);

    % Wait for ITI before next trial
    WaitSecs(ITIcurrent);

    % Display progress to experimenter
    fprintf('Trial %d: Target %d, Response %d...\n',trial,tarSeq(trial),response);
end

% Stop audio playback
[~,~,~,tEndSoundCurrent] = PsychPortAudio('Stop',pahandle,1);
% Send trigger at sound offset
IOPort('Write',handle,triggerSpeechOffset);

%% End of block screen
DrawFormattedText(window, '***END OF BLOCK***','center', 'center', white);
Screen('Flip', window);
WaitSecs(4);
IOPort('Write',handle,triggerEEGOffset);

%% Shut down and save data
dw_ptb_close;
IOPort('CloseAll');

%% Note when script finished
tExpDur = toc(tExpStart)/60;
fprintf('\nTime taken = %f minutes\n',tExpDur);
