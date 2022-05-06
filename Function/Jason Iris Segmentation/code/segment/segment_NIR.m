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

for i = 1:n %50 %n
    %close all;
    %tic
    [filename, type] = strtok(files(i).name, '.');
    
    im_src = imread([src_dir, files(i).name]);
    if hsiz ~= 0
        im_en = enhance_image(im_src, hsiz, gau_size, 1);
    else
        im_en = medfilt2(im_src, [3, 3]);
    end
    if save_inter_image
       imwrite(im_en, [inter_dir, filename, '-enhance.bmp']);
    end
    
%     [tl, th] = cal_hist_two_thresh(im_en(:), [0, 0.9]);
    
    % remove reflection part
%     [col, row] = size(im_src);
%     im_ref = im2bw(im_en, th);
%     im_big = bwareaopen(im_ref, round(col*row/100));
%     im_ref(im_big) = 0;
%     
%     se = strel('disk', 7); %% 8
%     im_fill = imdilate(im_ref, se);
%     im_md = roifill(im_en, im_fill);
    [col, row] = size(im_src);
    [im_md, reflection_region] = remove_reflection(im_en, 0.8, row*col*0.01);
    
    % get the structure map using local total variation
    [edgemap, im_smooth] = get_rtv_l1_contour(im_md, 0.2, 0.05, 3, 0.005);
    %[edgemap, im_smooth] = get_rtv_l1_contour(im_md, lambda, theta, sigma, ep);
    if save_inter_image
        imwrite(im_smooth, [inter_dir, filename, '-smooth.bmp']);
    end
    %im_smooth = imread([smooth_dir, filename, '.bmp']);
    %edgemap = edge(im_smooth);
    
    % find iris and pupil circles based on the structure map
    [center, radius, center_p, radius_p] = find_circles_NIR(im_md, edgemap, p_radiusRange, i_radiusRatio, i_radiusRange, searchRange);
    % [center, radius, center_p, radius_p] = find_circles_CASIA2(im_md, edgemap, radiusRange);
    circles(i).center = center;
    circles(i).center_p = center_p;
    circles(i).radius = radius;
    circles(i).radius_p = radius_p;
    %save([circle_dir, filename, '-circle.mat'], 'center', 'center_p', 'radius', 'radius_p');
    if save_inter_image
        im_circle = draw_circle(im_md, center(1), center(2), radius);
        im_circle = draw_circle(im_circle, center_p(1), center_p(2), radius_p);
        imwrite(im_circle, [inter_dir, filename, '-circle.jpg']);
    end
    
    
    % process lower half region
    [mask, thresh_high, thresh_low, cir_correct] = mask_lower_region(im_md, center, radius, extend);
        
    % mask upper_region roughly
    mask = mask_upper_region(im_md, mask, center, radius, thresh_high);

    %reflection = get_reflection_region(im_src, thresh_high);
    reflection = get_reflection_region(im_en, thresh_high);
    
    pupil_region = get_pupil_region(im_md, reflection, center_p, radius_p, thresh_low);
    
    % remove pupil and reflection
    mask(reflection) = 0;
    mask(pupil_region) = 0;
    
    [coffs, ~] = fit_eyelid(im_md, center, radius, center_p, radius_p, [0.2, 1], 'lower', 0, save_inter_image);
    
    if length(coffs) > 1
        [rs, cs] = size(im_md);
        [X, Y] = meshgrid(1:cs, 1:rs);
        mask(Y > polyval(coffs, X)) = 0;
    end
    
    % fit upper eyelid
    [coffs, im_eyelid] = fit_eyelid(im_md, center, radius, center_p, radius_p, [0.2, 1], 'upper', 0, save_inter_image);
    if save_inter_image
        imwrite(im_eyelid, [inter_dir, filename, '-eyelid.jpg']);
    end
    
    % process eyelash and shadow region
    mask = process_ES_region(im_md, mask, center, radius, coffs, [0.1, 0.8]);
    
    se = strel('disk', 4);
    mask = imerode(mask, se);
    
    mask = filter_region(mask);
    
    se = strel('disk', 2);
    mask = imdilate(mask, se);
    
    score = quality(mask, im_md, center, radius, center_p, radius_p);
    if(score > quality_thresh)
        
        imwrite(mask, [out_dir, filename, '.bmp']);
        num_pass = num_pass + 1;
        %fprintf('%d/%d processed. %f seconds remaining.\n', i, n, toc*(n-i));
    else
        imwrite(mask, [fail_dir, filename, '.bmp']);
        num_fail = num_fail + 1;
        %fprintf('%d/%d processed. failed. %f seconds remaining.\n', i, n, toc*(n-i));
    end
    
    fprintf('%d/%d processed.\n', i, n);
    
end

%err_mean = mean(err_rates);

for i = 1:n
    center = circles(i).center;
    center_p = circles(i).center_p;
    radius = circles(i).radius;
    radius_p = circles(i).radius_p;
    filename = strtok(files(i).name, '.');
    save([circle_dir, filename, '-circle.mat'], 'center', 'center_p', 'radius', 'radius_p');
end

%clear all;