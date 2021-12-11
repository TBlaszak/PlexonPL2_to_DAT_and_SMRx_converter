%% clean up the universe
clc;
clear;

%% IMPORTANT INFORMATION read it first, you moron!
% This script converts Plexon's .pl2 file into binary .dat file (for Kilosort) and into Spike2 .smrx file
% WARNING!!! - if FilterData = TRUE, it filters data (Butterworth, 4th order, 300-7500Hz)
% WARNING!!! - if SubtractMean = TRUE, it substracts, from each channel, the mean of all channels.
% % Only WB channels will go to binary .dat file
% All channels will go to Spike2 .smrx file

FilterData = true;
SubtractMean = true;
SubtractBy = 'SHK'; %'MEA', 'SHK' - determines if mean of wholle MEA or mean of Shanks is subtracted from channels (on shanks)

smrxSPKCnoOffset = 0;   %z tum offsetem bêda numerowane kana³y SPKC (pochodne WB)
smrxAInoOffset = 100;   %z tum offsetem bêda numerowane kana³y AI 

%% Stwórz kobietê!
NET.addAssembly('System.Speech');
SpeachObj = System.Speech.Synthesis.SpeechSynthesizer;
SpeachObj.Volume = 100;

%% wcztaj bibliotekê CED
CEDS64LoadLib('C:\Program Files\MATLAB\R2018a\toolbox\CEDMATLAB\CEDS64ML'); 

%% Show me the .pl2 file
Speak(SpeachObj, 'Kotek, wskarz mi plik pl2 do przekonwertowania na plik binarny dat dla kilosorta i smrx dla spajka');
[PL2fullfname, PL2fpath] = uigetfile ('*.pl2', 'Select .pl2 file');  %wska¿ plik .pl2
PL2file = fullfile (PL2fpath, PL2fullfname);
[~, PL2fname, ~] = fileparts(PL2file);
PL2info = PL2GetFileIndex (PL2file);    % gather info about content of .pl2 file

fprintf('Przerabiam plik %s PLEXONa do pliku binarnego.\n', PL2fullfname);

tic; % let's see how slow You are :-)

%% Pozbieraj info o tym co jest w kolejnych kana³ach i wci¹gnij dane
nAnalogChannels = PL2info.TotalNumberOfAnalogChannels;
nEventChannels = PL2info.NumberOfEventChannels;
infoWBchannels = {};
infoFPchannels = {};
infoAIchannels = {};
infoSingleBitEVNTchannels = {};
infoKbdEVNTchannels = {};

% najpierw info o kana³ach analogowych: WB, FP, AI
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

% teraz info o kana³ach zdarzeñ KBD, Single-bit events
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
% preallocate for speed (przedmuchaj nos)
nSampliPerCh = infoWBchannels{1, 4};  % assume that all Chanls are like 1st analague Chanl
[nchannels, ~] = size(infoWBchannels);
rawWBdata = zeros(nSampliPerCh, nchannels);
for i = 1:nchannels
        PLchannel = infoWBchannels{i, 3};
        [adfreq, n, ts, fn, adv] = plx_ad_v (PL2file, PLchannel);
        rawWBdata(:,i) = adv;
end

%% Get raw data from AI channels
% preallocate for speed (przedmuchaj nos)
nSampliPerCh = infoAIchannels{1, 4};  % let's assume that all WB chanls are like 1st WB analag channel
[nchannels, ~] = size(infoAIchannels);
rawAIdata = zeros(nSampliPerCh, nchannels);
for i = 1:nchannels
        PLchannel = infoAIchannels{i, 3};
        [adfreq, n, ts, fn, adv] = plx_ad_v (PL2file, PLchannel);
        rawAIdata(:,i) = adv;
end

%% Filter WB data, if You wish
if FilterData   
    Speak(SpeachObj, 'A teraz filtrujê sygna³, tak jak lubisz');
    fs = infoWBchannels{1, 5};  % let's assume that all WB chanls are like 1st WB analag channel
    dfilter = designfilt('bandpassiir', 'FilterOrder', 4, 'HalfPowerFrequency1', 300,...
         'HalfPowerFrequency2', 7500, 'SampleRate', fs);
    rawWBdata = filter (dfilter, rawWBdata);
end

%% Subtract mean of all WB channels from WB channels, if You wish - note, that it is after filtering
if SubtractMean
    switch SubtractBy
        case 'MEA'
            Speak(SpeachObj, 'Specjalnie dla Ciebie Kotku odejmujê uœredniony sygna³ ca³ej macierzy od ka¿dego kana³u');
            meanWBdata = mean (rawWBdata, 2);
            rawWBdata = rawWBdata - meanWBdata;
        case 'SHK'
            channelsOnSHK1 = [1:4:32];
            channelsOnSHK2 = [2:4:32];
            channelsOnSHK3 = [3:4:32];
            channelsOnSHK4 = [4:4:32];
            Speak(SpeachObj, 'Kiciuœ, odejmujê uœredniony sygna³ ca³ego szanka od kana³ów na tym szanku');
            meanWBdata = mean (rawWBdata (:, channelsOnSHK1), 2);    % shank 1
            rawWBdata (:, channelsOnSHK1) = rawWBdata (:, channelsOnSHK1) - meanWBdata;
            meanWBdata = mean (rawWBdata (:, channelsOnSHK2), 2);    % shank 2
            rawWBdata (:, channelsOnSHK2) = rawWBdata (:, channelsOnSHK2) - meanWBdata;
            meanWBdata = mean (rawWBdata (:, channelsOnSHK3), 2);    % shank 3
            rawWBdata (:, channelsOnSHK3) = rawWBdata (:, channelsOnSHK3) - meanWBdata;
            meanWBdata = mean (rawWBdata (:, channelsOnSHK4), 2);    % shank 4
            rawWBdata (:, channelsOnSHK4) = rawWBdata (:, channelsOnSHK4) - meanWBdata;
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
        error (['Skarbie, jakoœ nie mogê otworzyæ tego: ',DATfname]);
        Speak(SpeachObj, 'Skarbie, jakoœ nie mogê otworzyæ tego pliku...');
    end
fwrite (DATfid, niceWBdata', 'int16'); %line that writes data to binary file
fclose (DATfid);
toc;

%% Utwórz plik Spike2 .smrx
SMRxfname = sprintf ('%s\\%s.smrx', PL2fpath, PL2fname);
[SMRxfhand] = CEDS64Create(SMRxfname, 400, 2);
if SMRxfhand <= 0 
        display (sprintf ('Polecenie CEDS64Create wyszuci³o b³¹d: %i', SMRxfhand)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(SMRxfhand, PL2file);
        return;
end

%% Wrzuæ do pliku Spike2 kana³y WB - uwaga, ju¿ po ewentualnej filtracji i subtrakcji
[w k] = size (niceWBdata);
for i = 1:k
    smrxAnalogChNo = smrxSPKCnoOffset + i;
    sampleInt = (1/infoWBchannels{i, 5})*1e6;   % obliczam interwa³ (w tickach) pomiêdzy samplami, zak³¹daj¹c, ¿e tick = 1micros
    adfreq = infoWBchannels{i, 5};
    [isOK] = CEDS64SetWaveChan (SMRxfhand, smrxAnalogChNo, sampleInt, 1, adfreq); %utwórz odpowiedni nowy kana³ w pliku .smrx
    if isOK < 0 
            display (sprintf ('Polecenie CEDS64SetWaveChan wyrzuci³o b³¹d: %i', isOK)); 
            Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
            Posprzataj(isOK, PL2file);
            return;
    end   
    [isOK] = CEDS64WriteWave (SMRxfhand, smrxAnalogChNo, niceWBdata(:, i), 0);   % wrzuæ nice dane do kana³u
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64WriteWave wyrzuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanTitle (SMRxfhand, smrxAnalogChNo, infoWBchannels{i, 2});   % nadaj tytu³ kana³u taki jak w pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanUnits (SMRxfhand, smrxAnalogChNo, infoWBchannels{i, 6}); % podaj jednostkê kana³u tak jak pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
end

%% Wrzuæ do pliku Spike2 kana³y AI
[w k] = size (niceAIdata);
for i = 1:k
    smrxAIChNo = smrxAInoOffset + i;
    sampleInt = (1/infoAIchannels{i, 5})*1e6;   % obliczam interwa³ (w tickach) pomiêdzy samplami, zak³¹daj¹c, ¿e tick = 1micros
    adfreq = infoAIchannels{i, 5};
    [isOK] = CEDS64SetWaveChan (SMRxfhand, smrxAIChNo, sampleInt, 1, adfreq); %utwórz odpowiedni nowy kana³ w pliku .smrx
    if isOK < 0 
            display (sprintf ('Polecenie CEDS64SetWaveChan wyrzuci³o b³¹d: %i', isOK)); 
            Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
            Posprzataj(isOK, PL2file);
            return;
    end   
    [isOK] = CEDS64WriteWave (SMRxfhand, smrxAIChNo, niceAIdata(:, i), 0);   % wrzuæ nice dane do kana³u
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64WriteWave wyrzuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanTitle (SMRxfhand, smrxAIChNo, infoAIchannels{i, 2});   % nadaj tytu³ kana³u taki jak w pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
    [isOK] = CEDS64ChanUnits (SMRxfhand, smrxAIChNo, infoAIchannels{i, 6}); % podaj jednostkê kana³u tak jak pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end
end

%% Powyci¹gaj z pliku pl2 Single-bit EVENTS i wrzuc je do pliku .smrx
[w ~] = size (infoSingleBitEVNTchannels)
for i = 1:1:w
    smrxEVNTchNo = smrxAIChNo + i;  % kana³y EVENT wrzucam zaraz po AI
    [n, tsInSec] = plx_event_ts (PL2file, infoSingleBitEVNTchannels{i, 3});   % wczytaj ts bie¿¹cego kana³u Evnt 
    [isOK] = CEDS64SetEventChan (SMRxfhand, smrxEVNTchNo, 500, 3);
    if isOK < 0 
            display (sprintf ('Polecenie CEDS64SetEventChan wyszuci³o b³¹d: %i', isOK)); 
            Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
            Posprzataj(isOK, PL2file);
            return;
    end
    tsInTicks = CEDS64SecsToTicks (SMRxfhand, tsInSec); % przekonwertuj timestampy w sekundach na ticks
    [isOK] = CEDS64WriteEvents (SMRxfhand, smrxEVNTchNo, tsInTicks);   % wrzuæ dane Evnt do kana³u
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64WriteEvents wyszuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end  
    [isOK] = CEDS64ChanTitle (SMRxfhand, smrxEVNTchNo, infoSingleBitEVNTchannels{i, 2});   % nadaj tytu³ kana³u taki jak w pl2
    if isOK < 0 
        display (sprintf ('Polecenie CEDS64ChanTitle wyszuci³o b³¹d: %i', isOK)); 
        Speak(SpeachObj, 'Coœ mi tu œmierdzi...');
        Posprzataj(isOK, PL2file);
        return;
    end  
end

%% wezwij Leona
Posprzataj(isOK, PL2file);
clear;

%% a na koniec Leon Zawodowiec
function Posprzataj(isOK, PL2file)
    NET.addAssembly('System.Speech');   % ponowne udzielenie g³osu
    SpeachObj = System.Speech.Synthesis.SpeechSynthesizer;
    SpeachObj.Volume = 100;
    fclose('all');              %close all the files
    CEDS64CloseAll();           %close all CED the files
    plx_close (PL2file);        %close all Plexon the files
    unloadlibrary ceds64int;    %unload ceds64int.dll
    toc
    if isOK >= 0
        display ('Skoñczy³am :-)');
        Speak(SpeachObj, 'Skarbie, ju¿ skoñczy³am');
    else
        display ('Skoñczy³am, ale nie jestem zadowolona :-(');
        Speak(SpeachObj, 'Skarbie, ju¿ skoñczy³am ale nie jestem zadowolona');
    end
end
