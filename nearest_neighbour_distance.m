function nn_dist = nearest_neighbour_distance(xin,yin)

points = [xin,yin];
    
    n = size(points,1);
    x = repmat(points(:,1),1,n);
    y = repmat(points(:,2),1,n);
    D = sqrt((x-x').^2+(y-y').^2);
    
    diag_inds = diag(true(size(xin)));
    D(diag_inds) = NaN;
    nn_dist = nanmin(D,[],2);