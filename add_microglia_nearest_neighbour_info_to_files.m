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
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
clear;

path = uigetdir;

files = dir([path filesep '*_microglia_properties.csv']);
fnames = {files.name};
for ii = 1:length(fnames)
    [~, fname,~] = fileparts(fnames{ii});
    [IdOut,SomaArea,TotalArea,X,...
        Y,FeretDiameter,MaxBranches,MeanBranches] = ...
        import_microglia_file([path filesep fname '.csv']);
    
    CircArea = pi*(FeretDiameter/2).^2;
    Occupancy = TotalArea./CircArea;
    
    NN_dist = nearest_neighbour_distance(X,Y);
    
    
    fname_ext = [path filesep fname '_ext.csv'];
    if exist(fname_ext, 'file')
        delete(fname_ext);
    end
    
    fid = fopen(fname_ext, 'w');
    oldheaders = 'IdOut,SomaArea,TotalArea,CentreXPos,CentreYPos,FeretDiameter,MaxBranches,MeanBranches';
    fprintf(fid, '%s,%s,%s\r\n', oldheaders, 'Occupancy','Dist to NN');
    fclose(fid);
    dlmwrite(fname_ext, [IdOut,SomaArea,TotalArea,X, ...
        Y,FeretDiameter,MaxBranches,MeanBranches, ...
        Occupancy, NN_dist], '-append');
end

