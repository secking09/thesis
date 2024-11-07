%% Multi-exposure fusion 
%Version 5 for both motional and static image
%By Liang Chang, Mingyao Zheng and Zhiqin Zhu
%Chongqing University of Post and telecommunication
clc, clear, close all;

% Defining support functions folder
support_functions = 'support functions';

%% change directory
prev_dir = pwd; file_dir = fileparts(mfilename('fullpath')); 
% cd(file_dir);
addpath(genpath(pwd));
% Adding support functions
addpath(fullfile(prev_dir,support_functions));
%% read source image sequence

fileLists = dir(imgDirPath);% ���������ļ���
disp('      ��ʼ������');
%for i=3:length(fileLists)
    
%fprintf('Processing the %d......\n',i-2);
%subPath = strcat(imgDirPath,'/',fileLists(i).name);
    %finalMaskPath = strcat(subPath,'\finalMask');
  

%imagePath = '.\test pictures';
imgSeqColor = loadImg(imgDirPath,0.2); % use im2double
imgSeqColor = reorderByLum(imgSeqColor);

imgSeqColor = downSample(imgSeqColor, 1024);

%% multi-exposure image fusion

tic;
FI = vi7(imgSeqColor);
toc;
%figure,imshow(FI);
%imwrite(FI,'D:\Mathworkplace\V6\V5\results\7.jpg');
imwrite(FI,['/home/sg24duk/git/thesis/vision7_code/h4_005_28_10_2024_first_data/pano_cam1_front/wb/lowgain/result/',num2str(i-2),'.jpg'])

%end

% 1��BaseMu
% 2.fI
% 3.��ȨfI