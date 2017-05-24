function outIm = tiffResizeProd(input,output,varargin)
%tiffResize Change the size of a tiff image
%   This function will change the size (column and row) of inputIm. The
%   size of the new image will be harvested from the refIm or, if refIm is
%   left empty, from the Option imSize. Output name is generated
%   automatically adding the suffix '_resize' if outputIm is left empty.
% Required input/output description : 
% -- input  : input can be an image file name or a folder
% -- output : input can be an empty string (''), an image file name or a folder
% Parameter description :
% -- imSize : scalar or 2x1 vector
%            if scalar then the image x and y number of pixels will be modified to
%            newX = imSize * X and newY = imSize * Y
%            if vector then the image will be resized to the size
%            [imSize(1) imSize(2)]. If one enters NaN as one of the two
%            value of the vector, the algorithm will rescale the non NaN to
%            the desired size and resize the other while keeping the
%            proportion of the image
% -- refIm  : file name
%            the size of the the resized image can be copied directly from
%            a reference image defined with this option
% -- interp : string
%            the type of interpolation to use. Possible choices : 
%            {'nearest','bilinear','bicubic','box','lanczos2','lanczos3'}
%
%
% Example of use
% -- Resize the image called colbert.tif to have a width (column) of 1024 pixels 
%   - outIm = tiffResizeProd('colbert.tif','colbert_1024.tif','imSize',[NaN 1024])
%   Original: CC, 02/01/2017


% Parse inputs
p = inputParser;
defaultRefIm  = '';
defaultImSize = 1;  % scalar or vector
defaultSufIm  = 'resize';
defaultOutFmt = '';
%
defaultInterp  = 'nearest';
expectedInterp = {'nearest','bilinear','bicubic','box','lanczos2','lanczos3'};
%
addRequired(p,'input',@ischar);
addRequired(p,'output',@ischar);
addParameter(p,'refIm',defaultRefIm,@ischar);
addParameter(p,'sufIm',defaultSufIm,@ischar);
addParameter(p,'outfmt',defaultOutFmt,@ischar);
addParameter(p,'imSize',defaultImSize,@isnumeric);
addParameter(p,'interp',defaultInterp,@(x) any(validatestring(x,expectedInterp)));
%
parse(p,input,output,varargin{:});
%
% Check existence of inputs
%%% Check on the input
formatsAvail = imformats();
if isdir(input)
    if ~exist(input,'dir')
        error('TiffAdjProd:MissingDir','The directory %s cannot be found',input);
    else
        % Search directory for .tiff or tif files
        InputContent = dir(input);
        listFiles = {InputContent(:).name}';
        % Beautiful way to get indexes of all the patterns in a cell string
        fun = @(s)~cellfun('isempty',strfind(listFiles,s));
        out = cellfun(fun,[formatsAvail(:).ext],'UniformOutput',false);
        idxToKeep = any(horzcat(out{:}),2);
        %
        InputContentImages = InputContent(idxToKeep);
        filenames = fullfile(input,{InputContentImages(:).name}');
    end
else
    % Check if it was just the extension that was missing
    [pIn,fnIn,extIn] = fileparts(input);
    if ~exist(input,'file')
        if isempty(extIn)
            % Find the file
            if isempty(pIn)
                pIn = pwd;
            end
            DirContent = dir(pIn);
            fN = DirContent(~cellfun('isempty',strfind({DirContent(:).name},fnIn))).name;
            [pIn2,fnIn2,extIn2] = fileparts(fN);           
            if ismember(extIn2(2:end),[formatsAvail(:).ext]) % 2 for removeing the initial dot
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
% Check output
if ~isempty(p.Results.refIm)
    if ~exist(p.Results.refIm,'file')
        error('MATLAB:resizeImages:FileNotFound','Couldn''t find the file %s',p.Results.refIm);
    else
        Ref    = imfinfo(p.Results.refIm);
        dim_ref = [Ref.Height Ref.Width];
    end
else
    scale_im = p.Results.imSize;
end
%
nFiles = length(filenames);
%
for idxFile = 1 : nFiles
    %
    [pInL,fnInL,extInL] = fileparts(filenames{idxFile});
    fprintf(1,'%s\n',repmat('-',1,50));
    fprintf(1,'Resizing filename %s \n',sprintf('%s%s',fnInL,extInL));
    % Get file information
    InInfo  = imfinfo(filenames{idxFile});
    currDim = [InInfo.Height InInfo.Width];
    % Read the image: tiff or rest
    if strcmp(InInfo.Format,'tif'),
        %%% Load the Tiff Object
        tiffObj = Tiff(InInfo.Filename,'r');
        inData  = tiffObj.read();
    else
        inData  = imread(filenames{idxFile});
    end
    % Deal with the reshape
    if isempty(p.Results.refIm)
        outputSize = zeros(1,2);
        if isscalar(scale_im),
            outputSize = currDim * scale_im;
        else
            % Deal with the input as vector
            if all(isnan(scale_im)),
                outputSize = currDim;
            elseif any(isnan(scale_im)),
                outputSize(isnan(scale_im))  = scale_im(~isnan(scale_im)) * currDim(isnan(scale_im))/currDim(~isnan(scale_im));
                outputSize(~isnan(scale_im)) = scale_im(~isnan(scale_im));
            else
                outputSize = scale_im;
            end
        end
    else
        outputSize = dim_ref;
    end
    % Be sure we have integers
    outputSize = ceil(outputSize);
    % Reshape
    fprintf(1,'Input size : \n  height (lines) = %d\n  width (columns) = %d\n',InInfo.Height,InInfo.Width);
    fprintf(1,'Output size: \n  height (lines) = %d\n  width (columns) = %d\n',outputSize(1),outputSize(2));
    scaledData = imresize(inData,outputSize,p.Results.interp);
    % Prepare and write output
    sufIm = p.Results.sufIm;
    if ~isempty(p.Results.outfmt)
        extOut = ['.' p.Results.outfmt];
    else
        extOut = extInL;
    end
    if isdir(output)
        outIm = fullfile(output,sprintf('%s_%s%s',fnInL,sufIm,extOut));
    else
        if isempty(output)
            outIm = fullfile(pInL,sprintf('%s_%s%s',fnInL,sufIm,extOut));
        else
            [pOut,fOut,extOutt]=fileparts(output);
            if ~isempty(pOut) && ~exist(pOut,'dir')
                mkdir(pOut);
            end
            if isempty(pOut)
                pOut = pInL;
            end
            
            if isempty(extOutt)
                outIm = fullfile(pOut,sprintf('%s%s',fOut,extOut));
            else
                outIm = fullfile(pOut,sprintf('%s%s',fOut,extOutt));
            end
        end
    end
    %
    if strcmp(extOut,'.tif')
        newTiffObj = Tiff(outIm,'w');
        setTag(newTiffObj,'ImageLength',outputSize(1));
        setTag(newTiffObj,'ImageWidth',outputSize(2));
        setTag(newTiffObj,'Photometric',newTiffObj.Photometric.(InInfo.PhotometricInterpretation));
        setTag(newTiffObj,'BitsPerSample',max(InInfo.BitsPerSample));
        setTag(newTiffObj,'SamplesPerPixel',InInfo.SamplesPerPixel);
        setTag(newTiffObj,'Compression',newTiffObj.Compression.(InInfo.Compression))
        setTag(newTiffObj,'MinSampleValue',min(InInfo.MinSampleValue));
        setTag(newTiffObj,'MaxSampleValue',max(InInfo.MaxSampleValue));
        setTag(newTiffObj,'TileWidth',InInfo.TileWidth);
        setTag(newTiffObj,'TileLength',InInfo.TileLength);
        setTag(newTiffObj,'PlanarConfiguration',newTiffObj.PlanarConfiguration.(InInfo.PlanarConfiguration));
        % Set the resolution meta data
        setTag(newTiffObj,'ResolutionUnit',newTiffObj.ResolutionUnit.(InInfo.ResolutionUnit));
        x_res = InInfo.XResolution * outputSize(1) / InInfo.Height;
        setTag(newTiffObj,'XResolution',x_res);
        y_res = InInfo.YResolution * outputSize(2) / InInfo.Width;
        setTag(newTiffObj,'YResolution',y_res);
        % Write and close
        newTiffObj.write(scaledData); %#ok<*AGROW>
        newTiffObj.close;
    else
        imwrite(scaledData,outIm);
    end
    %
    % Done
    fprintf(1,'Resizing filename %s -- done\n',sprintf('%s%s',fnInL,extInL));
    fprintf(1,'%s\n',repmat('-',1,50));
    %
end

return
