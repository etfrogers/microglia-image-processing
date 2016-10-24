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
	inWidth = getWidth;
	inHeight = getHeight;
	dir = getDirectory("image");
	if (lengthOf(dir)==0) {
		dir = getInfo("Location");
		path_end = lastIndexOf(dir, '\\');
		dir = substring(dir,0,path_end);
	}
	
	run("Colour Deconvolution", "vectors=[H DAB] hide");

	//Analyse H
	selectWindow(tt+"-(Colour_1)");
	setAutoThreshold("Huang");
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
	newImage(tt + "Body mask" , "8-bit black", inWidth, inHeight, 1);
	roiManager("deselect"); 
	roiManager("Fill");
	
	
	
	//Close 3
	selectWindow(tt+"-(Colour_3)");
	close();

	//analyse DAB
	selectWindow(tt+"-(Colour_2)");
	setAutoThreshold("Huang");
	//run("Threshold...");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	//run("Close");
	run("Make Binary");
	run("Close-");
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
	dotPos = indexOf(tt, '.');
	if (dotPos != lengthOf(tt)-4) {
		Dialog.create("Warning: bad file extension")
		Dialog.addMessage("Expected single . in filename and 3 character extension.\nAssuming filename is " + substring(tt, 0, dotPos));
		Dialog.show();
	}
	saveAs("Results", dir + "\\" + substring(tt, 0, dotPos) + "_roi_stats.csv");
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
		
		if (SomaAreaAll[ii] < 100) {
			col = 'red';
		}
		else {
			col = 'yellow';
			
			roiManager("select", ii)
			run("Create Mask");
			makeLine(X, Y, X, Y+FeretDiaLocal);
			run("Sholl Analysis...", "starting=10  radius_step=0 _=[Left of line] #_samples=1 integration=Mean enclosing=1 #_primary=[] fit linear polynomial=[Best fitting degree] most semi-log normalizer=Area ");			
			close; // Sholl plot 1
			close; // Sholl plot 2
			close; // original mask
			FeretDiameter = Array.concat(FeretDiameter, FeretDiaLocal);
			SomaArea = Array.concat(SomaArea, SomaAreaAll[ii]);
			IdOut = Array.concat(IdOut, ID);
			Overlay.drawString(ID, X, Y, 0)
		}
		roiManager("select", ii)
		Overlay.addSelection(col)
		setColor(col);
		//Overlay.drawRect(getResult("BX", ii), getResult("BY", ii), Width, Height)
		setColor('yellow');
		//Overlay.drawString(ID, X, Y, 0)
	}
	Overlay.show();

	selectWindow("Sholl Results"); 
   	IJ.renameResults("Results"); 
   	MaxBranches = newArray(0);
   	MeanBranches = newArray(0);
   	
	for (ii = 0; ii < lengthOf(IdOut); ii++) {
		MaxBranches = Array.concat(MaxBranches, getResult("Max inters.", ii));
		MeanBranches = Array.concat(MeanBranches, getResult("Mean inters.", ii));
	}

	Array.show("Neuron Properties", IdOut, SomaArea, FeretDiameter, MaxBranches, MeanBranches);
}