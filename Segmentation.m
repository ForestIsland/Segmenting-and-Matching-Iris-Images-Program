% This file includes three parts: Segmentation, Normalization, Enhancement
pathfunc = 'Function/Jason Iris Segmentation';
addpath(genpath(pathfunc));
%% Iris Image Segmentation
extend = [0.7, 1.3];       % faction of radius to be collect to calculate threshold
p_radiusRange = [20, 60];    % possible range of radius of pupil circle
i_radiusRatio = [1.5, 3.5];  % possible ratio of iris circle radius to the pupil circle radius
i_radiusRange = [70, 130];   % possible range of radius of iris circle
searchRange = 10;           % search range for center of iris circle
src_type = 'jpg';          % file type of source image
hsiz = 0;                 % parameter for SSR enhancement, 0 for no enhancement;
quality_thresh = 0.4;
% Please end all the paths with "/" or "\"
src_dir = 'casiav3_origin_demo/';   % path of source images
out_dir = 'additional/casiav3/mask/'; % path of output directory
fail_dir = 'additional/casiav3/failed/';
circle_dir = 'additional/casiav3/circles/';
save_inter_image = true;   % save internal results or not. if yes, assign following
                            % folder values.
inter_dir = 'additional/casiav3/inter/';
segment_NIR;

%% Image and mask normalization and enhancement
global DIAGPATH             % Global variable that is needed in the following
DIAGPATH = '.';
blocksize = 16;
mkdir('mask');
mkdir('unwrap');
mkdir('unwrap_en');
im = dir('casiav3_origin_demo/*.jpg');
for i = 1:numel(im)
    imname = strtok(im(i).name, '.');
    cirname = [imname, '-circle.mat'];
    d = load(['additional/casiav3/circles/', cirname]);
    temp = imread(['casiav3_origin_demo/', im(i).name]);     % Original eye image
    if exist(['additional/casiav3/mask/', im(i).name],'file')
        mask = imread(['additional/casiav3/mask/', im(i).name]);
        [mask_normalized, ~] = normaliseiris(double(mask), d.center(1), d.center(2), d.radius, ...
            d.center_p(1), d.center_p(2), d.radius_p, 'output_image', 64, 512);
         mask = logical(mask_normalized);
         mask = ~mask;
    else
        mask = zeros(size(temp));
        [mask, ~] = normaliseiris(double(mask), d.center(1), d.center(2), d.radius, ...
            d.center_p(1), d.center_p(2), d.radius_p, 'output_image', 64, 512);
    end;
    imwrite(mask, ['mask/', im(i).name]);
    % The following function "normaliseiris" is originally available in Masek's implementation: http://www.peterkovesi.com/studentprojects/libor/
    % We also provide it in this folder for convenience.
    [im_normalized, ~] = normaliseiris(double(temp), d.center(1), d.center(2), d.radius, ...
            d.center_p(1), d.center_p(2), d.radius_p, 'output_image', 64, 512);
    
    imwrite(im_normalized, ['unwrap/', im(i).name]);
    
    % Enhancement 
    imUn = double(im_normalized);
    [row, col] = size(imUn);
    rowCou= row/blocksize;
    colCou= col/blocksize;
    imMean = zeros(rowCou, colCou);
    
    for k = 1:rowCou*colCou
        rowIn = floor((k-1)/colCou);
        colIn = mod((k-1), colCou);
        imSq = imUn((rowIn*blocksize+1):(rowIn*blocksize+blocksize),(colIn*blocksize+1):(colIn*blocksize+blocksize));
        vaMean = mean(imSq(:));
        imMean(rowIn+1, colIn+1) = vaMean;
    end;
    
    imMean = imresize(imMean, size(imUn), 'bicubic');
    imUn = imUn - imMean;
    imUn = imUn -min(imUn(:));
    imUn = imUn/max(imUn(:));
    imtest = histeq(imUn);
    imwrite(imtest,['unwrap_en/', im(i).name]);
 
end;