function results = run_DSiam(seq,res_path,bSaveImg)

seq = evalin('base', 'subS');

rootdir = '/media/jhvision/cv/JHTBenchmark/trackers/DSiam/';

isDisplay = 1;

% the pretrained network for Dynamic Siamese Network netname: siamfc,vgg19,jointtrain
netname = 'siamfc';
% '1res' denotes the multi-layer DSiam (DSiamM in paper) and uses two layers for tracking
% '0res' denotes the single-layer DSiam (DSiam in paper) and uses the last layer for tracking
nettype = '0res';
results =run_DSiam1(seq,[],isDisplay,rootdir,netname,nettype);
end
