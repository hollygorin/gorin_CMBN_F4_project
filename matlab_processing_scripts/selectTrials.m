function selectedTrials = selectTrials(trials)
    
    %this function allows user to input what trials to select or, if no trials are specified, selects them all

    arguments
        trials (:,1) double = []
    end
    
    thesisDataAnalysisSettings;  % call script with directories/variables
    
    if isempty(trials) %if no trials selected, it runs all of them:
        selectedTrials = fixedSpeedTrials;
    else
        invalidTrials = setdiff(trials, fixedSpeedTrials);
        if ~isempty(invalidTrials) %ie if some trials selected don't exist
            error ('one or more of the trials selected are incorrect')
        end
        selectedTrials = trials;
    end
    
