%% For screen

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens=Screen('Screens'); % USE THIS LINE FOR EXPERIMENT
% screens=Screen('Preference', 'SkipSyncTests', 1); % ONLY USE THIS LINE WHEN DEBUGGING

% Makes it so characters typed don't show up in the command window
%ListenChar(2);

% Hides the cursor
%HideCursor();

% Select screen
screenNumber = max(screens);
% screenNumber = 1;

% Define black, white and grey
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
grey = white / 2;

% Open an on screen window and color it black
if debugMode; PsychDebugWindowConfiguration(0,0.5); end
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Set the maximum priority number
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Get the size of the on screen window in pixels
% For help see: Screen WindowSize?
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Define text size and font
textSize = 20;
Screen('TextSize', window, textSize);
Screen('TextFont', window, 'Arial');
Screen('TextStyle', window, 1);

%% For sound

% Initialize Sounddriver
InitializePsychSound(1);

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;

% Open Psych-Audio port, with the follow arguments
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
pahandle = PsychPortAudio('Open', [], 1, 1, [], nrchannels);

% Set the volume to half
%PsychPortAudio('Volume', pahandle, 0.5);