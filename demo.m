% DEMO_TRACKING

% choose the path to the videos (you'll be able to choose one with the GUI)
base_path='/media/cjh/datasets/tracking/OTB100';
% ask the user for the video
[video_path,video] = choose_video(base_path);
if isempty(video_path), return, end  %user cancelled
[img_files, pos, target_sz, ground_truth, video_path,len] = load_video_info_OTB(video_path);

rootdir = '/media/cjh/cvpaper/git/DSiam-matlab/';
seq = struct('name',video,'path',strcat(base_path,'/',video,'/'),'startFrame',1,'endFrame',len,'nz',4,'ext','jpg','init_rect', [0,0,0,0]);

seq.len = seq.endFrame - seq.startFrame + 1;
seq.s_frames = cell(seq.len,1);
nz	= strcat('%0',num2str(seq.nz),'d'); %number of zeros in the name of image
for i=1:seq.len
    image_no = seq.startFrame + (i-1);
    id = sprintf(nz,image_no);
    seq.s_frames{i} = strcat(seq.path,'img/',id,'.',seq.ext);
end

rect_anno = dlmread([seq.path 'groundtruth_rect.txt']);
seq.init_rect = rect_anno(seq.startFrame,:);
isDisplay = 1;

% the pretrained network for Dynamic Siamese Network netname: siamfc,vgg19,jointtrain
netname = 'siamfc';
% '1res' denotes the multi-layer DSiam (DSiamM in paper) and uses two layers for tracking
% '0res' denotes the single-layer DSiam (DSiam in paper) and uses the last layer for tracking
nettype = '0res';
run_DSiam1(seq,[],isDisplay,rootdir,netname,nettype);
