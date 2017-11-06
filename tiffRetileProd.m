function tiffRetileProd(input,tiles_dir,output)
%
% Function: concatenates tiles into a tiff file. Tiles are predefined by the
% width and height of the original images. Information of the tiles is
% found in the metadata of the tiff file
%
% Syntaxis: tiffRetileProd(input,tiles_dir,output)
%
% Inputs
%   input (required): can be a directory name or a tiff filename with or
%   without extension
%   output_dir (required):  location where the adjusted tiff(s) will be stored.
%   The function will create a folder within output_dir
% Otpional input
%   tile_size : specify the tile size as vector [height width]
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
% default_output_size = [NaN NaN];
%%% Specify input type
addRequired(p,'input',@ischar);
addRequired(p,'tiles_dir',@ischar);
addRequired(p,'output',@ischar);
%
%%% Check inputs
parse(p,input,tiles_dir,output); %,varargin{:});
%
%%% Check on the input
if ~exist(input,'file')
    % there is an extension but the file doesn't exist
    error('TiffAdjProd:MissingFile',...
        'The file %s cannot be found',input);
else
    % Get info of the input file
    [pF,filename,ext] = fileparts(input);
    %%% Should really only have tif at this point, ut adding a last check
    if ismember(ext,{'.tif','.tiff'})
        % Gather info on the file
        tiffInfo = imfinfo(fullfile(pF,sprintf('%s%s',filename,ext)));
    else
        error('tiffRetileProd:InputNotImage','Are you sure this an image?');
    end
    %%% Load the Tiff Object
    tiffObj  = Tiff(tiffInfo.Filename,'r');
end
if ~exist(tiles_dir,'dir')
    % there is an extension but the file doesn't exist
    error('TiffAdjProd:MissingFile',...
        'The folder %s cannot be found',tiles_dir);
else
    % Search directory for .tiff or tif files
    TwoF = dir(fullfile(tiles_dir,'*.tiff'));
    OneF = dir(fullfile(tiles_dir,'*.tif'));
    InputContent = cat(1,OneF,TwoF);
    tiles_fn = fullfile(tiles_dir,{InputContent(:).name}');
end
if exist(output,'dir')
    % Get info of the input file
    out_dir = output;
    out_fn  = [filename '_retiled'];
    out_ext = ext;
else
    % Get info of the input file
    [out_dir,out_fn,out_ext] = fileparts(output);
end

%%% Create the new output
newFile = fullfile(out_dir,[out_fn out_ext]);
newTiffObj = Tiff(newFile,'w');

setTag(newTiffObj,'ImageLength',tiffObj.getTag('ImageLength'));
setTag(newTiffObj,'ImageWidth',tiffObj.getTag('ImageWidth'));
setTag(newTiffObj,'Photometric',tiffObj.getTag('Photometric'));
setTag(newTiffObj,'BitsPerSample',max(tiffInfo.BitsPerSample));
setTag(newTiffObj,'SamplesPerPixel',tiffInfo.SamplesPerPixel);
setTag(newTiffObj,'Compression',newTiffObj.Compression.(tiffInfo.Compression))
setTag(newTiffObj,'MinSampleValue',min(tiffInfo.MinSampleValue));
setTag(newTiffObj,'MaxSampleValue',max(tiffInfo.MaxSampleValue));
if ~isempty(tiffInfo.XResolution)
    setTag(newTiffObj,'XResolution',tiffInfo.XResolution);
end
if ~isempty(tiffInfo.YResolution)
    setTag(newTiffObj,'YResolution',tiffInfo.YResolution);
end
setTag(newTiffObj,'ResolutionUnit',newTiffObj.ResolutionUnit.(tiffInfo.ResolutionUnit));
setTag(newTiffObj,'PlanarConfiguration',newTiffObj.PlanarConfiguration.(tiffInfo.PlanarConfiguration));


%%% Loop on tiles

nFiles = length(tiles_fn);

for idxFile = 1 : nFiles
    %
    fprintf(1,'%s\n',repmat('-',1,50));
    curr_tile_fn = tiles_fn{idxFile}; 
    [~,curr_fn,~]=fileparts(curr_tile_fn);
    curr_tile_idx  = sscanf(curr_fn,[curr_fn(1:end-4) '%d']);
    fprintf(1,' -- Tiling tile %d out of %d...\n',curr_tile_idx,nFiles);
    
    %
    curr_tile_data = imread(curr_tile_fn);
    curr_tile_info = imfinfo(curr_tile_fn);
    
    if idxFile==1
        setTag(newTiffObj,'TileWidth',curr_tile_info.Width);
        setTag(newTiffObj,'TileLength',curr_tile_info.Height);
    end
    newTiffObj.writeEncodedTile(curr_tile_idx,curr_tile_data);
    %
%     fprintf(1,' -- Tile reading completed with success in %0.2f seconds\n',tread);
    %
    %if all(isnan(p.Results.tile_size)),

    

    %
end

newTiffObj.close;
%
return
