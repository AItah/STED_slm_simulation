function img_data = load_grayscale_bmp(filename)
%LOAD_GRAYSCALE_BMP Loads an 8-bit grayscale BMP image and validates its format.
%
%   img_data = load_grayscale_bmp(filename)
%
%   Inputs:
%       filename - A string containing the name or full path of the BMP file.
%
%   Output:
%       img_data - A 2D array (M x N) of type uint8 containing the pixel data (0-255).
%
%   Notes:
%       If the image is not 8-bit grayscale (e.g., RGB), an error is thrown.

    % --- 1. Load the Image ---
    try
        A = imread(filename);
    catch ME
        error('LOAD_GRAYSCALE_BMP:FileError', 'Could not read file "%s". MATLAB error: %s', filename, ME.message);
    end

    % --- 2. Check Data Type and Dimensions ---
    
    % Check if the data type is uint8 (which corresponds to 8 bits)
    if ~strcmp(class(A), 'uint8')
        error('LOAD_GRAYSCALE_BMP:DataType', ...
              'Image data type is "%s", expected "uint8" (8-bit).', class(A));
    end
    
    % Check if the image is grayscale (2 dimensions)
    img_dims = size(A);
    
    if numel(img_dims) == 3
        % If the size is [M x N x 3], it is an RGB image
        error('LOAD_GRAYSCALE_BMP:FormatError', ...
              'Image has 3 dimensions (%s), suggesting an RGB format. Expected grayscale (2 dimensions).', num2str(img_dims));
    elseif numel(img_dims) > 3
        % Check for anything unexpected
        error('LOAD_GRAYSCALE_BMP:FormatError', ...
              'Image has too many dimensions (%d). Expected 2 (grayscale).', numel(img_dims));
    end

    % --- 3. Assign Output ---
    img_data = A;
    
    disp(['Successfully loaded 8-bit grayscale image: ', filename]);
    disp(['Dimensions: ', num2str(size(img_data))]);

end