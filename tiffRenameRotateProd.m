function tiffRenameRotateProd(input_dir,output_dir,xls_fn,varargin)
%TIFFRENAMEROTATEPROD Rename and rotate the input images
%This function reads the list of the input files in an Excel file and
%rename and rotate the input file. The output filename is also lsited in the
%Excel filename.
%
%   Required input arguments:
%   -- input_dir : string. The directory containing the input images listed in the Excel file.
%   -- output_dir: string. Location where the renamed and/rotated images will be stored.
%   -- xls_fn: Excel file capturing the user input. The format of this file
%       is important and can be found in
%       Z:\HBP_Curation\Operation procedures and
%       templates\OP_Drafts\TE_001_RenamingTemplate.xlsx
%
%   Optional input arguments:
%   -- serie_dsc: the name of the tab in the Excel file
%   -- col_src_txt: the header of the column containing the original section
%   names (default: 'Scanning name')
%   -- col_tgt_txt: the header of the column containing the target section
%   names (default:'Renamed before Navigator')
%   -- col_rot_txt: the header of the column containing the rotation
%   information (default:'Rotation'). This column can contain four different
%   entries :
%       - a digit which captures the angle we want to rotate Ccounterclock
%       wise the image (angle in degrees)
%       - a string: 'FH' or 'FV': flip horizontally or flip vertically
%       - empty or 0: do nothing
%
%   Examples:
%   -- Rotate all the images in folder Z:\Matlab_scripts\test_data\ with an
%   angle defined in the Column 'Rotate' of the sheet '4G8' of the Excel
%   file called Z:\Matlab_scripts\test_data\TE_001_RenamingTemplate.xlsx.
%   Then the images are renamed using the information in the column
%   'Renamed before Navigator':
%      >> tiffRenameRotateProd('Z:\Matlab_scripts\test_data\',...
%       'Z:\Matlab_scripts\test_data\',...
%       'Z:\Matlab_scripts\test_data\TE_001_RenamingTemplate.xlsx',...
%       'serie_dsc','4G8');
%
% CC 14 Feb 2017
% Modified 13 Sep 2017

%%% Parse inputs
p = inputParser;
% Default optional inputs
serie_dsc_dft   = '';
col_src_txt_dft = 'Scanning name';
col_tgt_txt_dft = 'Renamed before Navigator';
col_rot_txt_dft = 'Rotation';
% Required inputs
addRequired(p,'input_dir',@ischar);
addRequired(p,'output_dir',@ischar);
addRequired(p,'xls_fn',@ischar);
% Optional inputs
addParameter(p,'serie_dsc',serie_dsc_dft,@ischar);
addParameter(p,'col_src_txt',col_src_txt_dft,@ischar);
addParameter(p,'col_tgt_txt',col_tgt_txt_dft,@ischar);
addParameter(p,'col_rot_txt',col_rot_txt_dft,@ischar);
% Parse inputs
parse(p,input_dir,output_dir,xls_fn,varargin{:});

%%% Create output directory
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end
%
%%% Look at the Excel file completeness
try
    [xls_st,sheets]=xlsfinfo(xls_fn);
    if isempty(xls_st)
        error('tiffRenameProd:NotExcelFormat','The Excel file %s is not a valid Excel file.',xls_fn);
    end
catch
    error('tiffRenameProd:ExcelNotFound','The Excel file %s could not be found.',xls_fn);
end
% Compare your serie name entry with the ones found in the Excel file
serie_dsc = p.Results.serie_dsc;
if isempty(serie_dsc)
    idx_sh = 1;
    fprintf(1,['\nNo serie description was given as input.',...
        ' Using the first sheet of the Excel file called %s for the renaming.'],sheets{idx_sh});
else
    idx_sh = strcmp(sheets,serie_dsc);
    if any(idx_sh)
        fprintf(1,'The serie %s was found in the Excel file \n',serie_dsc);
    else
        error('tiffRenameProd:SheetnameNotFound',...
            'The serie descriptor %s was not found as a valid sheet name in the Excel filename.',...
            serie_dsc);
    end
end
serie_sh = sheets{idx_sh};
%%% Read the  Excel file
[~, data_txt, data_raw] = xlsread(xls_fn,serie_sh);
if isempty(data_txt)
    error('tiffRenameProd:ContentNotFound',...
        'The sheet %s in the Excel file %s seems empty.',...
        serie_sh,xls_fn);
end
%%% Find row and column number of the source, target and rotation
col_src_txt = p.Results.col_src_txt;
col_tgt_txt = p.Results.col_tgt_txt;
col_rot_txt = p.Results.col_rot_txt;
%
[src_row,src_col]=find(~cellfun('isempty',...
    strfind(data_txt,col_src_txt)));
[tgt_row,tgt_col]=find(~cellfun('isempty',...
    strfind(data_txt,col_tgt_txt)));
[rot_row,rot_col]=find(~cellfun('isempty',...
    strfind(data_txt,col_rot_txt)));
%%% Find the list of files in the sources folder and check there is no
%   discrepency
if isempty(src_row) || isempty(src_col)
    error('tiffRenameProd:SourceColumnNotFound',...
        'The source column headed %s was not found.',col_src_txt);
else
    src_fn = data_txt(src_row+1:end,src_col);
end
if isempty(tgt_row) || isempty(tgt_col)
    error('tiffRenameProd:TargetColumnNotFound',...
        'The target column headed %s was not found.',col_tgt_txt);
else
    tgt_fn = data_txt(tgt_row+1:end,tgt_col);
end
if isempty(rot_row) || isempty(rot_col)
    warning('tiffRenameProd:RotationColumnNotFound',...
        'The rotation column headed %s was not found. Continuing without rotating',col_rot_txt);
else
    %     rot_txt = data_txt(rot_row+1:end,rot_col);
    rot_raw = data_raw(rot_row+1:end,rot_col);
end
%%% Loop over the files to renamed (and rotated)
n_fn = length(src_fn);
fprintf(1,'\nProcessing %0.2d files from serie %s\n',n_fn,serie_sh);
%
for i_fn = 1 : n_fn
    tic
    input_fn = fullfile(input_dir,[src_fn{i_fn} '.tif']);
    if exist(input_fn,'file')
        fprintf('\n - Renaming and rotating file # %0.2d of %0.2d',i_fn,n_fn);
        % Rotation info
        rot_str   = rot_raw{i_fn};
        %
        if ~(isempty(rot_str) || (isnumeric(rot_str)&&rot_str==0) )
            fprintf('\n -- Reading');
            [A,~,tiffInfo]= readTiff(input_fn);
            %
            if ~isnumeric(rot_str)
                if strcmp(rot_str,'FH')
                    fprintf(1,'\n -- Flipping FH');
                    Ar = flip(A,2);
                elseif strcmp(rot_str,'FV')
                    fprintf(1,'\n -- Flipping FV');
                    Ar = flip(A,1);
                else
                    error('tiffRenameProd:RotatationInformationIncorrect',...
                        'I didn''t recognize the rotation information');
                end
            else % it is an angle rotate
                m=memory;
                fprintf(1,'\n -- Memory available: %.0f GBytes',m.MaxPossibleArrayBytes/10^9);
                %
                fprintf(1,'\n -- Rotating %.0f degrees CCW',rot_str);
                Ar = imrotate(A,rot_str,'nearest','loose');
                if ~ismember([-180 -90 0 90 180],rot_str)
                    ss = size(A);
                    clear A
                    T = true(ss);
                    fprintf('\n -- Cleaning borders');
                    m=memory;
                    fprintf(1,'\n -- Memory available: %.0f GBytes',m.MaxPossibleArrayBytes/10^9);
                    Mrot = ~imrotate(T,rot_str);
                    clear T
                    Ar(Mrot&~imclearborder(Mrot)) = 255;
                    clear Mrot
                end
            end
            fprintf('\n -- Writing');
            writeTiff(Ar,fullfile(output_dir,[tgt_fn{i_fn} '.tif']),tiffInfo);
        else
            fprintf('\n -- Renaming only');
            copyfile(input_fn,...
                fullfile(output_dir,[tgt_fn{i_fn} '.tif']));
        end
        % Copy the text file if existing
        if exist(fullfile(input_dir,[src_fn{i_fn} '.txt']),'file')
            copyfile(fullfile(input_dir,[src_fn{i_fn} '.txt']),...
                fullfile(output_dir,[tgt_fn{i_fn} '.txt']));
        end
    else
        fprintf('\n - Skipping file # %0.2d of %0.2d -- not found in input folder',i_fn,n_fn);
    end
end
fprintf(1,'\n Finish with success \n');
%

function [A,tiffObj,tiffInfo]=readTiff(fn)

% Gather info on the file
tiffInfo = imfinfo(fn);
%%% Load the Tiff Object
tiffObj  = Tiff(tiffInfo.Filename,'r');
% % Tiff Data
A = tiffObj.read();
return
%
function writeTiff(Ar,fn,tiffInfo)
%
newTiffObj = Tiff(fn,'w');
setTag(newTiffObj,'ImageLength',size(Ar,1));
setTag(newTiffObj,'ImageWidth',size(Ar,2));
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
newTiffObj.write(Ar); %#ok<*AGROW>
%         end
newTiffObj.close;
return
