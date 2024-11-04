function fI = Second_depart(B)
    [s1,s2,s3,s4] = size(B);
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
    fI(fI < 0) = 0;
end