function FI = vi7(imgSeqColor, varargin)
%% preparing
[s1,s2,s3,s4] = size(imgSeqColor); % size of the images
%% input params parsing
    r  = 12; % slide size of the guided filter
    alpha = 1.1; % the parameters for the last fusion
    SigD = 0.12; % the Gauss parameters in the weigh map of the detail layer fusion
    p = 4; %
    gSig = 0.2;
    lSig = 0.5;
    wSize = 21;
    stepSize = 2;
    exposureThres = 0.01;
    consistencyThres = 0.15;
    structureThres = 0.80;
    overexposure_pa = 0.5;
    C = 0.03 ^ 2 / 2; % inherited from SSIM
    epsil = 0.25;     % (0.5*1)^2;
    np = s1*s2;
    H = ones(7);      % small average filter is enough
    H = H/sum(H(:));
    Fake_Ref = zeros(s1,s2,s3);
    L = zeros(s1,s2,s4); 
    gMu = zeros(s1, s2, s4);      % global mean intensity
    BaseMu   = zeros(s1, s2, s4); % local mean intensity
    Iones = ones(s1, s2);
    
    
    %% Optimise Ref image
    t_ref = 0.01;
    for i = 1 : s4
        Ig   = rgb2grey(imgSeqColor(:,:,:,i));
         c_t(1) = sum(sum(Ig<t_ref));
         c_t(2) = sum(sum(Ig>1-t_ref));
        c_f(i) = max(c_t)>(s1*s2*overexposure_pa);
    end

    count_seq = 0;
    if length(find(c_f==1))==s4
        refIdx = floor((s4)/2);
        else
        for i = 1:s4
            if c_f(i) == 0
                count_seq = count_seq + 1;
                count_num(count_seq) = i;
                imgSeqColor_Ref(:,:,:,count_seq) = imgSeqColor(:,:,:,i);
            end
        end
        refIdx_count = selectRef(imgSeqColor_Ref); %select ref image
        refIdx = count_num(refIdx_count);
    end


%    refIdx = selectRef(imgSeqColor);
%% SSIM consistency by Kede Ma
    % parameters setting
    numExd = 2*s4-1; %Extending the dataset, to place SSIM structural data. 
    imgSeqColorExd = zeros(s1, s2, s3, numExd); % Create an array to hold new dataset 
    imgSeqColorExd(:,:,:,1:s4) = imgSeqColor; % Take the original width,height,RGB of first s4 times data.
    xIdxMax = s1-wSize+1; % Maximum valid starting indices for windowing operations
    yIdxMax = s2-wSize+1; % This will be the image size ohne padding/ / / /@?#$@#?$@#$?@# 
    window = ones(wSize); %% So this is to create weighted map.
    window3D = repmat(window, [1, 1, 3]); %% Extending 2D map by repeating and making it 3D
    window = window / sum(window(:)); %% Normalize the values?
    window3D = window3D / sum(window3D(:)); 

    %Get local/global average brightness
    % Seckin begin 
    temp3 =  zeros (s1,s2,s3);
    new_con = zeros(xIdxMax, yIdxMax, numExd);
    % Seckin end
      %---consistency index
    temp  = zeros(xIdxMax, yIdxMax, s3); %% Initiate a vector to hold values.
    temp2 = zeros(s1,s2,s3); %% not sure if I added this to see smt? 
    lMu_c   = zeros(xIdxMax, yIdxMax, numExd); % local mean intensity
    lMuSq_c = zeros(xIdxMax, yIdxMax, numExd); % The upper value is to get this value
    for i = 1 : numExd  %% For all the images (source + Extended)
        for j = 1 : s3  %% going for all the channels.          
            temp(:,:,j) = filter2(window, imgSeqColorExd(:, :, j, i), 'valid'); %% 2D Convolution, Averaging.
        end %% Even maybe low-pass filtering? 
        
        temp3 = imgSeqColorExd(:,:,:,i);
        temp3 = mean(temp3,3);
        new_con = filter2(window,temp3,'valid');

        lMu_c(:,:,i) = mean(temp, 3);  % (R + G + B) / 3;
        lMuSq_c(:,:,i) = lMu_c(:,:,i) .* lMu_c(:,:,i); % Mean Square
    end
    sigmaSq = zeros(xIdxMax, yIdxMax, numExd); % signal strength from variance
    for i = 1 : numExd
        for j = 1 : s3
            temp(:,:,j) = filter2(window, imgSeqColorExd(:, :, j, i).*... %% Variance calculation!
                imgSeqColorExd(:, :, j, i), 'valid') - lMuSq_c(:,:,i);
        end
        sigmaSq(:,:,i) = mean(temp, 3);  %%Variance is also averaged over channels? 
                                         %%Why do we not use a gray image
                                         %%or some sort of averaged image
                                         %%instead of doing this?
                                         %%I think it is doable.
                                            
    end
    % The specifications of several parameters mentioned above, such as lMu_c, lMuSq_c, and sigmaSq, 
    % are all the same. They are all used to obtain sigma. This can explain the purpose of sigma
    sigma = sqrt( max( sigmaSq, 0 ) ); % Vanish all negative values to zero! Then obtain the sigma value from variance. 

    % computing structural consistency map
    sMap_c = zeros(xIdxMax, yIdxMax, s4, s4); 
    for i = 1 : s4      
        for j = i+1 : s4  %% Why exactly the loop runs up to s4 but not numExd?
        crossMu = lMu_c(:,:,i) .* lMu_c(:,:,j); % Structural SSIM
       crossSigma = convn(imgSeqColorExd(:, :, :, i).*imgSeqColorExd(:, :, :, j)...
            , window3D, 'valid') - crossMu;  %% WHY DID WE USE 3D now? for regular sigma 2D was enough?
        sMap_c(:,:,i,j) = ( crossSigma + C) ./ (sigma(:,:,i).* sigma(:,:,j) + C); % the third term in SSIM
        end
    end
    sMap_c(sMap_c < 0) = 0; % Why did we eliminate negative values? 
    %sMap_c is now contains 747x1004x6x6 and contains structrual
    %comparasion
    
    sRefMap = squeeze(sMap_c(:,:,refIdx,:)) + sMap_c(:,:,:,refIdx); %% Is Structual map symmetrical so that we can do this? 
    sRefMap(:,:,refIdx) = ones(xIdxMax, yIdxMax); % make the reference 1.
    sRefMap(sRefMap <= structureThres) = 0; %% binarizing the values. 
    sRefMap(sRefMap > structureThres) = 1;
    muIdxMap = lMu_c(:,:,refIdx) < exposureThres | lMu_c(:,:,refIdx) > 1 - exposureThres; %Detecting the deficit parts of image in terms of exposure
    muIdxMap = repmat(muIdxMap, [1, 1, s4]); %% according to reference image a map is generated. 
    sRefMap(muIdxMap) = 1;  %% Structural consistency is overridden in the areas where the pixel is under/over exposed. 
    se = strel('disk',wSize); %% Mathematical morphology is used to make up unrelated 1s and so on.  
    for k = 1 : s4            %% Erosion and dilation.
        sRefMap(:,:,k) = imopen(sRefMap(:,:,k),se);
    end
    clear sMap_c; %% Memory cleaning.
    
    iRefMap = imfConsistency(lMu_c(:,:,1:s4), refIdx, consistencyThres); % First matches the histogram then compares the structures 
    % and returns consistency map.(?)
    % imf = Intensity mapping function

    cMap = sRefMap.*iRefMap;   %Okay so Structural and Intensity (Can I also call it illuminance?)
    % refmaps are element-wise product. Notice both are binary matrixes. 
    [m1,m2,m3] = size(cMap);
    RefMatrix = ones(m1,m2,m3);

   
    cMap(cMap > 1) = 1; %% Why do we do this after all we did cross product of 
    cMap(cMap < 0) = 0;  
    
%      for i=1:s4
%          imwrite(cMap(:,:,i),['E:\erslut\o',num2str(i),'.jpg']);
%      end
%      imwrite(imgSeqColor(:,:,:,refIdx),'E:\erslut\ref.jpg');
%      
    Ig1 = rgb2gray(imgSeqColorExd(:,:,:,refIdx));  %WHY DID YOU DO THIS ?
    Ig1(Ig1 > 1-(t_ref*2)) = 1; %% So High intensity and low intensity values are converted to 1
    Ig1(Ig1 < (t_ref*2)) = 1; %% Normal ones(:d) left as 0. 
    Ig1(Ig1 < 1) = 0; 

        
    for icmp=1:m3
        cMap_seq(:,:,icmp) = imresize(cMap(:,:,icmp),[m1+wSize-1,m2+wSize-1])+Ig1; %%Resizing to original picture by interpolation probably?
    end
    % From the beginning, we start with image without padding, WHY? Don't
    % we lose details? And yet we are making the pic larger. Struggling to
    % see the reason for these.

    % We add our reference gray image in binary form into it.
         
    
    cMap_seq(cMap_seq > 0) = 1; %?? It is binary already? Maybe beacuse of interpolation we generate non-binary
    cMap_seq(cMap_seq < 0) = 0;
     [m1,m2,m3] = size(cMap_seq);
     for i = 1 : m3
        ratio=0.001;%
        area=ceil(ratio*m1*m2);
        tempMap1=bwareaopen(cMap_seq(:,:,i),area);  %% More morphological operations to eliminate small areas 
        tempMap2=1-tempMap1;                        %% of isolated pixels or unwanted regions. 
        tempMap3=bwareaopen(tempMap2,area);         %% So we have only the core parts of structure!
        cMap_seq(:,:,i)=1-tempMap3;                 %% So minor details are vanished I would assume. 
    end
%     cMap_seq = ones(s1,s2,s4);
%     cMap_seq((1+(wSize-1)/2):(s1-(wSize-1)/2),(1+(wSize-1)/2):(s2-(wSize-1)/2),:)=cMap;  
    cMap_seq_3D = ones(s1,s2,s3,s4);
    for i = 1:s3
        cMap_seq_3D(:,:,i,:) = cMap_seq; %%now we made it for all color channels I think.
    end  

    % generating pseudo exposures
    count = 0;
        for i = 1 : s4          
        if i ~= refIdx
            count = count + 1;
            temp = imhistmatch(imgSeqColorExd(:,:,:,refIdx),...
                imgSeqColorExd(:,:,:,i), 256);
            temp( temp<0 ) = 0;
            temp( temp>1 ) = 1;                         %% creating pseudo exposures and storing them as extended data!
            imgSeqColorExd(:,:,:,count+s4) = temp;          
        end
        end
    
    %----色彩明亮匹配 Replace with a bright image patch
     count = 0;
     if (length(find((RefMatrix-cMap)~=0))>m1*m2*m3*consistencyThres)  %% Consistency Check but RefMatrix is just ones.!
        for i = 1:s4
            if i ~= refIdx 
                count = count + 1;
                imgSeqColor(:,:,:,i) = imgSeqColor(:,:,:,i) .* cMap_seq_3D(:,:,:,i) + (imgSeqColorExd(:,:,:,s4 + count) .* ~cMap_seq_3D(:,:,:,i));
            end %% okay replacing it with extended set.
        end
     end
    
%% Decompose the image into a base layer and a detail layer
% base layer
%Initial
for i = 1:s4
    % Decomposition steps
    %---- luminance component
    Ig   = rgb2grey(imgSeqColor(:,:,:,i));  %% Luminance --> converted to weighted grey.
    
     %--- filtered luminance component
    IgPad = padimage(Ig,[3,3]);   %% This time we pad. 

    L(:,:,i) = conv2(IgPad, H, 'valid');  %Small local average brightness (chinese)
    
    %--- global mean intensity
    gMu(:,:,i) = Iones * sum(Ig(:))/np;
    
    %--- local mean intensity (Base layer)
    BaseMu(:,:,i) = fastGF(Ig, r, epsil, 2.5);
    
  
end
    %计算统计
    % computing statistics
    bgMu = zeros(xIdxMax, yIdxMax, s4); % global mean intensity
    for i = 1 : s4
        img = BaseMu(:,:,i);
        bgMu(:,:,i) = ones(xIdxMax, yIdxMax) * mean(img(:));
    end
   
    temp  = zeros(xIdxMax, yIdxMax, s4);
    lMu   = zeros(xIdxMax, yIdxMax, s4); % local mean intensity
    lMuSq = zeros(xIdxMax, yIdxMax, s4);
    for i = 1 : s4
        temp(:,:,i) = filter2(window, BaseMu(:, :,  i), 'valid');
        lMu(:,:,i) = temp(:,:,i); % (R + G + B) / 3;
        lMuSq(:,:,i) = lMu(:,:,i) .* lMu(:,:,i);
    end
    
        sigmaSq = zeros(xIdxMax, yIdxMax, s4); % signal strength from variance
    for i = 1 : s4
            temp(:,:,i) = filter2(window, BaseMu(:, :,  i).*...
                BaseMu(:, :,  i), 'valid') - lMuSq(:,:,i);
        sigmaSq(:,:,i) = temp(:,:,i);   
    end
    sigma = sqrt( max( sigmaSq, 0 ) );
    ed = sigma * sqrt( wSize^2 * s4 ) + 0.001; % signal strengh
    
    % computing weighing map 
    muMap =  exp( -.5 * ( (bgMu - .5).^2 /gSig.^2 +  (lMu - .5).^2 /lSig.^2 ) ); % mean intensity weighting map
    normalizer = sum(muMap, 3);
    muMap = muMap ./ repmat(normalizer,[1, 1, s4]);   

    sMap = ed.^p; % signal structure weighting map
    sMap = sMap + 0.001;
    normalizer = sum(sMap,3);
    sMap = sMap ./ repmat(normalizer,[1, 1, s4]);
    
    maxEd = max(ed, [], 3); %  desired signal strength
    
    % main loop for motion aware fusion
    fI = zeros(s1, s2, s4); 
    countMap = zeros(s1, s2, s4); 
    countWindow = ones(wSize, wSize, s4);
    xIdx = 1 : stepSize : xIdxMax;
    xIdx = [xIdx xIdx(end)+1 : xIdxMax];
    yIdx = 1 : stepSize : yIdxMax;
    yIdx = [yIdx yIdx(end)+1 : yIdxMax];

    offset = wSize-1;
    for row = 1 : length(xIdx)
        for col = 1 : length(yIdx)
            i = xIdx(row);
            j = yIdx(col);
            blocks = BaseMu(i:i+offset, j:j+offset,  :);
            rBlock = zeros(wSize, wSize, s4);
            for k = 1 : s4
                rBlock(:,:,k) = rBlock(:,:,k)  +(sMap(i, j, k) * ( blocks(:,:,k) - lMu(i, j, k) ) / ed(i, j, k));
            end
            if norm(rBlock(:)) > 0
                rBlock = rBlock / norm(rBlock(:)) * maxEd(i, j);
            end
            rBlock = rBlock + sum( muMap(i, j, :) .* lMu(i, j, :) ); 
            fI(i:i+offset, j:j+offset, :) = fI(i:i+offset, j:j+offset, :) + rBlock;
            countMap(i:i+offset, j:j+offset, :) = countMap(i:i+offset, j:j+offset, :) + countWindow;
        end
    end
    fI = fI ./ countMap;
    fI(fI > 1) = 1;
    fI(fI < 0) = 0;   %Base layer processed (chinese)
 
%% Detail layer

%============< Computing Weight Maps  >================%
%--- Detail layer's blending weights
Sig2 = 2*SigD.^2;
dsMap = exp(-1*(L - .5).^2 /Sig2)+1e-6; 
normalizer = sum(dsMap, 3);
dsMap = dsMap ./ repmat(normalizer,[1, 1, s4]); 
%--- Base layer's blending weights
dmuMap =  exp( -.5 * ( (gMu - .5).^2 /gSig.^2 +  (fI - .5).^2 /lSig.^2 ) ); % mean intensity weighting map
normalizer = sum(dmuMap, 3);
dmuMap = dmuMap ./ repmat(normalizer,[1, 1, s4]);


%=====================< Fusion >======================%
FI  = zeros(s1, s2, 3);
% sMap = alpha*sMap;
for j=1:3
    Ist = (squeeze(imgSeqColor(:,:,j,:))-BaseMu); %The Detail Layer :D (chinese)
    FI(:,:,j) = sum((alpha*dsMap.*Ist + dmuMap.*fI),3);
    % dmuMap.*
end
FI(FI > 1) = 1;
FI(FI < 0) = 0;

return

end
