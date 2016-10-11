clear

path = 'extra images\';
stat_file = '_roi_stats.csv';
files = dir([path '*.tif']);

for ii = 1:length(files)
    fname = files(ii).name;
    [~,base, ext] = fileparts(fname);
    
    roi_fname = [base stat_file];
    if exist([path roi_fname], 'file')
        disp(['Processing ' fname])
        img = imread([path fname]);
        assert(ndims(img) == 3);
        assert(any(size(img,3) == [3,4]))
        if size(img,3) == 4
            warning('Four channel image found. Droping channel 4')
        end
        img = img(:,:,1:3);
        figure(ii);
        image(img)
        axis image
        
        [ID,Area,Mean,StdDev,Mode,Min,Max,X,Y,XM,YM,Perim,BX,BY,Width,Height,Major,Minor,Angle,Circ,Feret,IntDen,Median,Skew,Kurt,Area1,RawIntDen,Slice,FeretX,FeretY,FeretAngle,MinFeret,AR,Round,Solidity] = import_roi_file([path roi_fname]);
        density = Area./(Width.*Height);
        
        for jj = 1:length(ID)
            if density(jj)>0.3; 
                col = 'g';
            else
                col = 'y';
            end
            str = sprintf('%d\n%.2f', ID(jj), density(jj));
            text(X(jj),Y(jj),str, 'Color', col, 'HorizontalAlignment', 'center')
            pos = [BX(jj),BY(jj),Width(jj),Height(jj)];
            rectangle('Position',pos, 'EdgeColor', col)
        end
        
        figure(2*ii)
        histogram(density)
    else
        disp(['Skipping ' fname])
    end
    
end

% [ID,Area,Mean,StdDev,Mode,Min,Max,X,Y,XM,YM,Perim,BX,BY,Width,Height,Major,Minor,Angle,Circ,Feret,IntDen,Median,Skew,Kurt,Area1,RawIntDen,Slice,FeretX,FeretY,FeretAngle,MinFeret,AR,Round,Solidity] = import_roi_file('TN347_1_roi_stats.csv',2, 100);