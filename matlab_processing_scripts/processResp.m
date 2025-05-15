function [avgRR, avgRD, peakRD] = processResp (biopacRawData, subj, t)
    % Process BIOPAC respiration data to calculate:
    % avgRR  - Average respiratory rate (breaths per minute)
    % avgRD  - Average respiratory depth (peak-to-trough amplitude)
    % peakRD - Peak respiratory depth (max peak-to-trough amplitude)

    thesisDataAnalysisSettings;

    % Extract Respiration Channel
    labels = strtrim(string(biopacRawData.labels));  % Clean up labels
    respChannelIdx = find(contains(labels, 'Respiration', 'IgnoreCase', true));
    
    if isempty(respChannelIdx)
        warning('Respiration channel not found in BIOPAC labels for %s, Trial %d.', subj, t);
        avgRR = NaN; avgRD = NaN; peakRD = NaN;
        return;
    end

respRawData = double(biopacRawData.data(:, respChannelIdx));
respRawData = respRawData(:);  % ensure its column vector  


%Resp processing parameters:
respOgFreq = 1000/biopacRawData.isi; 
        % ISI sampling interval of 0.5 ms --> ogSR of 2000 Hz
         %ISI should be consistent, but jic


 %%FIND RR:
    %first bandpass FIR with 4000 coefficients)
            %remove drift and high-frequency noise
            %isolate typical RRs + room on either side
bpFilter = designfilt('bandpassfir', 'FilterOrder', 4000, ...
'CutoffFrequency1', RRfilterLow, 'CutoffFrequency2', RRfilterHigh, ...
'SampleRate', respOgFreq);
    %RRfilterLow and RRFilterHigh defined in thesisDataAnalysiSettings
    
rrFiltered = filtfilt(bpFilter, respRawData);



    %then resample to 50Hz
        %can be low (to reduce computational load) and still ID peak timing
rrTargetFreq = 50; %Hz (consistently)

rrFiltResampled = resample(rrFiltered, rrTargetFreq, respOgFreq);
    %or;
    % [pRR, qRR] = rat(rrTargetFreq / respOgFreq);
    % respRR = resample(respFilteredRR, pRR, qRR);

    %troubleshooting:


    %then use positive peak detect (threshold of 0)   
respThreshold = 0; %peak detection of >0

[respPeaks, respLocs] = findpeaks(rrFiltResampled, 'MinPeakHeight', respThreshold, ...
'MinPeakDistance', rrTargetFreq / 1.5);  
    % Min 1.5 sec between peaks (max ~40 bpm possible)

    % Calculate Average RR
if length(respLocs) > 1 %ie if at least 2 peaks detected
    timeBetweenPeaks = diff(respLocs) / rrTargetFreq; 
        %diff(respLocs) = time b/n peaks (in samples)
        %/rrTargetFreq --> converts to seconds
    instantaneousRR = 60 ./ timeBetweenPeaks;  
        % time b/n peaks --> breaths per minute
    avgRR = mean(instantaneousRR); %for whole trial
else
    avgRR = NaN;  % Not enough peaks detected
end

 

%%FIND RD:

  %first aply low-pass filter 
        %remove noise without comromising amplitude details/flattening peaks
    lpFilter = designfilt('lowpassfir', 'FilterOrder', 500, ...
                      'CutoffFrequency', 5, 'SampleRate', respOgFreq);
        %filter consistent at 5Hz
    rdFiltered = filtfilt(lpFilter, respRawData);

  %resample to 200Hz
        %Higher sampling rate than RR to preserve peak/trough amplitudes
    rdTargetFreq = 200; %Hz (consistent0
    rdFiltResampled = resample(rdFiltered, rdTargetFreq, respOgFreq);
        %or:
        %[pRD, qRD] = rat(rdTargetFreq / respOgFreq);
        %respRD = resample(respFilteredRD, pRD, qRD);


  %then find RD using peak to trough amplitudes
    [rdPeaks, rdPeakLocs] = findpeaks(rdFiltResampled);
    [rdTroughs, rdTroughLocs] = findpeaks(-rdFiltResampled);
    rdTroughs = -rdTroughs;

    % Pair each trough with the next immediate peak
    depths = [];
    iTrough = 1;
    iPeak = 1;

    while iTrough <= length(rdTroughLocs) && iPeak <= length(rdPeakLocs)
        troughLoc = rdTroughLocs(iTrough);
        peakLoc = rdPeakLocs(iPeak);

        if peakLoc > troughLoc
            % Found a valid trough-to-peak pair (inhalation phase)
            troughValue = rdFiltResampled(troughLoc);
            peakValue = rdFiltResampled(peakLoc);
            depths(end+1) = peakValue - troughValue;  % Peak-to-Trough Amplitude
            iTrough = iTrough + 1;
            iPeak = iPeak + 1;  % Move to next peak
        else
            % Peak comes before trough; move to the next peak
            iPeak = iPeak + 1;
        end
    end


    %Calculate average RD
    if ~isempty(depths)
        avgRD = mean(depths);
        peakRD = max(depths);
    else
        avgRD = NaN;
        peakRD = NaN;
    end
end


    % depths = [];
    % for k = 1:length(rdPeakLocs)
    %     troughsBefore = rdTroughLocs(rdTroughLocs < rdPeakLocs(k));
    %     if ~isempty(troughsBefore)
    %         lastTroughLoc = troughsBefore(end);
    %         troughValue = rdFiltResampled(lastTroughLoc);
    %         peakValue = rdFiltResampled(rdPeakLocs(k));
    %         depths(end+1) = peakValue - troughValue;  % Peak-to-Peak amplitude for this breath
    %     end
    % end
    % 



