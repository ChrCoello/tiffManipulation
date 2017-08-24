function tiffAdjProd(input,output_dir,varargin)
%TIFFADJPROD Adjust contrast of the input tiff image
%This function adjusts the contrast of the input tiff image to remove the
%surrounding "grey" tiles. Only works with tiff files.
%
%Syntaxis: tiffAdjProd(filename,output_dir,logFile,varargin)
%
%Required input arguments:
% -- input      : can be a tiff filename with or without extension, 
%                 or a directory name
% -- output_dir : location where the adjusted tiff will be stored   
%
%Optional input parameters:
% -- sat_pix       : number (0<sat_pix<1). 
%                    Percentage of pixels we accept to saturate in the black 
%                    part of the image (default: 0.05)
% -- make_thumb    : boolean. save a thumbnail version of the input and  processed 
%                   image (default: false)
% -- make_mask     : boolean. save the binary image of the input mask (default:
%                   false)
% -- whole_section : boolean. if true, applies the contrast adjustment to the 
%                    whole section. If false, only applies it to the
%                    outside of the mask (default: true)
% -- suffix        : string. The suffix that is added at the end of the filename
%
% Examples:
% 1/ Remove tiles of 'tg2576_m287_1D1_IV-1_s1.tif' and accept that 0.1% are
%    saturated in the black part of the image and write it in the same folder as
%    'tg2576_m287_1D1_IV-1_s1_adj.tif'
%   >> tiffAdjProd('tg2576_m287_1D1_IV-1_s1.tif','','sat_pix',0.1);
% 2/ Remove tiles of all tiff files in folder Z:\Matlab_scripts\test_data\
%    and write the adjusted files in Z:\Matlab_scripts\test_data_adjusted\ with same
%    filename
%   >> tiffAdjProd('Z:\Matlab_scripts\test_data\','Z:\Matlab_scripts\test_data_adjusted\','suffix','');
%
%   Created:        CC, 05 Feb 2017
%   Last modified : CC, 17 Aug 2017
%
%%% Parse inputs
p = inputParser;
%
make_thumb_dfl = false; 
make_mask_dfl  = false; 
whole_section_dfl = true;
sat_pix_dfl    = 0.05; % in percent
suffix_dfl     = '_adj';
%
%%% Specify input type
addRequired(p,'input',@ischar);
addRequired(p,'output_dir',@ischar);
addParameter(p,'sat_pix',sat_pix_dfl,@isnumeric);
addParameter(p,'make_thumb',make_thumb_dfl,@islogical);
addParameter(p,'make_mask',make_mask_dfl,@islogical);
addParameter(p,'whole_section',whole_section_dfl,@islogical);
addParameter(p,'suffix',suffix_dfl,@ischar);
%
%%% Check inputs
parse(p,input,output_dir,varargin{:});
%
%%% Check on the input
if isdir(input)
    if ~exist(input,'dir')
        error('TiffAdjProd:MissingDir','The directory %s cannot be found',input);
    else
        % Search directory for .tiff or tif files
        OneF  = dir(fullfile(input,'*.tif'));
        TwoF = dir(fullfile(input,'*.tiff'));
        if ~(size(OneF,1)||size(TwoF,1))
            %read the content of the folder
            DirContent = dir(input);
            % remove . and ..
            DirContent(1:2)=[];
            % pick up only folders
            SubFolders = DirContent([DirContent(:).isdir]);
            for iSF = 1 : length(SubFolders)
                input_sub_dir = fullfile(input,SubFolders(iSF).name);
                tiffAdjProd(input_sub_dir,output_dir,varargin{:});
            end
            return
        else
            InputContent = cat(1,OneF,TwoF);
            filenames = fullfile(input,{InputContent(:).name}');
        end
    end
else
    if ~exist(input,'file')
        % Check if it was just the extension that was missing
        [pIn,fnIn,extIn] = fileparts(input);
        if isempty(extIn)
            % Find the file
            if isempty(pIn)
                pIn = pwd;
            end
            DirContent = dir(pIn);
            fN = DirContent(~cellfun('isempty',strfind({DirContent(:).name},fnIn))).name;
            [pIn2,fnIn2,extIn2] = fileparts(fN);
            if ismember(extIn2,{'tif','tiff'})
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
if ~exist(output_dir,'dir')
    [s,mess,messid] = mkdir(output_dir);
    if ~s
        error(messid,mess);
    end
end

%%% Loop on filenames
if ~isempty(filenames)
    %
    nFiles = length(filenames);
    tTot   = zeros(nFiles,1);
    for idxFile = 1 : nFiles
        %
        [pF,filename,ext] = fileparts(filenames{idxFile});
        
        fprintf(1,'%s\n',repmat('-',1,50));
        fprintf(1,'Adjusting histogram for filename %s...\n',sprintf('%s%s',filename,ext));
        %%% Should really only have tif at this point, ut adding a last check
        if ismember(ext,{'.tif','.tiff'})
            % Gather info on the file
            tiffInfo = imfinfo(fullfile(pF,sprintf('%s%s',filename,ext)));
        else
            % Not a tiff, go to the next file
            continue
        end
        %%% Load the Tiff Object
        tiffObj  = Tiff(tiffInfo.Filename,'r');
        % % Tiff Data
        % tiffData = tiffObj.read();

        %%% Create new tiff
        if ~isempty(p.Results.suffix)
            output_fn = sprintf('%s%s',filename,p.Results.suffix);
        else
            output_fn = filename;
        end
        newFile = fullfile(output_dir,sprintf('%s.tif',output_fn));
        %
        newTiffObj = Tiff(newFile,'w'); % 'w8' is for bigTiff, should be clever here
        setTag(newTiffObj,'ImageLength',tiffInfo.Height);
        setTag(newTiffObj,'ImageWidth',tiffInfo.Width);
        setTag(newTiffObj,'Photometric',newTiffObj.Photometric.(tiffInfo.PhotometricInterpretation));
        setTag(newTiffObj,'BitsPerSample',max(tiffInfo.BitsPerSample));
        setTag(newTiffObj,'SamplesPerPixel',tiffInfo.SamplesPerPixel);
        setTag(newTiffObj,'Compression',newTiffObj.Compression.(tiffInfo.Compression))
        setTag(newTiffObj,'MinSampleValue',min(tiffInfo.MinSampleValue));
        setTag(newTiffObj,'MaxSampleValue',max(tiffInfo.MaxSampleValue));
        setTag(newTiffObj,'TileWidth',tiffInfo.TileWidth);
        setTag(newTiffObj,'TileLength',tiffInfo.TileLength);
        setTag(newTiffObj,'XResolution',tiffInfo.XResolution);
        setTag(newTiffObj,'YResolution',tiffInfo.YResolution);
        setTag(newTiffObj,'ResolutionUnit',newTiffObj.ResolutionUnit.(tiffInfo.ResolutionUnit));
        setTag(newTiffObj,'PlanarConfiguration',newTiffObj.PlanarConfiguration.(tiffInfo.PlanarConfiguration));

        %%% Read all the tiles
        fprintf(1,' -- Reading image ...\n');
        %
        tic
        dataRaw = tiffObj.read();
        tread=toc;
        %
        fprintf(1,' -- Image reading completed with sucess in %0.2f seconds\n',tread);
        %
        % Adjust intensity per tile
        sat_pix       = p.Results.sat_pix;
        whole_section = p.Results.whole_section;
        [adjData,maskData,tileTime] = adjustIntensityBW(dataRaw,tiffInfo,sat_pix,whole_section);
        %
        fprintf(1,' -- Writing image ...\n');
%
        tic
%         for iL = 1:tiffObj.numberOfTiles,
        newTiffObj.write(adjData); %#ok<*AGROW>
%         end
        newTiffObj.close;
        % Look for a txt file
        if exist(fullfile(pF,[filename '.txt']),'file')
            copyfile(fullfile(pF,[filename '.txt']),...
                fullfile(output_dir,sprintf('%s.txt',output_fn)));
        end
        % Write thumbnail if requested
        if p.Results.make_thumb
            thumbData = imresize(dataRaw,[256 256*tiffInfo.Width./tiffInfo.Height]);
            if ~exist(fullfile(output_dir,'thumb'),'dir')
                mkdir(fullfile(output_dir,'thumb'));
            end
            imwrite(thumbData,fullfile(output_dir,'thumb',sprintf('%s_orig.png',output_fn)));
            %
            thumbData = imresize(adjData,[256 256*tiffInfo.Width./tiffInfo.Height]);
            imwrite(thumbData,fullfile(output_dir,'thumb',sprintf('%s.png',output_fn)));
        end
        % Write masks if requested
        if p.Results.make_mask
            if ~exist(fullfile(output_dir,'masks'),'dir')
                mkdir(fullfile(output_dir,'masks'));
            end
            imwrite(maskData,fullfile(output_dir,'masks',sprintf('%s.png',output_fn)));
        end
        twrite=toc;
        fprintf(1,' -- Image writing completed with success done in %0.2f seconds\n',twrite);
        %
        %
        tTot(idxFile) = tread+tileTime+twrite;
        fprintf(1,'Adjusting histogram for filename %s completed in %0.2f seconds\n',sprintf('%s%s',filename,ext),tread+tileTime+twrite);
        fprintf(1,'%s\n',repmat('-',1,50));
        %
    end
    fprintf(1,'%s\n',repmat('-',1,50));
    fprintf(1,'All files were processed successfully in %0.2f minutes\n',...
        sum(tTot)/60);
    fprintf(1,'%s\n',repmat('-',1,50));
    %
end
%
return

function [scaleddata,bw4,tileTime] = adjustIntensityBW(slicedata,tiffInfo,sat_pix,whole_section)
% Description needed
%
fprintf(1,' -- Adjusting histogram ...\n');
tic;
%%%%%%%%%%%%%%%%%%%%%%%%
%%% Take care of the low par tof the histogram
%%%%%%%%%%%%%%%%%%%%%%%%
[yRed, xRed]     = imhist(slicedata(:,:,1));
[yGreen, xGreen] = imhist(slicedata(:,:,2)); %#ok<*ASGLU>
[yBlue, xBlue]   = imhist(slicedata(:,:,3));
%
% idxNullRed   = find(xRed(yRed==0), 1, 'last' );
% idxNullGreen = find(xGreen(yGreen==0), 1, 'last' );
% idxNullBlue  = find(xBlue(yBlue==0), 1, 'last' );
%
%%%%%%%%%%%%%%%%%%%%%%%%
%%% Take care of the tiles
%%%%%%%%%%%%%%%%%%%%%%%%
% Find where the peak is
% 
xSum = xRed(ceil(end/2):end-4);
ySum = yRed(ceil(end/2):end-4)+yBlue(ceil(end/2):end-4)+yGreen(ceil(end/2):end-4);
%
idxPic = xSum(ySum==max(ySum));
%
idxPicRed = xRed(yRed==max(yRed((idxPic-15):idxPic)));
%
bw = im2bw(slicedata,(idxPicRed-15)/255);
%
SE = strel('disk', round(tiffInfo.Height/200), 4);
bw2 = imopen(bw, SE);
clear bw
%
bw4 = imfill(~bw2,'holes');
clear bw2
%
for iR = 1:3
    tmp=slicedata(:,:,iR);
    tmp(bw4==0)=255;
    prcMin(iR) = single(prctile(tmp(:),sat_pix))/255;
    slicedata(:,:,iR) = tmp;
end
clear tmp
prcMin = repmat(min(prcMin),1,3);
prcMax = repmat(idxPic/255,1,3);
%%% scaling to the minimum and maximum found
% either the min only or min and mask
fprintf(1,' -- Scaling the minimum value to %0.2f and maximum to %0.2f\n',prcMin(1),prcMax(1));
if whole_section
    scaleddata = imadjust(slicedata,[prcMin; prcMax],[0 0 0;1 1 1]);
else
    scaleddata = imadjust(slicedata,[prcMin; 1 1 1],[0 0 0;1 1 1]);
end
% %
% 
% hF = figure;
% subplot(2,1,1); % Original histogram
% plot(xRed(1:end-4),yRed(1:end-4),'r');hold on;plot(xBlue(1:end-4),yBlue(1:end-4),'b');plot(xGreen(1:end-4),yGreen(1:end-4),'g');
% hold on;
% plot([idxPicRed-15 idxPicRed-15],[0 max(yRed(1:end-4))],'k--');
% %
% [yRed, xRed] = imhist(slicedata(:,:,1));
% [yGreen, xGreen] = imhist(slicedata(:,:,2));
% [yBlue, xBlue] = imhist(slicedata(:,:,3));
% %
% subplot(2,1,2); % Modified histogram
% plot(xRed(1:end-4),yRed(1:end-4),'r');hold on;plot(xBlue(1:end-4),yBlue(1:end-4),'b');plot(xGreen(1:end-4),yGreen(1:end-4),'g');
% hold on;
% plot([idxPicRed-15 idxPicRed-15],[0 max(yRed(1:end-4))],'k--');

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Output
%%%%%%%%%%%%%%%%%%%%%%%%
tileTime=toc;
fprintf(1,' -- Histogram adjusting completed with success in %0.2f seconds\n',tileTime);

return
