rootDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/RawData/';

allRawDataFolder = dir(rootDir); %pulls everything from the raw data folder (folders and files) --> structure array
subjectFolders = allRawDataFolder([allRawDataFolder.isdir]); 
    %isdir gets rid of files and just keeps folders (aka directories)
subjectFolders = subjectFolders(~ismember({subjectFolders.name}, {'.', '..'}));
    %gets rid of 'system entry' folders so just takes subject folders
    %pulls the name of each subject folder to display below

subjectList = {subjectFolders.name};

%lists all subjects numbered
for i = 1:length(subjectList)
    fprintf('%2d: %s\n', i, subjectList{i});
        %%2d=right aligned # labeling each subject
        %s = string = folder name (subjectsFolders)
        %\n = new line
end

%pick which subject from the numbered list
subjectIndex = input('\nWhich subject?');
subjectName = subjectFolders(subjectIndex).name; %pulls folder name for selected subject

subjectFolder = fullfile(rootDir, subjectName, 'Raw Logs');


fileNames = {
    'Trial4raw_EndlessCarKinematicLog.csv'; 'Trial5raw_EndlessCarKinematicLog.csv'; ...
    'Trial6raw_EndlessCarKinematicLog.csv'; 'Trial7raw_EndlessCarKinematicLog.csv'; ...
    'Trial8raw_EndlessCarKinematicLog.csv'; 'Trial4raw_EndlessCarEyeLog.csv'; ...
    'Trial5raw_EndlessCarEyeLog.csv'; 'Trial6raw_EndlessCarEyeLog.csv'; ...
    'Trial7raw_EndlessCarEyeLog.csv'; 'Trial8raw_EndlessCarEyeLog.csv'};

eyeHeaderLine = 'DateTime,Milliseconds,Car X,Car Y,Gaze X,Gaze Y,IsInGazeArea?,Pupil Diameter(mm),Chosen Palette,Spawn Time Between Palettes';
    %so it can put the same exact headers back on the cut down eye log files
kinematicHeaderLine = 'DateTime,Milliseconds,PalmPosX,PalmPosY,PalmPosZ,PalmNormalX,PalmNormalY,PalmNormalZ,WristPosX,WristPosY,WristPosZ,Pitch,Yaw,Roll,HandOpen,ThumbMetacarpalX,ThumbMetacarpalY,ThumbMetacarpalX, ThumbProximalX,ThumbProximalY,ThumbProximalZ,ThumbIntermediateX,ThumbIntermediateY,ThumbIntermediateZ,ThumbDistalX,ThumbDistalY,ThumbDistalZ,ThumbTipX,ThumbTipY,ThumbTipZ,IndexMetacarpalX,IndexMetacarpalY,IndexMetacarpalZ,IndexProximalX,IndexProximalY,IndexProximalZ,IndexIntermediateX,IndexIntermediateY,IndexIntermediateZ,IndexDistalX,IndexDistalY,IndexDistalZ,IndexTipX,IndexTipY,IndexTipZ,MiddleMetacarpalX,MiddleMetacarpalY,MiddleMetacarpalZ,MiddleProximalX,MiddleProximalY,MiddleProximalZ,MiddleIntermediateX,MiddleIntermediateY,MiddleIntermediateZ,MiddleDistalX,MiddleDistalY,MiddleDistalZ,MiddleTipX,MiddleTipY,MiddleTipZ,RingMetacarpalX,RingMetacarpalY,RingMetacarpalZ,RingProximalX,RingProximalY,RingProximalZ,RingIntermediateX,RingIntermediateY,RingIntermediateZ,RingDistalX,RingDistalY,RingDistalZ,RingTipX,RingTipY,RingTipZ,PinkyMetacarpalX,PinkyMetacarpalY,PinkyMetacarpalZ,PinkyProximalX,PinkyProximalY,PinkyProximalZ,PinkyIntermediateX,PinkyIntermediateY,PinkyIntermediateZ,PinkyDistalX,PinkyDistalY,PinkyDistalZ,PinkyTipX,PinkyTipY,PinkyTipZ,SpeedMultiplier,AttemptedOpen,SuccessfulOpen,FailedOpen,AttemptedClose,SuccessfulClose,FailedClose,RollActions,TotalObjects,Accuracy,CalibratedOpen,CalibratedClose,CalibratedPronation,CalibrationSupination';
    %so it can put the same exact headers back on the cut down kinematics file

    outputFolder = fullfile(rootDir, subjectName, 'Logs');
%if Logs folder doesn't already exist there, make one:
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%Time range to cut out: first 30 seconds
startKeepTime = 29999;

%endKeepTime = 210515; 

%for all 10 raw log files:
for i = 1:length(fileNames)
    inputFile = fullfile(subjectFolder, fileNames{i});
    newFile = fullfile(outputFolder, strrep(fileNames{i}, 'raw', ''));
        %make new file names without _raw
  
    dataTable = readtable(inputFile, 'HeaderLines', 1);
         %so now it only looks at from row 2 on:

    Milliseconds = dataTable{:, 2};
        %ms are always in column 2

    %cut out first 30 seconds:
    cutData = dataTable(Milliseconds > startKeepTime, :);
    
    % cut everything at and after the first ms value that starts with '21051'
    msThirtySecOn = cutData{:, 2}; %2nd column
    msStr = string(msThirtySecOn);  % convert ms column to a string array msStr so can look for 21051x
    
    % Find first match that starts with '21051' (i.e., 210510–210519)
    cutIdx = find(startsWith(msStr, '21051'), 1);
        %checks each number to see if it starts with 21051 and assigns true or false
        % , 1 --> return the first 'true' match
    
    if ~isempty(cutIdx) %if found a 21051_ match
        % then only keep only rows before it
        cutData = cutData(1:cutIdx - 1, :);
            %keep all columns only from row 1 to the row before the match (ie -1)
    end

     writetable(cutData, newFile, 'WriteVariableNames', false);

  %tell it which first row to assign to the new file
    if contains(fileNames{i}, 'EyeLog')
        expectedHeaders = eyeHeaderLine;
    elseif contains(fileNames{i}, 'KinematicLog')
        expectedHeaders = kinematicHeaderLine;
    end

    fileText = fileread(newFile);
    
    fid = fopen(newFile, 'w');
    fprintf(fid, '%s\n', expectedHeaders);
    fprintf(fid, '%s', fileText);
    fclose(fid);

end

