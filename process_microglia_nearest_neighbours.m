clear;
Ni = 3;
for ii = 1:Ni
    fname = ['extra images' filesep 'TN347_' num2str(ii) '_microglia_properties_ext'];
    [IdOut,SomaArea,TotalArea,X,...
        Y,FeretDiameter,MaxBranches,MeanBranches{ii}, Occupancy{ii}, NN_dist{ii}] = ...
        import_microglia_file([fname '.csv'],2,Inf,true);
    
    
    
    figure(ii)
    subplot(3,1,1)
    histogram(MeanBranches{ii},10);
    m = mean(MeanBranches{ii});
    title(sprintf('Mean: %f', m));
    line(m*[1 1], ylim, 'Color', 'k', 'LineStyle', '--')
    xlim([0,4.5])
    ylabel('Frequency');
    xlabel('Mean Branches');
    
    subplot(3 ,1, 2);
    histogram(Occupancy{ii},10);
    xlim([0,0.8])
    m = mean(Occupancy{ii});
    title(sprintf('Mean: %f', m));
    line(m*[1 1], ylim, 'Color', 'k', 'LineStyle', '--')
    ylabel('Frequency');
    xlabel('Fractional Occupancy');
    
    subplot(3,1,3)
    histogram(NN_dist{ii},10);
    m = mean(NN_dist{ii});
    title(sprintf('Mean: %f', m));
    line(m*[1 1], ylim, 'Color', 'k', 'LineStyle', '--')
    ylabel('Frequency');
    xlabel('Distance to nearest neighbour');
    xlim([0,250])
    
end

for ii = 1:3
    for jj = 1:3
        [hNN(ii,jj),pNN(ii,jj),ciNN(ii,jj,:), statsNN(ii,jj)] = ttest2(NN_dist{ii}, NN_dist{jj});
        [hMean(ii,jj),pMean(ii,jj),ciMean(ii,jj,:), statsMean(ii,jj)] = ttest2(MeanBranches{ii}, MeanBranches{jj});
        [hOcc(ii,jj),pOcc(ii,jj),ciOcc(ii,jj,:), statsOcc(ii,jj)] = ttest2(Occupancy{ii}, Occupancy{jj});
        
    end
end
