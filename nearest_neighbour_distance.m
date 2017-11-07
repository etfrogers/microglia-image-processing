function nn_dist = nearest_neighbour_distance(xin,yin)
% ImageJ macro to process dual colour DAB/H images of microglia nd
% calculate various properties.
% Copyright (C) 2017 Edward Rogers
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

points = [xin,yin];
    
    n = size(points,1);
    x = repmat(points(:,1),1,n);
    y = repmat(points(:,2),1,n);
    D = sqrt((x-x').^2+(y-y').^2);
    
    diag_inds = diag(true(size(xin)));
    D(diag_inds) = NaN;
    nn_dist = nanmin(D,[],2);