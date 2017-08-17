function tiffRenameProd(dirSource,dirTarget,xlsFileName,serieStr,colSourceTxt,colTargetTxt)
%
%
%
% CC 14 Feb 2017
% Modified 16 Aug 2017


SourceDirContent = dir(dirSource);

if ~exist(dirTarget,'dir')
    mkdir(dirTarget);
end

% Loop on all the tabs where you can find Scanning name and Renamed in
% Navigator

[numericData, textData, rawData] = xlsread(xlsFileName,serieStr);


[rowSource,colSource]=find(~cellfun('isempty',...
    strfind(textData,colSourceTxt)));
[rowTarget,colTarget]=find(~cellfun('isempty',...
    strfind(textData,colTargetTxt)));

% Find the list of files in the sources folder and check there is no
% discrepency

listSourceFiles = textData(rowSource+1:end,colSource);
listTargetFiles = textData(rowTarget+1:end,colTarget);

nTiff = length(listSourceFiles);

for iF = 1 : nTiff
    fprintf('\nRenaming file # %0.2d of %0.2d\n',iF,nTiff);
    copyfile(fullfile(dirSource,[listSourceFiles{iF} '.tif']),...
        fullfile(dirTarget,[listTargetFiles{iF} '.tif']));
    
    copyfile(fullfile(dirSource,[listSourceFiles{iF} '.txt']),...
        fullfile(dirTarget,[listTargetFiles{iF} '.txt']));
    if exist(fullfile(dirSource,'thumb'),'dir')
        if ~exist(fullfile(dirTarget,'thumb'),'dir')
            mkdir(fullfile(dirTarget,'thumb'));
        end
            copyfile(fullfile(dirSource,'thumb',[listSourceFiles{iF} '.png']),...
        fullfile(dirTarget,'thumb',[listTargetFiles{iF} '.png']));
    end
end


