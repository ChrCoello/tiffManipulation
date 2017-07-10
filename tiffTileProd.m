function tiffTileProd(input,output_dir)
%
% Function: open a tiff file and save as tiles. Tiles are predefined by the
% width and height of the original images. Information of the tiles is
% found in the metadata of the tiff file
%
% Syntaxis: tiffAdjProd(filename,output_dir)
%
% Inputs
%   filename (required): can be a directory name or a tiff filename with or
%   without extension
%   output_dir (required):  location where the adjusted tiff(s) will be stored.
%   The function will create a folder within output_dir
%
% Example:
% 1/ Save a tiff file as tiles
%       tiffTileProd('C:\data\histology\RawTiff\tg2576_m287_1D1_IV-1\tg2576_m287_1D1_IV-1_s3.tif',workdir);
%
%
%
%%% Parse inputs
p = inputParser;
%
%%% Specify input type
addRequired(p,'input',@ischar);
addRequired(p,'output_dir',@ischar);
%
%%% Check inputs
parse(p,input,output_dir);
%
%%% Check on the input
if isdir(input),
    if ~exist(input,'dir'),
        error('TiffAdjProd:MissingDir','The directory %s cannot be found',input);
    else
        % Search directory for .tiff or tif files
        TwoF = dir(fullfile(input,'*.tiff'));
        OneF = dir(fullfile(input,'*.tif'));
        InputContent = cat(1,OneF,TwoF);
        filenames = fullfile(input,{InputContent(:).name}');
    end
else
    if ~exist(input,'file'),
        % Check if it was just the extension that was missing
        [pIn,fnIn,extIn] = fileparts(input);
        if isempty(extIn),
            % Find the file
            if isempty(pIn),
                pIn = pwd;
            end
            DirContent = dir(pIn);
            fN = DirContent(~cellfun('isempty',strfind({DirContent(:).name},fnIn))).name;
            [pIn2,fnIn2,extIn2] = fileparts(fN);
            if ismember(extIn2,{'tif','tiff'}),
                % Good that is what we wanted to find : tif extension
                % forgotten in the input
                filenames = {fullfile(pIn2,sprintf('%s%s',fnIn2,extIn2))};
            else
                error('TiffAdjProd:MissingFile','The file %s is not a tiff file',input);
            end
        else
            % there is an extension but the file doesn't exist
            error('TiffAdjProd:MissingFile','The file %s cannot be found',input);
        end
    else
        filenames = {input};
    end
end
if ~exist(output_dir,'dir'),
    [s,mess,messid] = mkdir(output_dir);
    if ~s,
        error(messid,mess);
    end
end

%%% Loop on filenames
if ~isempty(filenames),
    %
    nFiles = length(filenames);
    tTot   = zeros(nFiles,1);
    for idxFile = 1 : nFiles,
        %
        [pF,filename,ext] = fileparts(filenames{idxFile});
        %
        fprintf(1,'%s\n',repmat('-',1,50));
        %%% Should really only have tif at this point, ut adding a last check
        if ismember(ext,{'.tif','.tiff'}),
            % Gather info on the file
            tiffInfo = imfinfo(fullfile(pF,sprintf('%s%s',filename,ext)));
        else
            % Not a tiff, go to the next file
            continue
        end
        %%% Load the Tiff Object
        tiffObj  = Tiff(tiffInfo.Filename,'r');
        %%% Read all the tiles
        fprintf(1,' -- Reading %d tiles from file %s...\n',tiffObj.numberOfTiles,filename);
        %
        tic
        for iL = 1:tiffObj.numberOfTiles,
            tileDataRaw{iL}=tiffObj.readEncodedTile(iL); %#ok<*AGROW>
        end
        %
        tread=toc;
        %
        fprintf(1,' -- Tile reading completed with success in %0.2f seconds\n',tread);
        %
        fprintf(1,' -- Writing %d tiles in separate files ...\n',tiffObj.numberOfTiles);
        %
        tic;
        if ~exist(fullfile(output_dir,sprintf('%s_tiles',filename)),'dir'),
            mkdir(fullfile(output_dir,sprintf('%s_tiles',filename)));
        end
        for iL = 1:tiffObj.numberOfTiles,
            %%% Create new tiff
            newFile = fullfile(output_dir,sprintf('%s_tiles',filename),sprintf('%s_tile%0.4d.tif',filename,iL));
            newTiffObj = Tiff(newFile,'w');
            setTag(newTiffObj,'ImageLength',tiffInfo.TileLength);
            setTag(newTiffObj,'ImageWidth',tiffInfo.TileWidth);
            setTag(newTiffObj,'Photometric',newTiffObj.Photometric.(tiffInfo.PhotometricInterpretation));
            setTag(newTiffObj,'BitsPerSample',max(tiffInfo.BitsPerSample));
            setTag(newTiffObj,'SamplesPerPixel',tiffInfo.SamplesPerPixel);
            setTag(newTiffObj,'Compression',newTiffObj.Compression.(tiffInfo.Compression))
            setTag(newTiffObj,'MinSampleValue',min(tiffInfo.MinSampleValue));
            setTag(newTiffObj,'MaxSampleValue',max(tiffInfo.MaxSampleValue));
            %             setTag(newTiffObj,'TileWidth',tiffInfo.TileWidth);
            %             setTag(newTiffObj,'TileLength',tiffInfo.TileLength);
            if ~isempty(tiffInfo.XResolution)
                setTag(newTiffObj,'XResolution',tiffInfo.XResolution);
            end
            if ~isempty(tiffInfo.YResolution)
                setTag(newTiffObj,'YResolution',tiffInfo.YResolution);
            end
            setTag(newTiffObj,'ResolutionUnit',newTiffObj.ResolutionUnit.(tiffInfo.ResolutionUnit));
            setTag(newTiffObj,'PlanarConfiguration',newTiffObj.PlanarConfiguration.(tiffInfo.PlanarConfiguration));
            %
            newTiffObj.write(tileDataRaw{iL}); %#ok<*AGROW>
        end
        newTiffObj.close;
        twrite=toc;
        %
        fprintf(1,' -- Tile writing completed with success in %0.2f seconds\n',twrite);
        %
        tTot(idxFile) = tread+twrite;
        fprintf(1,'Processing of filename %s completed in %0.2f seconds\n',sprintf('%s%s',filename,ext),tread+twrite);
        fprintf(1,'%s\n',repmat('-',1,50));
        %
    end
    if isdir(input),
        fprintf(1,'%s\n',repmat('-',1,50));
        fprintf(1,'All files in input folder were processed successfully in %0.2f minutes\n',...
            sum(tTot)/60);
        fprintf(1,'%s\n',repmat('-',1,50));
    end
end
%
return
