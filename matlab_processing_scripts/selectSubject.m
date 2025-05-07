function [selectedSubjects, subjectMap] = selectSubject(subjects)
    %this function allows user to input what subjects to select (or to run all subjects)
    %subject IDs are listed for all existing subject folders
        %nested createSubjectIDMap function pulls all subject folders and assigns simple subject IDs   
    %creates selectedSubjects array 
        %(to be looped through in trimming.m and extractall.m)

    arguments
        subjects cell = {} %optional- if want to specify specific subjects to process
end

    subjectMap=createSubjectIDMap();
        %pulls in subject ID directory from createSubjectIDMap (which defines
        %their location and linked subject ID
    
    if isempty(subjects)
        selectedSubjects = keys(subjectMap);
            % If don't specify input for subjects, get all subject folders automatically
    else %if you do specify subjects, then:
            availableSubjects = keys(subjectMap);
                %keys = all subject IDs from the containers.Map used in
                %createSubjectIDMap function
                %vs value, which would be the folder name 
            invalidSubjects = setdiff(subjects, availableSubjects);
    
            if ~isempty(invalidSubjects) %if it finds invalid subject IDs
                error('1+ subject IDs not found')
            end
    
        % if all selected subject IDs are valid, creates an array of selected subjects
            selectedSubjects = subjects;  
    end
end
    

%%NESTED createSubjectIDMap HELPER FUNCTION
%this function locates all subject folders in the raw data folder and assigns subject IDs to each subject's folder
function SubjectIDmap = createSubjectIDMap()

    thesisDataAnalysisSettings;  % call script with directories/variables

    rootDir = rawDataFolderDir;
        %where subject folders are  
    
    allRawDataFolder = dir(rootDir); 
        %pulls everything from the raw data folder (folders and files) --> structure array
    subjectFolders = allRawDataFolder([allRawDataFolder.isdir]); 
        %isdir gets rid of files and just keeps folders (aka directories)
    subjectFolders = subjectFolders(~ismember({subjectFolders.name}, {'.', '..'}));
        %gets rid of 'system entry' folders so just takes subject folders
    
    subjectMap = containers.Map();%create empty map
    for i = 1:length(subjectFolders) %for all subject folders
        folderName=subjectFolders(i).name;
            % Extract subject ID from folder name using 'regular expression (aka finds naming pattern):
        tokens = regexp(folderName, '^(H\d+|S\d+)', 'match');
            %token = shortcut description (ie: d for digit) 
            %^ is start of string
            %(H\d+) = H#(#) and S\d+ = S#(#)
            %match creates cell array of the matches (ie the subject IDs)
        if ~isempty(tokens) %ie if finds matches^
            subjectID = tokens{1};  % Use the match (e.g., 'S1, H11, etc') as the subject ID
                %{} pulls the actual text content out of the matching cell
            subjectMap(subjectID) = folderName;
                % Adds to the map linking subjectID with folderName
        else
            error('Subject ID not found in folder name: %s', folderName);
            % gives an error if a subject's folder doesn't match the pattern
        end
    end

    % create the map:
    SubjectIDmap = subjectMap;
end



