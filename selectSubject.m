%this function allows user to input what subjects to select or, if no
%subjects are specified, selects them all from createSubjectIDMap function

function selectedSubjects = selectSubject(subjects)
    %creates selectedSubjects array

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
    
            selectedSubjects = subjects;  % if all valid subject IDs
    end
end
    
    
  