%trimming.m
%this script takes raw data .csv files (pupil, accuracy, speed data) and cuts out the first 30 seconds
%and anything past 210 seconds (ie: cuts the data down to 3 minutes). It
%then saves the trimmed data in a new .csv file with matching column
%headers (so compatible with existing filtering/pre-processing script (not included in this repository)


thesisDataAnalysisSettings;  % call script with directories/variables
    %defines startKeepTime, endTimeLow, and endTimeHigh
    %defines rawFixedSpeedFileNames

%Time frame to keep is defined in thesisDataAnalysisSettings
    %startKeepTime = time frame from beginning to cut out
    %endTimeLow = time to cut from there on (low range) xxxxx0
    %endTimeHigh = time to cut from there on (high range) xxxxx9
        %below will find first ms time between endTimeLow and endTimeHigh and cut from there on

rootDir = rawDataFolderDir;


%select subjects to process using selectSubject function and prompt for
%input
subjInput = input('Enter subject IDs (ie H1, S5...) or press Enter to select all: ', 's');
if isempty(subjInput)
    [selectedSubjects, subjectMap] = selectSubject();  % all subjects
else
    subjInputFormatted = strsplit(strrep(subjInput, ' ', ''), ',');
        %strsplit splits by spaces
    [selectedSubjects, subjectMap] = selectSubject(subjInputFormatted);  % specific ones
end

for i = 1:length(selectedSubjects)
    subjectID = selectedSubjects{i};
    subjectName = subjectMap(subjectID);
    subjectFolder = fullfile(rootDir, subjectName, 'Raw Logs');

    outputFolder = fullfile(rootDir, subjectName, 'Logs');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    %rawFixedSpeedFileNames defined in thesisDataAnalysis
    
    eyeHeaderLine = 'DateTime,Milliseconds,Car X,Car Y,Gaze X,Gaze Y,IsInGazeArea?,Pupil Diameter(mm),Chosen Palette,Spawn Time Between Palettes';
        %so it can put the same exact headers back on the cut down eye log files
    kinematicHeaderLine = 'DateTime,Milliseconds,PalmPosX,PalmPosY,PalmPosZ,PalmNormalX,PalmNormalY,PalmNormalZ,WristPosX,WristPosY,WristPosZ,Pitch,Yaw,Roll,HandOpen,ThumbMetacarpalX,ThumbMetacarpalY,ThumbMetacarpalX, ThumbProximalX,ThumbProximalY,ThumbProximalZ,ThumbIntermediateX,ThumbIntermediateY,ThumbIntermediateZ,ThumbDistalX,ThumbDistalY,ThumbDistalZ,ThumbTipX,ThumbTipY,ThumbTipZ,IndexMetacarpalX,IndexMetacarpalY,IndexMetacarpalZ,IndexProximalX,IndexProximalY,IndexProximalZ,IndexIntermediateX,IndexIntermediateY,IndexIntermediateZ,IndexDistalX,IndexDistalY,IndexDistalZ,IndexTipX,IndexTipY,IndexTipZ,MiddleMetacarpalX,MiddleMetacarpalY,MiddleMetacarpalZ,MiddleProximalX,MiddleProximalY,MiddleProximalZ,MiddleIntermediateX,MiddleIntermediateY,MiddleIntermediateZ,MiddleDistalX,MiddleDistalY,MiddleDistalZ,MiddleTipX,MiddleTipY,MiddleTipZ,RingMetacarpalX,RingMetacarpalY,RingMetacarpalZ,RingProximalX,RingProximalY,RingProximalZ,RingIntermediateX,RingIntermediateY,RingIntermediateZ,RingDistalX,RingDistalY,RingDistalZ,RingTipX,RingTipY,RingTipZ,PinkyMetacarpalX,PinkyMetacarpalY,PinkyMetacarpalZ,PinkyProximalX,PinkyProximalY,PinkyProximalZ,PinkyIntermediateX,PinkyIntermediateY,PinkyIntermediateZ,PinkyDistalX,PinkyDistalY,PinkyDistalZ,PinkyTipX,PinkyTipY,PinkyTipZ,SpeedMultiplier,AttemptedOpen,SuccessfulOpen,FailedOpen,AttemptedClose,SuccessfulClose,FailedClose,RollActions,TotalObjects,Accuracy,CalibratedOpen,CalibratedClose,CalibratedPronation,CalibrationSupination';
        %so it can put the same exact headers back on the cut down kinematics file
  
    
    %for all 10 raw log files:
    for f = 1:length(rawFixedSpeedFileNames)
        inputFile = fullfile(subjectFolder, rawFixedSpeedFileNames{f});
        newFile = fullfile(outputFolder, strrep(rawFixedSpeedFileNames{f}, 'raw', ''));
            %make new file names without _raw
      
        dataTable = readtable(inputFile, 'HeaderLines', 1);
             %so now it only looks at from row 2 on:
    
        Milliseconds = dataTable{:, 2};
            %ms are always in column 2
    
        %cut out first 30 seconds:
        cutData = dataTable(Milliseconds > startKeepTime, :);
        
        % cut everything at and after the first ms value that starts with '21051'
        msThirtySecOn = cutData{:, 2}; %2nd column
        %msStr = string(msThirtySecOn);  % convert ms column to a string array msStr so can look for 21051x
            %no longer need to convert to string
        
        % Find first match that starts with '21051' (i.e., 210510–210519)
        cutIDx = find(msThirtySecOn >= endTimeLow & msThirtySecOn <= endTimeHigh, 1, 'first');
            %finds the first row where ms column has a value above 210510 (ie: 210.5 seconds- exact 6th digit varies from dataset to dataset)-
            % there is generally always a 21051x number in the ms column, but just in case there's not the upper range is there- 
            % if no matching number it saves cutIDx as an empty array, which
            % will give an error below
        
      
        
        if ~isempty(cutIDx) %if found a 21051_ match (~ means not)
            % then only keep only rows before it
            cutData = cutData(1:cutIDx - 1, :);
                %keep all columns only from row 1 to the row before the match (ie -1)
        else
            error('no matching 21051x ms #')
        end
    
         writetable(cutData, newFile, 'WriteVariableNames', false);
    
      %tell it which first row to assign to the new file
        if contains(rawFixedSpeedFileNames{f}, 'EyeLog')
            expectedHeaders = eyeHeaderLine;
        elseif contains(rawFixedSpeedFileNames{f}, 'KinematicLog')
            expectedHeaders = kinematicHeaderLine;
        end
    
        fileText = fileread(newFile);
        
        fid = fopen(newFile, 'w');
        fprintf(fid, '%s\n', expectedHeaders);
        fprintf(fid, '%s', fileText);
        fclose(fid);
    
    end
end

