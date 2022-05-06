clc, clear, close all;
pathfunc = 'Function/Log_Gabor_Templates';
addpath(genpath(pathfunc));
disp('Start generating log garbor templates and masks');
temp_dir = 'gabor_temp/';
mask_dir_g = 'gabor_mask/';
mkdir(temp_dir);
mkdir(mask_dir_g);
in_dir = 'unwrap_en/';
mask_dir = 'mask/';
im = dir([in_dir,'*.jpg']);
for sbj = 1:numel(im)
    image = imread([in_dir, im(sbj).name]);
    mask = imread([mask_dir, im(sbj).name]);
    [template, mask] = encode(image, mask, 1, 22, 1, 0.55);
    imwrite(template, [temp_dir, im(sbj).name]);
    imwrite(mask, [mask_dir_g, im(sbj).name]);
end

in_dir = 'gabor_temp/';   % path of normalized iris images
mask_dir= 'gabor_mask/';
g_score = [];
g_count = 0;
i_score = [];
i_count =0;

disp('Start matching templates');
imtemp = dir([in_dir, '*.jpg']);
for i = 1: (numel(imtemp)-1)
        im1 = imread([in_dir, imtemp(i).name])/255;
        im1mask = imread([mask_dir, imtemp(i).name]);
        label1 = str2double(strtok(imtemp(i).name,'_'));
        disp(sprintf('%d/%d completed', i,numel(imtemp)));
        for j = (i+1):numel(imtemp)
            im2 = imread([in_dir,imtemp(j).name]);
            im2mask = zeros(size(im2));
            label2 = str2double(strtok(imtemp(j).name,'_'));     
            tmp_score = gethammingdistance(im1, im1mask, im2, im2mask, 1);
            if label1 ==label2
                g_score=[g_score, tmp_score];
                g_count= g_count +1;
            else
                i_score=[i_score, tmp_score];
                i_count= i_count +1;
            end

        end % end of sample
end % end of class
disp('Done')
[ver_rate, miss_rate, rates] = produce_ROC_PhD(g_score,i_score);
figure;
h = plot_ROC_PhD(ver_rate, miss_rate, 'r');
result_score = sprintf('wavelength%d_sigmaonf%f_EER:%f',22, 0.55,rates.EER_er);
title('20094686g-DongJiangyuan-','rates');
disp(result_score)
  