%this function locates all subject folders in the raw data folder and assigns subject IDs to each subject's folder

function SubjectIDmap = createSubjectIDMap()

    rootDir = '/Users/holly/Library/CloudStorage/OneDrive-RutgersUniversity(2)/thesis_stuff/data/DataProcessing/RawData';
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
            error('Could not extract subject ID from folder: %s', folderName);
            % gives an error if a subject's folder doesn't match the
            % pattern
        end
    end

    % create the map:
    SubjectIDmap = subjectMap;
end



