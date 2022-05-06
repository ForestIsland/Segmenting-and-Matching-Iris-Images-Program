# Biometrics Identification Using Iris
## Problem Details
Two or more publicly accessible iris image databases are to be used to ascertain accuracy for the iris recognition using more accurate iris segmentation algorithms. The task is to achieve iris segmentation and investigate the performance improvement:

1. The purposek is to use [CASIA v3 Iris database](http://www.cbsr.ia.ac.cn/english/IrisDatabase.asp) to segment region of interest from iris images. There are two files(segmentation.m, matching.m) which should be run as the following guidelines. Visualize the intermediate results to ascertain accuracy of localization with reference to given iris images. You should open the intermediate results folder (additional\casiav3\inter) to view :
    - (i) location of pupil boundaries, 
    - (ii) location of sclera boundaries, 
    - (iii) location of pupil diameter, 
    - (iv) location of sclera diameter, 
    - (v) location of eyelashes and eyelid. 
   
   The matching accuracy using ROC and EER will help to estimate the performance.
2. You can also download and use [PolyU Cross Spectral Iris Database](http://www4.comp.polyu.edu.hk/~csajaykr/polyuiris.htm) or [NICE I (Noisy Iris Challenge
Evaluation Part I )](http://nice1.di.ubi.pt) or choose [IIT Delhi Iris Database](http://www4.comp.polyu.edu.hk/~csajaykr/IITD/Database_Iris.htm).
## Guideline for Segmenting and Matching Iris Images in CASIAV3 Database
1. All the test images should be placed in the folder named casiav3_origin_demo. You can find 200 images in it, and those samples are selected from the left eye images of first 25 subjects in CASIA v3 dataset. If you want to use your own selected images, please rename jpg files in the same manner and put them in this folder.
2. You should next run the program segmentation.m which will be able to complete segmentation,
unwrapping the segmented images, enhancement, generation of templates and respective masks.
These (intermediate) results will be posted in the following folders:
    - unwrap: unwrapped and segmented iris images.
    - unwrap_en: enhanced unwrapped iris images.
    - mask: unwrap masks
    - additional: circles, masks generated during the segmentation process.

    The change in the code downloaded from ICCV 2015 reference [2]: In find_circles_NIR.m, the
edge detection is changed from sobel to canny. The original code is edge(im, ‘sobel’, [], ‘vertical’).
It is changed to edge(im, ‘canny’, 0.05).
3. Once you have successfully segmented and visualized results from above steps, you should run
matching to ascertain verification accuracy using all-to-all protocol. You can run matching.m to
match segmented iris images and plot the ROC. The IrisCode approach using 1D log-Gabor filters
(not 2D log-Gabor filters) is [publicly available implementation](http://www.peterkovesi.com/studentprojects/libor/). The matching.m program will generate the templates and generate the matching scores using the
respective masks. The templates and masks are placed in the following folders:
    - gabor_temp: templates
    - gabor_mask: masks

## References
1. [A. Kumar and A. Passi, “Comparison and combination of iris matchers for reliable personal authentication,” Pattern Recognition, vol. 43, no. 3, pp. 1016-1026, March 2010](http://www4.comp.polyu.edu.hk/~csajaykr/myhome/papers/PR_10_2.pdf).
2. [Z. Zhao and A. Kumar, “An accurate iris segmentation framework under related imaging constraints,” Proc. ICCV 2015, pp. 3829-3836, Santiago, Chile, December 2015](http://www4.comp.polyu.edu.hk/~csajaykr/myhome/papers/ICCV15_Final.pdf)

    [Segmentation Code](http://www4.comp.polyu.edu.hk/~csajaykr/tvmiris.htm)

