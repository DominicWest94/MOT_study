%% Define constants
nParticipants = 40;
nBlocks = 6;
Chapters = 6;
Conditions = [1 2 2]; % 1 - auditory, 2 - visual

%% Build block order
% Create cell arrays to store the order of blocks for each participant
blockOrder = {'Subject','Block','Condition','MOT Load','Chapter'};

% Loop for each participant
for participant = 1:nParticipants

    %% First half of session
    % Create inital Condition order for first half session
    halfSessionA = Conditions';

    if mod(participant,2) == 0 % make Auditory Condition low load if participant number is even
        halfSessionA(1,2) = 1;
    else
        halfSessionA(1,2) = 2;
    end

    % Add low and high MOT loads to two Visual Conditions
    halfSessionA(2,2) = 1;
    halfSessionA(3,2) = 2;
    
    % Shuffle order of blocks
    halfSessionA = halfSessionA(randperm(size(halfSessionA,1)),:);

    %% Second half of session
    % Create random Condition order for second half session
    halfSessionB = Conditions';

    if mod(participant,2) == 0 % make Auditory Condition high load if participant number is even
        halfSessionB(1,2) = 2;
    else
        halfSessionB(1,2) = 1;
    end

    % Add low and high MOT loads to two Visual Conditions
    halfSessionB(2,2) = 1;
    halfSessionB(3,2) = 2;
    
    % Shuffle order of blocks
    halfSessionB = halfSessionB(randperm(size(halfSessionB,1)),:);

    %% Concatonate to full session

    fullSession = cat(1,halfSessionA, halfSessionB); % concatonate arrays for full session

    randChapters = randperm(Chapters)'; % randomise chapters
    fullSession(:,3) = randChapters; % assign chapter numbers to full session

    %% Add to blockOrder cell array
    blockOrder(participant*6-4:participant*6+1,3) = num2cell(fullSession(:,1)); % add Conditions
    blockOrder(participant*6-4:participant*6+1,4) = num2cell(fullSession(:,2)); % add MOT Loads
    blockOrder(participant*6-4:participant*6+1,5) = num2cell(fullSession(:,3)); % add Chapters
    blockOrder(participant*6-4:participant*6+1,2) = num2cell(1:6);              % add Block numbers
    blockOrder(participant*6-4:participant*6+1,1) = num2cell(participant);

end

% Save the cell array
fname = 'blockOrder.mat';
save(fname, 'blockOrder');
