function ExportCSV(sound, varargin)

if isempty(varargin)
    config = struct();
else
    config = varargin{1};
end

[config, grouping, directory, valueTypes, timeRes] = GetConfigCSVParams(config);

[config, sz] = CheckConfigRepsDescrs(sound, config);

counter = 0;
wtbar = waitbar(0, '', 'Name', ['Exporting CSV for sound ' [sound.fileName sound.fileType]]);
if strcmp(grouping, 'sound')
    for v = 1:length(valueTypes)
        if strcmp(valueTypes{v}, 'stats') || timeRes == 0
            csvfileName = [sound.fileName '_' valueTypes{v}];
        else
            csvfileName = [sound.fileName '_' valueTypes{v} '_' num2str(round(timeRes)) 'Hz'];
        end
        csvfileName = NewCSVFileName(directory, csvfileName);
        csvfile = fopen([directory '/' csvfileName '.csv'], 'w');
        fprintf(csvfile, 'Filename,%s\nSample Rate (samples/s),%s\nTotal Length (s),%s\nSample Range (Start) (s),%s\nSample Range (End) (s),%s\n\n',...
            [sound.fileName sound.fileType], num2str(sound.info.SampleRate), num2str((sound.info.TotalSamples-1)/sound.info.SampleRate), num2str((sound.info.SampleRange(1)-1)/sound.info.SampleRate), num2str((sound.info.SampleRange(2)-1)/sound.info.SampleRate));
        reps = fieldnames(config);
        for i = 1:length(reps)
            if strcmp(valueTypes{v}, 'ts')
                waitbar(counter/(length(valueTypes)*sz), wtbar, ['Exporting ' reps{i} ' Representation''s Time Series...']);
            else
                waitbar(counter/(length(valueTypes)*sz), wtbar, ['Exporting ' reps{i} ' Representation''s Statistics...']);
            end
            csvfile = sound.reps.(reps{i}).ExportCSV(csvfile, directory, csvfileName, valueTypes{v}, timeRes, 1);
            counter = counter + 1;
            descrs = fieldnames(config.(reps{i}));
            for j = 1:length(descrs)
                if strcmp(valueTypes{v}, 'ts')
                    waitbar(counter/(length(valueTypes)*sz), wtbar, ['Exporting ' descrs{j} ' Descriptor''s Time Series...']);
                else
                    waitbar(counter/(length(valueTypes)*sz), wtbar, ['Exporting ' descrs{j} ' Descriptor''s Statistics...']);
                end
                csvfile = sound.reps.(reps{i}).descrs.(descrs{j}).ExportCSV(csvfile, directory, csvfileName, valueTypes{v}, timeRes, 1);
                counter = counter + 1;
            end
        end
        fclose(csvfile);
    end
else
    for v = 1:length(valueTypes)
        reps = fieldnames(config);
        for i = 1:length(reps)
            counter = counter + 1;
            descrs = fieldnames(config.(reps{i}));
            for j = 1:length(descrs)
                if strcmp(valueTypes{v}, 'stats') || timeRes == 0
                    csvfileName = [class(sound.reps.(reps{i}).descrs.(descrs{j})) '_' valueTypes{v}];
                else
                    csvfileName = [class(sound.reps.(reps{i}).descrs.(descrs{j})) '_' valueTypes{v} '_' num2str(round(timeRes)) 'Hz'];
                end
                csvfile = GetCSVFileSameConfig(directory, csvfileName, sound.reps.(reps{i}).descrs.(descrs{j}));
                fprintf(csvfile, 'Filename,%s\nSample Rate (samples/s),%s\nTotal Length (s),%s\nSample Range (Start) (s),%s\nSample Range (End) (s),%s\n',...
                    [sound.fileName sound.fileType], num2str(sound.info.SampleRate), num2str((sound.info.TotalSamples-1)/sound.info.SampleRate), num2str((sound.info.SampleRange(1)-1)/sound.info.SampleRate), num2str((sound.info.SampleRange(2)-1)/sound.info.SampleRate));
                if strcmp(valueTypes{v}, 'ts')
                    waitbar(counter/(length(valueTypes)*sz), wtbar, ['Exporting ' descrs{j} ' Descriptor''s Time Series...']);
                else
                    waitbar(counter/(length(valueTypes)*sz), wtbar, ['Exporting ' descrs{j} ' Descriptor''s Statistics...']);
                end
                csvfile = sound.reps.(reps{i}).descrs.(descrs{j}).ExportCSV(csvfile, directory, csvfileName, valueTypes{v}, timeRes, 0);
                fclose(csvfile);
                counter = counter + 1;
            end
        end
    end
end
close(wtbar);

end

function [config, grouping, directory, valueTypes, timeRes] = GetConfigCSVParams(config)

if isfield(config, 'Grouping')
    if ~any(strcmp(config.Grouping, {'sound', 'descr'}))
        error('Config.Grouping can only accept the values ''sound'' or ''descr''.');
    end
    grouping = config.Grouping;
    config = rmfield(config, 'Grouping');
else
    grouping = 'sound';
end
if isfield(config, 'Directory')
    if ~isdir(config.Directory)
        error('Config.Directory must be a valid directory.');
    end
    directory = config.Directory;
    config = rmfield(config, 'Directory');
else
    directory = pwd();
end
if isfield(config, 'ValueTypes')
    if ~isa(config.ValueTypes, 'cell') || isempty(config.ValueTypes) || length(config.ValueTypes) ~= (any(strcmp(config.ValueTypes, 'ts')) + any(strcmp(config.ValueTypes, 'stats')))
        error('Config.ValueTypes must be a cell array containing the values ''ts'' (for the time series) and/or ''stats'' (for descriptive statistics of the time series).');
    end
    valueTypes = config.ValueTypes;
    config = rmfield(config, 'ValueTypes');
else
    valueTypes = {'ts', 'stats'};
end
if isfield(config, 'TimeRes')
    if ~isa(config.TimeRes, 'double') || config.TimeRes < 0
        error('Config.TimeRes must be a time resolution in Hz (double >= 0, with 0 for default time resolutions). It is ignored for ValueType ''stats''.');
    end
    timeRes = config.TimeRes;
    config = rmfield(config, 'TimeRes');
else
    timeRes = 0;
end

end

function [config, sz] = CheckConfigRepsDescrs(sound, config)

sz = 0;
reps = fieldnames(config);
noSpecifiedRep = true;
for i = 1:length(reps)
    if ~isfield(sound.reps, reps{i}) || ~isa(sound.reps.(reps{i}), 'Rep')
        config = rmfield(config, reps{i});
    else
        sz = sz + 1;
        noSpecifiedRep = false;
        descrs = fieldnames(config.(reps{i}));
        if isfield(config.(reps{i}), 'NoDescr')
            config.(reps{i}) = struct();
        else
            noSpecifiedDescr = true;
            for j = 1:length(descrs)
                if ~isfield(sound.reps.(reps{i}).descrs, descrs{j}) || ~isa(sound.reps.(reps{i}).descrs.(descrs{j}), 'Descr')
                    config.(reps{i}) = rmfield(config.(reps{i}), descrs{j});
                else
                    sz = sz + 1;
                    noSpecifiedDescr = false;
                end
            end
            if noSpecifiedDescr
                descrs = fieldnames(sound.reps.(reps{i}).descrs);
                for j = 1:length(descrs)
                    if isa(sound.reps.(reps{i}).descrs.(descrs{j}), 'Descr')
                        sz = sz + 1;
                        config.(reps{i}).(descrs{j}) = struct();
                    end
                end
            end
        end
    end
end
if noSpecifiedRep
    reps = fieldnames(sound.reps);
    for i = 1:length(reps)
        if isa(sound.reps.(reps{i}), 'Rep')
            sz = sz + 1;
            config.(reps{i}) = struct();
            descrs = fieldnames(sound.reps.(reps{i}).descrs);
            for j = 1:length(descrs)
                if isa(sound.reps.(reps{i}).descrs.(descrs{j}), 'Descr')
                    sz = sz + 1;
                    config.(reps{i}).(descrs{j}) = struct();
                end
            end
        end
    end
end

end

function csvfileName = NewCSVFileName(directory, csvfileName)

filelist = dir(directory);
count = 0;
for k = 1:length(filelist)
    [~,fileName,~] = fileparts(filelist(k).name);
    if strcmp(csvfileName, fileName)
        count = count + 1;
        if count == 1
            csvfileName = [csvfileName '_' num2str(count)];
        else
            if count <= 10
                csvfileName = [csvfileName(1:end-1) num2str(count)];
            elseif count <= 100
                csvfileName = [csvfileName(1:end-2) num2str(count)];
            elseif count <= 1000
                csvfileName = [csvfileName(1:end-3) num2str(count)];
            elseif count <= 10000
                csvfileName = [csvfileName(1:end-4) num2str(count)];
            else
                error('Too many csv files with the same name (10000).');
            end
        end
    end
end

end

function csvfile = GetCSVFileSameConfig(directory, csvfileName, descr)

filelist = dir(directory);
count = 0;
for k = 1:length(filelist)
    [~,fileName,~] = fileparts(filelist(k).name);
    if strcmp(csvfileName, fileName)
        csvfile = fopen([directory '/' csvfileName '.csv'], 'r');
        config = struct();
        line = fgetl(csvfile);
        parsedLine = strsplit(line,',');
        if strcmp(parsedLine{2}, class(descr.rep))
            line = fgetl(csvfile);
            parsedLine = strsplit(line,',');
            while ~any(strcmp(parsedLine{1}, {'Filename'}))
                if ~any(strcmp(parsedLine{1}, {'Representation','Descriptor',''}))
                    [value, isNumber] = str2num(parsedLine{2});
                    if isNumber
                        config.(parsedLine{1}) = value;
                    else
                        config.(parsedLine{1}) = parsedLine{2};
                    end
                end
                line = fgetl(csvfile);
                parsedLine = strsplit(line,',');
            end
            if descr.HasSameConfig(config)
                csvfile = fopen([directory '/' csvfileName '.csv'], 'a');
                return;
            end
        end
        fclose(csvfile);
        count = count + 1;
        if count == 1
            csvfileName = [csvfileName '_' num2str(count)];
        else
            if count <= 10
                csvfileName = [csvfileName(1:end-1) num2str(count)];
            elseif count <= 100
                csvfileName = [csvfileName(1:end-2) num2str(count)];
            elseif count <= 1000
                csvfileName = [csvfileName(1:end-3) num2str(count)];
            elseif count <= 10000
                csvfileName = [csvfileName(1:end-4) num2str(count)];
            else
                error('Too many csv files with the same name (10000).');
            end
        end
    end
end

csvfile = fopen([directory '/' csvfileName '.csv'], 'w');

fprintf(csvfile, 'Representation,%s\n', class(descr.rep));
csvfile = descr.ExportCSV(csvfile, directory, csvfileName, {}, [], -1);

end