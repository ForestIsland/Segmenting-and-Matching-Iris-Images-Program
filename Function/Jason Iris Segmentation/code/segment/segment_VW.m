%% Create folders if not existing
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
if ~exist(fail_dir, 'dir')
    mkdir(fail_dir);
end
if ~exist(circle_dir, 'dir')
    mkdir(circle_dir);
end

if save_inter_image
    if ~exist(inter_dir, 'dir')
        mkdir(inter_dir);
    end
end

delete([out_dir, '*']);
delete([fail_dir, '*']);

%%
files = dir([src_dir, '*.', src_type]);
n = length(files);

err_rates = zeros(n, 1);
circles = struct([]);
num_pass = 0;
num_fail = 0;

for i = 1:n %n
    %close all;
    [filename, type] = strtok(files(i).name, '.');
    
    im_src = imread([src_dir, files(i).name]);
    
    % want to see enhanced color image, set last parameter to 3
    
    if hsiz ~= 0
        im_en = enhance_image(im_src, hsiz, gau_size, 1);
    else
        im_en = medfilt2(im_src, [3, 3]);
    end
    if save_inter_image
       imwrite(im_en, [inter_dir, filename, '-enhance.bmp']);
    end
%     im_en = imread([inter_dir, filename, '-enhance.bmp']);
%     im_en = im_en(:, :, 1);
    
    [col, row] = size(im_en);
    
    % get the structure map using local total variation
    im_ad = imadjust(im_en, [0.4, 1], [0, 1]);
    % im_ad = im_en;
    
    % roughly remove obvious reflection
    [im_ad, reflection_region] = remove_reflection(im_ad, 0.8, row*col*0.01);
    
    % RTV-L1
    [edgemap, im_smooth] = get_rtv_l1_contour(im_ad, 0.2, 0.05, 3, 0.005); %0.02, 0.15, 3, 0.005
    if save_inter_image
        imwrite(im_smooth, [inter_dir, filename, '-smooth.bmp']);
    end
%     im_smooth = imread([inter_dir, filename, '-smooth.bmp']);
%     im_smooth = im_smooth(:, :, 1);
%     edgemap = edge(im_smooth);
    
    % find iris and pupil circles based on the structure map
    %[center, radius, center_p, radius_p] = find_circles_UBIRIS(im_en, edgemap, radiusRange, searchRange);
	[center, radius, center_p, radius_p] = find_circles_VW(im_en, edgemap, i_radiusRange, searchRange);

    circles(i).center = center;
    circles(i).center_p = center_p;
    circles(i).radius = radius;
    circles(i).radius_p = radius_p;
    
    
    if save_inter_image
        im_circle = draw_circle(im_en, center(1), center(2), radius);
        im_circle = draw_circle(im_circle, center_p(1), center_p(2), radius_p);
        imwrite(im_circle, [inter_dir, filename, '-circle.jpg']);
    end
    
    % process lower half region
    [mask, thresh_high, thresh_low, cir_correct] = mask_lower_region(im_en, center, radius, extend);
        
    % mask upper_region roughly
    mask = mask_upper_region(im_en, mask, center, radius, thresh_high);
    mask = imfill(mask, 'holes');
    
    reflection = get_reflection_region(im_en, thresh_high);    
    pupil_region = get_pupil_region(im_en, reflection, center_p, radius_p, thresh_low);
    
    % remove pupil and reflection
    mask(pupil_region) = 0;
    mask(reflection) = 0;
    
    [coffs, im_eyelid] = fit_eyelid(im_en, center, radius, center_p, radius_p, [0.3, 1], 'upper', 0, save_inter_image);
    if save_inter_image
        imwrite(im_eyelid, [inter_dir, filename, '-eyelid.jpg']);
    end
    
    % process eyelash and shadow
    mask = process_ES_region(im_en, mask, center, radius, coffs, [0.02, 0.8]);
    
    % eliminate isolated pixels by "open" operation
    se = strel('disk', 4);
    mask = imerode(mask, se);
    
    mask = filter_region(mask);
    
    se = strel('disk', 3); % 3
    mask = imdilate(mask, se);
    
    score = quality(mask, im_en, center, radius, center_p, radius_p);
    if(score > quality_thresh)
        imwrite(mask, [out_dir, filename, '.bmp']);
        num_pass = num_pass + 1;
    else
        imwrite(mask, [fail_dir, filename, '.bmp']);
        num_fail = num_fail + 1;
    end
    
    fprintf('%d/%d processed.\n', i, n);
    
end

for i = 1:n
    center = circles(i).center;
    center_p = circles(i).center_p;
    radius = circles(i).radius;
    radius_p = circles(i).radius_p;
    filename = strtok(files(i).name, '.');
    save([circle_dir, filename, '-circle.mat'], 'center', 'center_p', 'radius', 'radius_p');
end
