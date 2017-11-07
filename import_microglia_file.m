function [IdOut,SomaArea,TotalArea,CentreXPos,CentreYPos,FeretDiameter,...
    MaxBranches,MeanBranches,Occupancy,NN_dist] ...
    = import_microglia_file(filename, startRow, endRow, ext_file)
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

%% Initialize variables.
delimiter = ',';
if nargin<=2
    startRow = 2;
    endRow = inf;
end
if nargin < 4
    ext_file = false;
end


%% Format string for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: double (%f)
% For more information, see the TEXTSCAN documentation.
if ext_file 
    formatSpec = '%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
else
    formatSpec = '%f%f%f%f%f%f%f%f%[^\n\r]';
end
%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names
IdOut = dataArray{:, 1};
SomaArea = dataArray{:, 2};
TotalArea = dataArray{:, 3};
CentreXPos = dataArray{:, 4};
CentreYPos = dataArray{:, 5};
FeretDiameter = dataArray{:, 6};
MaxBranches = dataArray{:, 7};
MeanBranches = dataArray{:, 8};
if ext_file
    Occupancy = dataArray{:, 9};
    NN_dist = dataArray{:, 10};
end

