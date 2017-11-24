function tiffRetileProd(input,tiles_dir,output)
%TIFFRETILEPROD concatenates small tiles into a single high resolution 
%tiled Tiff image.
%Output image are predefined by the width and height of the input. 
%Information of the tiles is found in the metadata of the input.
%
%Syntaxis: tiffRetileProd(input,tiles_dir,output)
%
%Required input arguments:
% -- input     : string. high resolution tiled Tiff image
% -- tiles_dir : string. The folder containing the tiles. The
% format of the tiles' filename should be XXX_tileYYYY.tif where 
% XXX is any string and 
% YYYY is a four digit number telling the index of the tile (i.e 0023) 
% -- output    : string. The output image filename or location where the
% retiled tiff will be stored. The function will create a folder within
% output_dir
% 
%
%Use cases:
% -- retile tifs into one tif 
% -- retile pngs into one tif 
% -- retile tiffs into one png 
% -- retile pngs into one png
%
%Example:
% 1/ Save a tiff file by combining tiles that were generated with
%    tiffTileProd.m >> tiffRetileProd('C:\data\test\tg2576_m287.tif',...
%       'C:\data\test\tg2576_m287_tiles\',...
%       'C:\data\test\tg2576_m287_retiled.tif');
%

%%% Parse inputs
p = inputParser;
%
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
    [input_dir,input_fn,input_ext] = fileparts(input);
    %%% Should really only have tif at this point, ut adding a last check
    if ismember(input_ext,'.tif')
        % Gather info on the file
        tiffInfo = imfinfo(fullfile(input_dir,sprintf('%s%s',input_fn,input_ext)));
        %%% get the Tiff Object info
        tiffObj  = Tiff(tiffInfo.Filename,'r');
    else
        error('tiffRetileProd:InputNotTiff','Are you sure this is the original tiff image?');
    end
    
end
if ~exist(tiles_dir,'dir')
    % there is an extension but the file doesn't exist
    error('TiffAdjProd:MissingFile',...
        'The folder %s cannot be found',tiles_dir);
else
    % Search directory for .tif,.jpg or .png files
    InputContent = cat(1,dir(fullfile(tiles_dir,'*.jpg')),...
        dir(fullfile(tiles_dir,'*.png')),dir(fullfile(tiles_dir,'*.tif')));
    tiles_fn = fullfile(tiles_dir,{InputContent(:).name}');
end
if exist(output,'dir')
    % Get info of the input file
    out_dir = output;
    out_fn  = [input_fn '_retiled'];
    out_ext = input_ext;
else
    % Get info of the input file
    [out_dir,out_fn,out_ext] = fileparts(output);
    if ~exist(out_dir,'dir')
        mkdir(out_dir);
    end
end

%%% Create the new output
newTiffFile = fullfile(out_dir,[out_fn '.tif']);
newTiffObj = Tiff(newTiffFile,'w');
%
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
    %%% Remove Object Prediction from the file name if found
    curr_tile_orig_fn = tiles_fn{idxFile};
    [~,curr_fn,~] = fileparts(curr_tile_orig_fn);
    if strfind(curr_fn,'Object Prediction')
        curr_fn = curr_fn(1:strfind(curr_fn,'Object Prediction')-2);
    end
    %%% Get the tile number
    curr_tile_idx  = sscanf(curr_fn,[curr_fn(1:end-4) '%d']);
    %
    fprintf(1,' -- Tiling tile %d out of %d...\n',curr_tile_idx,nFiles);
    %
    %%% Read the tile data and pad with zeros along dimension 3 (RGB) if
    %%% necessary
    [curr_tile_data,curr_cmap] = imread(curr_tile_orig_fn);
    if size(curr_tile_data,3)==1
        if isempty(curr_cmap)
            if exist('glasbey.mat','file')
                load('glasbey.mat');
                curr_tile_data = ind2rgb8(curr_tile_data,glasbey);
            else
                curr_tile_data = ind2rgb8(curr_tile_data,[1 1 1;lines(255)]);
            end
        else
            curr_tile_data = ind2rgb8(curr_tile_data,curr_cmap);
        end    
    end
    %%% Set tile length just one time
    if idxFile==1
        curr_tile_info = imfinfo(curr_tile_orig_fn);
        setTag(newTiffObj,'TileWidth',curr_tile_info.Width);
        setTag(newTiffObj,'TileLength',curr_tile_info.Height);
    end
    newTiffObj.writeEncodedTile(curr_tile_idx,curr_tile_data);
    %
end
%
fprintf(1,'%s\n',repmat('-',1,50));
fprintf(1,'%s\n',repmat('-',1,50));
newTiffObj.close;
%
if ~strcmp(out_ext,'.tif')
   fprintf(1,'Converting output to %s\n',out_ext);
   fprintf(1,'%s\n',repmat('-',1,50));
   tmpT = Tiff(newTiffFile,'r');
   T = tmpT.read();
   tmpT.close();
   imwrite(T,fullfile(out_dir,[out_fn out_ext])); 
   delete(newTiffFile);   
end
%
fprintf(1,'Tiling tiles finished with success\n');
fprintf(1,'%s\n',repmat('-',1,50));
%
return
