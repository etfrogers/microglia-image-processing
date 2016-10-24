
function open_roi(file) {
	roiManager("reset");
	roiManager("open", file);
	roiManager("select", 0);
	Roi.getCoordinates(x, y);
	Array.getStatistics(x, minx); 
	Array.getStatistics(y, miny); 
	roiManager("translate", -minx, -miny);
}

macro "Process DAB Neurons [q]" {
	//currently scale is set to inches. This is meaningless, so let's 
	//remove the scale and use pixels instead
	
	//selectWindow("Sholl Results")
	//run("Close");
	tt = getTitle(); 
	if (endsWith(tt, '.tif')) {
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	}

	//print(tt)
	getDimensions(inWidth, inHeight, inChannels, inSlices, inFrames);
	
	dir = getDirectory("image");
	if (lengthOf(dir)==0) {
		dir = getInfo("Location");
		path_end = lastIndexOf(dir, '\\');
		if (path_end == -1)
		{
			Dialog.create("Error: Could not get path")
			Dialog.addMessage("Error finding path. Did you use the select the right window?");
			Dialog.show();
			return;
		}
		dir = substring(dir,0,path_end);
		
	}

	roiManager("reset");
	roiManager("Add");
	roiManager("select", 0);
	
	
	if (inChannels == 3) {
		run("Stack to RGB");
		tt = getTitle(); //need to get it again as it has changed after Stack to RGB 
		roiManager("select", 0)
	}
	
	run("Duplicate...", "title='"+tt+" processed'");
	procWidth = getWidth;
	procHeight = getHeight;
	tt = getTitle(); //need to get it again as it has changed after Stack to RGB 

	dotPos = indexOf(tt, '.');
	base_file = substring(tt, 0, dotPos);
	roiManager("save selected", dir + base_file + '_processed_roi.zip');
	
	
	run("Set Measurements...", "area redirect=None decimal=3");	
	run("Measure");
	saveAs("Results", dir + "\\" + substring(tt, 0, dotPos) + "_roi_properties.csv");
	run("Make Inverse");
	//run("Fill", "slice");
	run("Clear");
	run("Select None");

	run("Colour Deconvolution", "vectors=[H DAB] hide");

	//Analyse H
	selectWindow(tt+"-(Colour_1)");
	open_roi(dir + base_file + '_processed_roi.zip');
	setAutoThreshold("Triangle");
	setThreshold(0, 192);
	//run("Threshold...");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	//run("Close");
	run("Make Binary");
	run("Close-");
	run("Open");
	run("Watershed");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack redirect='" + tt + "' decimal=3");
	run("Analyze Particles...", "size=100-600 circularity=0.50-1.00 display exclude clear add");
	close();
	selectWindow(tt);
	roiManager("Show None");
	//roiManager("Show All");
	Overlay.remove();
	Overlay.clear();
	for (ii = 0; ii < nResults; ii++) {
		col = 'blue';
		
		roiManager("select", ii)
		Overlay.addSelection(col)
		
	}
	newImage(tt + "Body mask" , "8-bit black", procWidth, procHeight, 1);
	
	roiManager("deselect"); 
	roiManager("Fill");
	
	
	
	//Close 3
	selectWindow(tt+"-(Colour_3)");
	close();

	//analyse DAB
	selectWindow(tt+"-(Colour_2)");
	open_roi(dir + base_file + '_processed_roi.zip');
	setAutoThreshold("Huang");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Make Binary");
	run("Close-");
	open_roi(dir + base_file + '_processed_roi.zip');
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack redirect='" + tt + "' decimal=3");
	run("Analyze Particles...", "size=200-Infinity display exclude clear add");
	close();
	IJ.renameResults("TempResults"); 
	
	run("Set Measurements...", "integrated redirect='" + tt + "Body mask' decimal=3");
	roiManager("measure")
	SomaAreaAll = newArray(nResults);
	
	for (ii = 0; ii < nResults; ii++) {
		SomaAreaAll[ii] = getResult("IntDen", ii)/255;
	}
	
	selectWindow("TempResults"); 
   	IJ.renameResults("Results"); 
	close(tt + "Body mask");

	selectWindow(tt);
	roiManager("Show None");
	//roiManager("Show All");
	
	//saveAs("Results", dir + "\\" + base_file + "_roi_stats.csv");
	IdOut = newArray(0);
	SomaArea = newArray(0);
	FeretDiameter = newArray(0);
	for (ii = 0; ii < nResults; ii++) {
		ID = ii+1;
		X = getResult("X", ii);
		Y = getResult("Y", ii);
		Area = getResult("Area", ii);
		Width = getResult("Width", ii);
		Height = getResult("Height", ii);
		FeretDiaLocal = getResult("Feret", ii);
		density = Area/(Width*Height);

		Xp = X; toUnscaled(Xp);
		Yp = Y; toUnscaled(Yp);
		FeretDiap = FeretDiaLocal; toScaled(FeretDiap);
		
		
		if (SomaAreaAll[ii] < 100) {
			col = 'red';
		}
		else {
			col = 'yellow';
			
			roiManager("select", ii)
			run("Create Mask");
			//makeline uses pixel units, but X,Y,FeretDia are in image units.
			makeLine(Xp, Yp, Xp, Yp+FeretDiaLocal);
			run("Sholl Analysis...", "starting=1  radius_step=0 _=[Left of line] #_samples=1 integration=Mean enclosing=1 #_primary=[] fit linear polynomial=[Best fitting degree] most semi-log normalizer=Area ");			
			close; // Sholl plot 1 
			close; // Sholl plot 2 
			close; // original mask
			FeretDiameter = Array.concat(FeretDiameter, FeretDiap);
			SomaArea = Array.concat(SomaArea, SomaAreaAll[ii]);
			IdOut = Array.concat(IdOut, ID);
			Overlay.drawString(ID, Xp, Yp, 0)
		}
		roiManager("select", ii)
		Overlay.addSelection(col)
		setColor(col);
		//Overlay.drawRect(getResult("BX", ii), getResult("BY", ii), Width, Height)
		setColor('yellow');
		//Overlay.drawString(ID, X, Y, 0)
	}
	Overlay.show();
	if (isOpen("Sholl Results"))
		selectWindow("Sholl Results"); 
   		IJ.renameResults("Results"); 
   		MaxBranches = newArray(0);
   		MeanBranches = newArray(0);
   	
		for (ii = 0; ii < lengthOf(IdOut); ii++) {
			MaxBranches = Array.concat(MaxBranches, getResult("Max inters.", ii));
			MeanBranches = Array.concat(MeanBranches, getResult("Mean inters.", ii));
		}

		//SomaArea was calculated on a mask image with no size, so is in pixels.
		//Need to convert to real units, by calling toScaled twice (as once is a length conversion)
		// only the x,y version which tajkes two nputs handles arrays, so use a dummy
		dummy = newArray(lengthOf(SomaArea)); Array.fill(dummy, 0);
		toScaled(SomaArea, dummy); toScaled(SomaArea, dummy);
		
		Array.show("Neuron Properties", IdOut, SomaArea, FeretDiameter, MaxBranches, MeanBranches);
		saveAs("Results", dir + "\\" + substring(tt, 0, dotPos) + "_microglia_properties.csv");
	}_
	else 
	{
		Dialog.create("Warning: No good microglia found")
		Dialog.addMessage("No suitable microglia found for processing");
		Dialog.show();
	}


