%this function allows user to input what trials to select or, if no
%trials are specified, selects them all

function selectedTrials = selectTrials(trials)

    arguments
        trials (:,1) double = []
    end
    
    availableTrials = [1, 4, 5, 8, 6, 7];
    
    if isempty(trials) %if no trials selected, it runs all of them:
        selectedTrials = availableTrials;
    else
        invalidTrials = setdiff(trials, availableTrials);
        if ~isempty(invalidTrials) %ie if some trials selected don't exist
            error ('one or more of the trials selected are incorrect')
        end
        selectedTrials = trials;
    end
end