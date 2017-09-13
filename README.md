# tiffManipulation
A set of Matlab function to manipulate high resolution microscopic images

## Resizing images
Function name: **tiffResizeProd.m**
### High level description:
Change the size of an image (tiff or other)   

This function will change the size (column and row) of inputIm. The size of the new image will be harvested from the refIm or, if refIm is left empty, from the Option imSize. Output name is generated automatically adding the suffix `_resize` if outputIm is left empty.

### Required input arguments:
- input  : string. It can be an image file name or a folder , or a directory containing exclusively directories
- output : string. It can be an empty string ('') to write in the same folder as input, an image file name or a folder

### Optional input arguments:
- imSize: scalar or 2x1 vector
    * if scalar then the image x and y number of pixels will be modified to newX = imSize * X and newY = imSize * Y
    * if vector then the image will be resized to the size [imSize(1) imSize(2)]. If one enters NaN as one of the two value of the vector, the algorithm will rescale the non NaN to the desired size and resize the other while keeping the proportion of the image

- interp: string. The type of interpolation to use. Possible choices :
               {'nearest','bilinear','bicubic','box','lanczos2','lanczos3'}

- refIm: string (filename). The size of the the resized image can be copied directly from a reference image defined with this option (default: '')
- suffix: string. The suffix that is added at the end of the filename
- outfmt  : string. Any image format for output (default: same as input)
- istiled : boolean. if true, the tif output will be tiled (default: false)
- export_json : boolean. if true, will export a json file containing the image size of the inut and output files (default: false)

### Examples:
- Resize the image called Mtg01_bl1_4G8_s078.tif to have a width (column) of 1024 pixels:
```matlab
>> tiffResizeProd('Mtg01_bl1_4G8_s078.tif','Mtg01_bl1_4G8_s078.png','imSize',[NaN 1024])
```
- Reduce by a factor 2 all the images in folder Z:\\Matlab_scripts\\test_data\\ and place them in the folder Z:\\Matlab_scripts\\test_data_half_size\\:
```matlab
>> tiffResizeProd('Z:\\Matlab_scripts\\test_data\\','Z:\\Matlab_scripts\\test_data_half_size\\','imSize',0.5)
```
- Reduce all the tiff images in folder Z:\\Matlab_scripts\\test_data\\, to have a width (column) of 1024 pixels, change format to png, keeping the same image name and place them in the folder Z:\\Matlab_scripts\\test_data_half_size\\:
```matlab
>> tiffResizeProd('Z:\\Matlab_scripts\\test_data\\',...
'Z:\\Matlab_scripts\\test_data_half_size\\',...
'imSize',[NaN 1024],'outfmt','png','suffix','');
```

## Removing tiles from the border of the microscopic section

## Renaming and rotating images

## Creating tiles from a single image
