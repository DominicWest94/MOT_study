clear all
format compact
direxp = '/Users/dominicwest/Documents/Uni/PhD/MATLAB/Speech_processing_attention';
cd(direxp)
addpath(genpath('MATLAB'))

% parameters
nMovies   = 60;

frameRate = 60;
frameTime = 1/frameRate;
trackSize = [500 500]; % screen size
trackDur  = 10; % length of stimuli in seconds
movieLength = round(trackDur / frameTime)+1; % length of stim in frames

numDots   = 16; % total # of objects
objSize   = 14; % radius of the objects (16 ~ 1deg)
angleSD   = 10; % standard deviation of motion perturbations that occur each frame
objBuffer = 24; % distance in pixels around an object that another object cannot enter
speed     = 1.5;  % frames per second
w         = 0;  % do not make a gif


% build movies
for ii = 1 : nMovies
	[~, locs] = MOTmovie(movieLength,numDots,trackSize,speed,angleSD,objSize,objBuffer,w);
	fname = ['Stimuli/MOTlocs/Sc' num2str(trackSize(1)) '-' num2str(trackSize(2)) '_L' num2str(trackDur) '_R' num2str(frameRate) '_nD' num2str(numDots) '_S' num2str(objSize) '_A' num2str(angleSD) '_B' num2str(objBuffer) '_Sp' num2str(speed) '_stim' num2str(ii) '.mat'];
	locs  = squeeze(locs);
	save(fname,'locs')
	
	if mod(ii,10)==0
		disp(['Movie No. ' num2str(ii) ' done.'])
	end
end


