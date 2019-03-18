% -------------------------------------------------------------------------------------------------------------------------
function [newTargetPosition, bestScale, score,responseMap,score_pos] = tracker_eval(net_x, s_x, corrfeat,...
    x_crops, targetPosition, window,p)

%TRACKER_STEP
%   runs a forward pass of the search-region branch of the pre-trained Fully-Convolutional Siamese,
%   reusing the features of the exemplar z computed at the first frame.
%
%   Luca Bertinetto, Jack Valmadre, Joao F. Henriques, 2016
% -------------------------------------------------------------------------------------------------------------------------
% forward pass, using the pyramid of scaled crops as a "batch"
%     net_x.conserveMemory = false;

if strcmp(p.nettype,'1res')        
    net_x.eval({p.netconv_input{1}, corrfeat{1},p.netconv_input{2},corrfeat{2},p.netconv_img, x_crops});
    % get score maps before fusion
%     scoreMaps = gather(net_x.vars(p.scoresId).value);
 
else
    net_x.eval({p.netconv_input{1}, corrfeat{1},p.netconv_img, x_crops});
    % get score maps before fusion
%     scoreMaps = gather(net_x.vars(p.scoreId).value);
end
responseMaps = gather(net_x.vars(p.scoreId).value);
responseMaps = reshape(responseMaps, [p.scoreSize p.scoreSize p.numScale]);        
responseMapsUP =single(zeros(p.scoreSize*p.responseUp, p.scoreSize*p.responseUp, p.numScale));

if p.numScale>1
    currentScaleID = ceil(p.numScale/2);
    bestScale = currentScaleID;
    bestPeak = -Inf;
    for s = 1:p.numScale
        if p.responseUp > 1
            responseMaps_(:,:,s) =  imresize(responseMaps(:,:,s), p.responseUp, 'bicubic');
            responseMapsUP(:,:,s) = responseMaps_(:,:,s);
            thisResponse = responseMapsUP(:,:,s);
            % penalize change of scale
            if s~=currentScaleID, thisResponse = thisResponse * p.scalePenalty; end
            thisPeak = max(thisResponse(:));
            if thisPeak > bestPeak, bestPeak = thisPeak; bestScale = s; end
            score = bestPeak;
        else
            responseMapsUP(:,:,s) = responseMaps{1}(:,:,s);
        end
    end
    responseMap = responseMapsUP(:,:,bestScale);
else
    responseMap = responseMapsUP;
    bestScale = 1;    
    score = max(responseMap(:));
end
% make the response map sum to 1
responseMap = responseMap - min(responseMap(:));
responseMap = responseMap / sum(responseMap(:));

% apply windowing
responseMap = (1-p.wInfluence)*responseMap + p.wInfluence*window;

[r_max, c_max] = find(responseMap == max(responseMap(:)), 1);
[r_max, c_max] = avoid_empty_position(r_max, c_max, p);
p_corr = [r_max, c_max];

score_pos = p_corr./p.responseUp;
% Convert to crop-relative coordinates to frame coordinates
% displacement from the center in instance final representation ...
disp_instanceFinal = p_corr - ceil(p.scoreSize*p.responseUp/2);
% ... in instance input ...
disp_instanceInput = disp_instanceFinal * p.totalStride / p.responseUp;

% ... in instance original crop (in frame coordinates)
disp_instanceFrame = disp_instanceInput * s_x / p.instanceSize;

% position within frame in frame coordinates
newTargetPosition = targetPosition + disp_instanceFrame;
end

function [r_max, c_max] = avoid_empty_position(r_max, c_max, params)
    if isempty(r_max)
        r_max = ceil(params.scoreSize/2);
    end
    if isempty(c_max)
        c_max = ceil(params.scoreSize/2);
    end
end
