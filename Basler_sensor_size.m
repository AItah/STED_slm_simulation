% https://www.thorlabs.com/newgrouppage9.cfm?objectgroup_id=13677#ad-image-0
% 1.6 MP CMOS Compact Scientific Cameras
% basler
% [1,1] to [1080,1440]
% pixel size 3.45 um

Pmin = [1,1];
Pmax = [1080,1440];

H = min(Pmax-Pmin)+1;
W = max(Pmax-Pmin)+1;
sensor_size = [W,H]*3.45; % in milimeters