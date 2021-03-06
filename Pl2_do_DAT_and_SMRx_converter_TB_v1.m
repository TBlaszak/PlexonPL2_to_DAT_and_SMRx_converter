%% clean up the universe
clc;
clear;

%% IMPORTANT INFORMATION read it first!
% This script converts Plexon's .pl2 file into binary .dat file (for Kilosort) and into Spike2 .smrx file
% WARNING!!! - if FilterData = TRUE, it filters data (Butterworth, 4th order, 300-7500Hz)
% WARNING!!! - if Subtract = 'mean' or 'median', it substracts, from each channel, the mean of median of:
% all channels (SubtractBy = 'MEA') or channels on the same MES's shank (SubtractBy = 'SHK').
% It is written for 32 channel MEA with configuration 4x8 (four shanks, 8 channels per shank) - it does metter
% if You use SubtractBy = 'SHK'
% Only WB channels will go to binary .dat file
% All channels WB (optionally filtered and subtracted), AI, EVENT will go to Spike2 .smrx file
% WARNING!!! - SPK, SPKC, FP and KBD channels are discarded - the script can be easly moddifed to includ it.

FilterData = true;
Subtract = 'median';  %'mean', 'median' oe 'none' - determines what (if anything) will be subtracted from signal on channels
SubtractBy = 'MEA'; %'MEA', 'SHK' - determines if mean of wholle MEA or mean of Shanks is subtracted from channels (on shanks)
smrxSPKCnoOffset = 0;   % WB (after optional processing) channells' numbering offset for Spike2 file
smrxAInoOffset = 100;   % AI channells' numbering offset for Spike2 file

CanItalk2U = true;

%% Create woman voice
if CanItalk2U
    NET.addAssembly('System.Speech');
    SpeachObj = System.Speech.Synthesis.SpeechSynthesizer;
    SpeachObj.Volume = 100;
    SpeachObj.SelectVoice('Microsoft Hazel Desktop'); % You need to add here the string corresponding to the right voice.
    Speak(SpeachObj, 'Hello darling, you know that I love to heve these conversations with you');
end

%% read CEDMATLAB librairy
CEDS64LoadLib('C:\Program Files\MATLAB\R2018a\toolbox\CEDMATLAB\CEDS64ML'); 

%% Show me the .pl2 file
if CanItalk2U
    Speak(SpeachObj, 'Kitty, show me the plexon file You want me to convert for You');
end    
[PL2fullfname, PL2fpath] = uigetfile ('*.pl2', 'Select .pl2 file');  %wska? plik .pl2
PL2file = fullfile (PL2fpath, PL2fullfname);
[~, PL2fname, ~] = fileparts(PL2file);
PL2info = PL2GetFileIndex (PL2file);    % gather info about content of .pl2 file

fprintf('I have starded to convert %s file to .dat and .smrx files.\n', PL2fullfname);

tic; % let's see how slow I am :-)

%% Get info about content of channels and gather data
nAnalogChannels = PL2info.TotalNumberOfAnalogChannels;
nEventChannels = PL2info.NumberOfEventChannels;
infoWBchannels = {};
infoFPchannels = {};
infoAIchannels = {};
infoSingleBitEVNTchannels = {};
infoKbdEVNTchannels = {};

% first analog channels: WB, SPKC, FP, AI
for i = 1:nAnalogChannels
    switch PL2info.AnalogChannels{i, 1}.SourceName
        case 'WB'
            if PL2info.AnalogChannels{i, 1}.NumValues > 0
                infoWBchannels{end+1, 1} = 'WB';
                infoWBchannels{end, 2} = PL2info.AnalogChannels{i, 1}.Name;
                infoWBchannels{end, 3} = PL2info.AnalogChannels{i, 1}.PlxChannel;
                infoWBchannels{end, 4} = PL2info.AnalogChannels{i, 1}.NumValues;
                infoWBchannels{end, 5} = PL2info.AnalogChannels{i, 1}.SamplesPerSecond;
                infoWBchannels{end, 6} = PL2info.AnalogChannels{i, 1}.Units;
                infoWBchannels{end, 7} = PL2info.AnalogChannels{i, 1}.TotalGain;
            end
        case 'FP'
            if PL2info.AnalogChannels{i, 1}.NumValues > 0
                infoFPchannels{end+1, 1} = 'FP';
                infoFPchannels{end, 2} = PL2info.AnalogChannels{i, 1}.Name;
                infoFPchannels{end, 3} = PL2info.AnalogChannels{i, 1}.PlxChannel;
                infoFPchannels{end, 4} = PL2info.AnalogChannels{i, 1}.NumValues;
                infoFPchannels{end, 5} = PL2info.AnalogChannels{i, 1}.SamplesPerSecond;
                infoFPchannels{end, 6} = PL2info.AnalogChannels{i, 1}.Units;
                infoFPchannels{end, 7} = PL2info.AnalogChannels{i, 1}.TotalGain;
            end
        case 'AI'
            if PL2info.AnalogChannels{i, 1}.NumValues > 0
                infoAIchannels{end+1, 1} = 'AI';
                infoAIchannels{end, 2} = PL2info.AnalogChannels{i, 1}.Name;
                infoAIchannels{end, 3} = PL2info.AnalogChannels{i, 1}.PlxChannel;
                infoAIchannels{end, 4} = PL2info.AnalogChannels{i, 1}.NumValues;
                infoAIchannels{end, 5} = PL2info.AnalogChannels{i, 1}.SamplesPerSecond;
                infoAIchannels{end, 6} = PL2info.AnalogChannels{i, 1}.Units;
                infoAIchannels{end, 7} = PL2info.AnalogChannels{i, 1}.TotalGain;
            end
    end
end

% next KBD, Single-bit events channels
for i = 1:nEventChannels
    switch PL2info.EventChannels{i, 1}.SourceName
        case 'KBD'
            if PL2info.EventChannels{i, 1}.NumEvents > 0
                infoKbdEVNTchannels{end+1, 1} = 'KBD';
                infoKbdEVNTchannels{end, 2} = PL2info.EventChannels{i, 1}.Name;
                infoKbdEVNTchannels{end, 3} = PL2info.EventChannels{i, 1}.Channel;
                infoKbdEVNTchannels{end, 4} = PL2info.EventChannels{i, 1}.NumEvents;
            end
        case 'Single-bit events'
            if PL2info.EventChannels{i, 1}.NumEvents > 0
                infoSingleBitEVNTchannels{end+1, 1} = 'EVT';
                infoSingleBitEVNTchannels{end, 2} = PL2info.EventChannels{i, 1}.Name;
                infoSingleBitEVNTchannels{end, 3} = PL2info.EventChannels{i, 1}.Channel;
                infoSingleBitEVNTchannels{end, 4} = PL2info.EventChannels{i, 1}.NumEvents;
            end
    end
end

%% Get raw data from WB channels
% preallocate for speed 
nSampliPerCh = infoWBchannels{1, 4};  % assume that all WB channels are like 1st WB channel
[nchannels, ~] = size(infoWBchannels);
rawWBdata = zeros(nSampliPerCh, nchannels);
for i = 1:nchannels
        PLchannel = infoWBchannels{i, 3};
        [adfreq, n, ts, fn, adv] = plx_ad_v (PL2file, PLchannel);
        rawWBdata(:,i) = adv;
end

%% Get raw data from AI channels
% preallocate for speed 
nSampliPerCh = infoAIchannels{1, 4};  % let's assume that all AI chanls are like 1st AI channel
[nchannels, ~] = size(infoAIchannels);
rawAIdata = zeros(nSampliPerCh, nchannels);
for i = 1:nchannels
        PLchannel = infoAIchannels{i, 3};
        [adfreq, n, ts, fn, adv] = plx_ad_v (PL2file, PLchannel);
        rawAIdata(:,i) = adv;
end

%% Filter WB data, if You wish
if FilterData   
    if CanItalk2U
        Speak(SpeachObj, 'And now I will filter data, as You like');
    end
    fs = infoWBchannels{1, 5};  % let's assume that all WB chanls are like 1st WB analag channel
    dfilter = designfilt('bandpassiir', 'FilterOrder', 4, 'HalfPowerFrequency1', 300,...
         'HalfPowerFrequency2', 7500, 'SampleRate', fs);
    rawWBdata = filter (dfilter, rawWBdata);
end

%% Subtract mean or median of all WB channels from WB channels, if You wish - note, that it is after filtering
switch Subtract
    case 'mean'
        switch SubtractBy
            case 'MEA'
                if CanItalk2U
                    Speak(SpeachObj, 'Especially for You Darling, I subtract from each channel mean of all channels');
                end
                meanWBdata = mean (rawWBdata, 2);
                rawWBdata = rawWBdata - meanWBdata;
            case 'SHK'
                channelsOnSHK1 = [1:4:32];
                channelsOnSHK2 = [2:4:32];
                channelsOnSHK3 = [3:4:32];
                channelsOnSHK4 = [4:4:32];
                if CanItalk2U
                    Speak(SpeachObj, 'My precious, now i subtract from the channells mean of all channels on a given shank');
                end
                meanWBdata = mean (rawWBdata (:, channelsOnSHK1), 2);    % shank 1
                rawWBdata (:, channelsOnSHK1) = rawWBdata (:, channelsOnSHK1) - meanWBdata;
                meanWBdata = mean (rawWBdata (:, channelsOnSHK2), 2);    % shank 2
                rawWBdata (:, channelsOnSHK2) = rawWBdata (:, channelsOnSHK2) - meanWBdata;
                meanWBdata = mean (rawWBdata (:, channelsOnSHK3), 2);    % shank 3
                rawWBdata (:, channelsOnSHK3) = rawWBdata (:, channelsOnSHK3) - meanWBdata;
                meanWBdata = mean (rawWBdata (:, channelsOnSHK4), 2);    % shank 4
                rawWBdata (:, channelsOnSHK4) = rawWBdata (:, channelsOnSHK4) - meanWBdata;
        end
    case 'median'
        switch SubtractBy
            case 'MEA'
                if CanItalk2U
                    Speak(SpeachObj, 'Especially for You Darling, I subtract from each channel median of all channels');
                end
                medianWBdata = median (rawWBdata, 2);
                rawWBdata = rawWBdata - medianWBdata;
            case 'SHK'
                channelsOnSHK1 = [1:4:32];
                channelsOnSHK2 = [2:4:32];
                channelsOnSHK3 = [3:4:32];
                channelsOnSHK4 = [4:4:32];
                if CanItalk2U
                    Speak(SpeachObj, 'My precious, now i subtract from the channells median of all channels on a given shank');
                end
                medianSHkWBdata = median (rawWBdata (:, channelsOnSHK1), 2);    % shank 1
                rawWBdata (:, channelsOnSHK1) = rawWBdata (:, channelsOnSHK1) - medianSHkWBdata;
                medianSHkWBdata = median (rawWBdata (:, channelsOnSHK2), 2);    % shank 2
                rawWBdata (:, channelsOnSHK2) = rawWBdata (:, channelsOnSHK2) - medianSHkWBdata;
                medianSHkWBdata = median (rawWBdata (:, channelsOnSHK3), 2);    % shank 3
                rawWBdata (:, channelsOnSHK3) = rawWBdata (:, channelsOnSHK3) - medianSHkWBdata;
                medianSHkWBdata = median (rawWBdata (:, channelsOnSHK4), 2);    % shank 4
                rawWBdata (:, channelsOnSHK4) = rawWBdata (:, channelsOnSHK4) - medianSHkWBdata;
            end     
end

%% Make nice and shiny shit for binary file and Spike2 file
niceWBdata = int16(rawWBdata*infoWBchannels{1, 7});      % let's assume that all WB channels have the same TotalGain
niceAIdata = int16(rawAIdata*infoAIchannels{1, 7});      % let's assume that all WB channels have the same TotalGain

%% Write niceWBdata to binary file
% create file and open it for me
DATfname = sprintf ('%s\\%s.dat', PL2fpath, PL2fname);
DATfid = fopen (DATfname, 'w');
    if (DATfid == -1)
        error (['Darling, i can not open this file: ',DATfname]);
        if CanItalk2U
            Speak(SpeachObj, 'Oh boy, i can not open this file...');
        end
    end
fwrite (DATfid, niceWBdata', 'int16'); %line that writes data to binary file
fclose (DATfid);
toc;

%% Utw?rz plik Spike2 .smrx
SMRxfname = sprintf ('%s\\%s.smrx', PL2fpath, PL2fname);
[SMRxfhand] = CEDS64Create(SMRxfname, 400, 2);
if SMRxfhand <= 0 
        display (sprintf ('Polecenie CEDS64Create wyszuci?o b??d: %i', SMRxfhand));
        if CanItalk2U
            Speak(SpeachObj, 'Fuck, something went really wrong...');
        end;
        Posprzataj(SMRxfhand, PL2file);
        return;
end

%% Wrzu? do pliku Spike2 kana?y WB - uwaga, ju? po ewentualnej filtracji i subtrakcji
[w k] = size (niceWBdata);
for i = 1:k
    smrxAnalogChNo = smrxSPKCnoOffset + i;
    sampleInt = (1/infoWBchannels{i, 5})*1e6;   % obliczam interwa? (w tickach) pomi?dzy samplami, zak??daj?c, ?e tick = 1micros
    adfreq = infoWBchannels{i, 5};
    [isOK] = CEDS64SetWaveChan (SMRxfhand, smrxAnalogChNo, sampleInt, 1, adfreq); %utw?rz odpowiedni nowy kana? w pliku .smrx
    if isOK < 0 
            display (sprintf ('Polecenie CEDS64SetWaveChan wyrzuci?o b??d: %i', isOK)); 
            Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
            Posprzataj(isOK, PL2file);
            return;
    end   
    [isOK] = CEDS64WriteWave (SMRxfhand, smrxAnalogChNo, niceWBdata(:, i), 0);   % wrzu? nice dane do kana?u
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64WriteWave wyrzuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanTitle (SMRxfhand, smrxAnalogChNo, infoWBchannels{i, 2});   % nadaj tytu? kana?u taki jak w pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanUnits (SMRxfhand, smrxAnalogChNo, infoWBchannels{i, 6}); % podaj jednostk? kana?u tak jak pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
end

%% Wrzu? do pliku Spike2 kana?y AI
[w k] = size (niceAIdata);
for i = 1:k
    smrxAIChNo = smrxAInoOffset + i;
    sampleInt = (1/infoAIchannels{i, 5})*1e6;   % obliczam interwa? (w tickach) pomi?dzy samplami, zak??daj?c, ?e tick = 1micros
    adfreq = infoAIchannels{i, 5};
    [isOK] = CEDS64SetWaveChan (SMRxfhand, smrxAIChNo, sampleInt, 1, adfreq); %utw?rz odpowiedni nowy kana? w pliku .smrx
    if isOK < 0 
            display (sprintf ('Polecenie CEDS64SetWaveChan wyrzuci?o b??d: %i', isOK)); 
            Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
            Posprzataj(isOK, PL2file);
            return;
    end   
    [isOK] = CEDS64WriteWave (SMRxfhand, smrxAIChNo, niceAIdata(:, i), 0);   % wrzu? nice dane do kana?u
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64WriteWave wyrzuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanTitle (SMRxfhand, smrxAIChNo, infoAIchannels{i, 2});   % nadaj tytu? kana?u taki jak w pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanUnits (SMRxfhand, smrxAIChNo, infoAIchannels{i, 6}); % podaj jednostk? kana?u tak jak pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
end

%% Powyci?gaj z pliku pl2 Single-bit EVENTS i wrzuc je do pliku .smrx
[w ~] = size (infoSingleBitEVNTchannels)
for i = 1:1:w
    smrxEVNTchNo = smrxAIChNo + i;  % kana?y EVENT wrzucam zaraz po AI
    [n, tsInSec] = plx_event_ts (PL2file, infoSingleBitEVNTchannels{i, 3});   % wczytaj ts bie??cego kana?u Evnt 
    [isOK] = CEDS64SetEventChan (SMRxfhand, smrxEVNTchNo, 500, 3);
    if isOK < 0 
            display (sprintf ('Polecenie CEDS64SetEventChan wyszuci?o b??d: %i', isOK)); 
            Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
            Posprzataj(isOK, PL2file);
            return;
    end
    tsInTicks = CEDS64SecsToTicks (SMRxfhand, tsInSec); % przekonwertuj timestampy w sekundach na ticks
    [isOK] = CEDS64WriteEvents (SMRxfhand, smrxEVNTchNo, tsInTicks);   % wrzu? dane Evnt do kana?u
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64WriteEvents wyszuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end  
    [isOK] = CEDS64ChanTitle (SMRxfhand, smrxEVNTchNo, infoSingleBitEVNTchannels{i, 2});   % nadaj tytu? kana?u taki jak w pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci?o b??d: %i', isOK)); 
        Speak(SpeachObj, 'Co? mi tu ?mierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end  
end

%% wezwij Leona
Posprzataj(isOK, PL2file, CanItalk2U);
clear;

%% a na koniec Leon Zawodowiec
function Posprzataj(isOK, PL2file, CanItalk2U)
    NET.addAssembly('System.Speech');   % ponowne udzielenie g?osu
    SpeachObj = System.Speech.Synthesis.SpeechSynthesizer;
    SpeachObj.Volume = 100;
    SpeachObj.SelectVoice('Microsoft Hazel Desktop'); % You need to add here the string corresponding to the right voice.
    fclose('all');              %close all the files
    CEDS64CloseAll();           %close all CED the files
    plx_close (PL2file);        %close all Plexon the files
    unloadlibrary ceds64int;    %unload ceds64int.dll
    toc
    if isOK >= 0
        display ('I am done :-)');
        if CanItalk2U
            Speak(SpeachObj, 'Darling, I am always happy to please You. Thank You, I am done.');
        end
    else
        display ('Darling, it was nice, but I am not fully satisfied');
        if CanItalk2U
            Speak(SpeachObj, 'Darling, it was really nice, but I am not fully satisfied. Is something bothering You?');
        end
    end
end
