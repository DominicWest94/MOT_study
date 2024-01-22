clear all


sca;                                             % close all screens
screens      = Screen('Screens');                % get all screens available
screenNumber = max(screens);                     % present stuff on the last screen
Screen('Preference', 'SkipSyncTests', 1);
white = WhiteIndex(screenNumber);              % get white given the screen used
black = BlackIndex(screenNumber);

bgcolor = 0;

[shandle, wRect] = Screen('Openwindow', screenNumber, bgcolor, [], [], 2);
	slack = Screen('GetFlipInterval', shandle)/2;
	W = wRect(RectRight); % screen width
	H = wRect(RectBottom); % screen height
	Screen(shandle,'FillRect',bgcolor);
	Screen('Flip', shandle);


trackSize = [700 700];

rect = Screen('Rect',shandle);
xMid = rect(3)/2;
yMid = rect(4)/2;
trackRect = [xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2];

objSize   = 14;
fixSize   = 4;      % size of the fixation box (well, half of it - the distance from the middle to edge horizontally/vertically)
qFrame    = 1;      % width of frame around each tracking quadrant
fixCol    = [255 255 0]; % color of fixation box
frameCol  = [128 128 128];
tarCol    = [255 0 0];
taskCol   = [0 255 0];
nTargets  = 4;

screenSf = Screen('NominalFrameRate',shandle); % screen refresh rate
screenDT = 1/screenSf;                         % delta t of the refresh rate


Screen('FillRect',shandle, black,[xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2]);
    
load('C:\Users\dsw27\Documents\MATLAB\MOTlocs\Sc500-500_L5_R75_nD16_S14_A10_B24_Sp1.5_stim1.mat')

% get all dot positions for the trial
dotPos = cat(1,locs(1,:,:)+trackRect(1)-objSize, locs(2,:,:)+trackRect(2)-objSize, locs(1,:,:)+trackRect(1)+objSize, locs(2,:,:)+trackRect(2)+objSize);

% get target and distractor indices
[~,ixr] = sort(rand([1 size(dotPos,2)]));
ixtar = ixr(1:nTargets);
ixdis = ixr(nTargets+1:end);

% draw which dots to track
Screen('FillRect', shandle,bgcolor);
Screen('FillRect', shandle,black,[xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2]);
Screen('FillOval', shandle, white, dotPos(:,ixdis,1), objSize);
Screen('FillOval', shandle, tarCol, dotPos(:,ixtar,1), objSize);
Screen('FrameRect', shandle,frameCol,trackRect,qFrame); % drawn frame around the dot area
Screen('FillRect', shandle,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box
Screen('Flip', shandle);
WaitSecs(1);

% present movie
flipTime = Screen('Flip', shandle);
for fi = 1 : size(dotPos,3)
	Screen('FillRect',shandle,bgcolor);
	Screen('FillRect',shandle,black,[xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2]);

	Screen('FillOval', shandle, white, dotPos(:,:,fi), objSize);
	Screen('FrameRect', shandle,frameCol,trackRect,qFrame); % drawn frame around the dot area
	Screen('FillRect', shandle,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box

	flipTime(fi) = Screen('Flip', shandle, flipTime(end) + screenDT - slack,0);
end

tarTracked = 0;

% which dot to highlight for the task
if tarTracked == 1
	[~,ixr] = sort(rand([1 length(ixtar)]));
	ixmark  = ixtar(ixr(1));
else
	[~,ixr] = sort(rand([1 length(ixdis)]));
	ixmark  = ixdis(ixr(1));
end

% get colored dot drawn for the task
Screen('FillRect', shandle,bgcolor);
Screen('FillRect', shandle,black,[xMid-trackSize(1)/2,yMid-trackSize(2)/2,xMid+trackSize(1)/2,yMid+trackSize(2)/2]);
Screen('FillOval', shandle, white, dotPos(:,~ismember(1:size(dotPos,2),ixmark),end), objSize);
Screen('FillOval', shandle, taskCol, dotPos(:,ismember(1:size(dotPos,2),ixmark),end), objSize);
Screen('FrameRect', shandle,frameCol,trackRect,qFrame); % drawn frame around the dot area
Screen('FillRect', shandle,fixCol,[xMid-fixSize,yMid-fixSize,xMid+fixSize,yMid+fixSize]); % draw fixation box
Screen('Flip', shandle);



WaitSecs(1)
sca
