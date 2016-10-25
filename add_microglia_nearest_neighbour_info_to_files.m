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

