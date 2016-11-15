
function open_roi(file, pull_to_zero, new_window) {
	if (new_window)
	{
		open(file);
		roiManager("add");
	} else
	{
		roiManager("reset");
		roiManager("open", file);
		roiManager("select", 0);
	}
	
	//if required, shift the ROI to the top left of the image - useful when working with cropped images
	if (pull_to_zero) {
		Roi.getCoordinates(x, y);
		Array.getStatistics(x, minx); 
		Array.getStatistics(y, miny); 
		roiManager("translate", -minx, -miny);
	}

	//find a scaling factor file and, if one exists, load it.
	dotPos = indexOf(file, '.');
	roi_file = substring(file, 0, dotPos);
	fname_sf = roi_file+"_sf.txt";
	if (File.exists(fname_sf)) {
		s = File.openAsString(fname_sf);
		scaleFactor = parseInt(s);
	} else
	{
		scaleFactor = 1;
	}

	//now apply any scaling needed.
	type = selectionType(); 
    getSelectionCoordinates(x, y); 
    
    for (i = 0; i < x.length; i++) { 
           x[i] = x[i] * scaleFactor; 
           y[i] = y[i] * scaleFactor; 
    } 
    roiManager("reset");

     
    makeSelection(type, x, y); 
    roiManager("add")
    roiManager("select", 0);
}



function get_current_dir() {
	dir = getDirectory("image");

	//method above fails for vsi files imported with bioformats, so try a backup method
	if (lengthOf(dir)==0) {
		dir = getInfo("Location");
		path_end = lastIndexOf(dir, File.separator);
		if (path_end == -1)
		{
			dir = "";
		} else {
			dir = substring(dir,0,path_end);
		}
		
	}
	return dir;
}

macro "Process from saved ROI" {
	process_from_saved_roi(false);
}

function process_from_saved_roi(in_script) {
	tt = getTitle(); 

	dir = get_current_dir();
	dotPos = indexOf(tt, '.');
	base_file = substring(tt, 0, dotPos);
	fname = dir + File.separator() + base_file + '_roi_for_processing.zip';
	
	if (File.exists(fname)) {
		open_roi(fname, in_script, false); // need to pull to zero if not called interactively, as we now load cropped image in "process_directory"
		process_dab_microglia();
		return true;
	}else
		return false;
	
}

macro "Save ROI for processing [Q]" {
	tt = getTitle(); //need to get it again as it has changed after Stack to RGB 

	roiManager("reset");
	roiManager("Add");
	roiManager("select", 0);
	dir = get_current_dir();
	dotPos = indexOf(tt, '.');
	base_file = substring(tt, 0, dotPos);
	roiManager("save selected", dir + File.separator() +base_file + '_roi_for_processing.zip');
	vsiPos = indexOf(tt,"vsi");
	if (vsiPos >= 0)
	{
		hashPos = indexOf(tt,"#");
		imageNoString = substring(tt, hashPos+1, lengthOf(tt));
		scaleFactor = pow(2,parseInt(imageNoString)-1);
		
		f = File.open(dir + File.separator() + base_file + '_roi_for_processing_sf.txt'); 
   		print(f, scaleFactor);
   		File.close(f);

   		Roi.getBounds(x, y, width, height)
   		bounds_str = "" + x + ',' + y + ',' + width + ',' + height;
   		f = File.open(dir + File.separator() + base_file + '_roi_for_processing_bounds.txt'); 
   		print(f, bounds_str);
   		File.close(f);

	}
}

macro "Process directory" {
dir = getDirectory("Choose a directory");


setBatchMode(true); 
list = getFileList(dir);

for (i = 0; i < list.length; i++) {
	fname = list[i];
	if (endsWith(fname, ".tif"))
	{ 
		open(dir+fname);
		
		didrun = process_from_saved_roi(false);
		
		close();
		
		//if (didrun) 
			//close();
		
	} else if (endsWith(fname, ".vsi"))
	{
		dotPos = indexOf(fname, '.');
		base_file = substring(fname, 0, dotPos);
		roi_fname = dir + File.separator() + base_file + '_roi_for_processing.zip';
	
		if (File.exists(roi_fname)) {
			//newImage("Untitled", "8-bit black", 5000, 5000, 1);
			//open_roi(roi_fname, false, true);

			s = File.openAsString(dir + File.separator() + base_file + '_roi_for_processing_sf.txt');
			sf = parseInt(s);
			
			bounds_str = File.openAsString(dir + File.separator() + base_file + '_roi_for_processing_bounds.txt');
			bounds = split(bounds_str, ',');
			x = parseInt(bounds[0]); y = parseInt(bounds[1]); 
			width = parseInt(bounds[2]); height = parseInt(bounds[3]);

			x = x*sf; y = y*sf; width = width*sf; height = height*sf; 
			
			//close();
			run("Bio-Formats Importer", "open=[" + dir + File.separator() + fname + "] color_mode=Default crop display_metadata rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1 x_coordinate_1="+x+" y_coordinate_1="+y+" width_1="+width+" height_1="+height);
			process_from_saved_roi(true);
		}
		//close();
		//close();
	}    
}
setBatchMode(false);
}
macro "Process DAB Microglia [q]" {
	process_dab_microglia();
}

function process_dab_microglia() {
	//selectWindow("Sholl Results")
	//run("Close");
	tt = getTitle(); 
	if (endsWith(tt, '.tif')) {
		//currently scale is set to inches. This is meaningless, so let's 
		//remove the scale and use pixels instead
	
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	}

	//print(tt)
	getDimensions(inWidth, inHeight, inChannels, inSlices, inFrames);

	dir = get_current_dir();
	if (lengthOf(dir) == 0) {
		Dialog.create("Error: Could not get path")
		Dialog.addMessage("Error finding path. Did you use the select the right window?");
		Dialog.show();
		return;
	}

	ROIType = selectionType();
	useROI = (ROIType != -1);
	if (!useROI)
	{
		Dialog.create("Warning: No selection")
		Dialog.addMessage("There is no region of interest selected. Select OK to use whole image, or cancel to abort");
		Dialog.show();
		makeRectangle(0, 0, inWidth, inHeight);
	} 
	

	roiManager("reset");
	roiManager("Add");
	roiManager("select", 0);
	
	
	if (inChannels == 3) {
		run("Stack to RGB");
		tt = getTitle(); //need to get it again as it has changed after Stack to RGB 
		roiManager("select", 0)
	}

	if (isOpen(tt + " processed")){
		close(tt + " processed");
	}
	run("Duplicate...", "title='"+tt+" processed'");
	procWidth = getWidth;
	procHeight = getHeight;
	tt = getTitle(); //need to get it again as it has changed after Stack to RGB 

	dotPos = indexOf(tt, '.');
	base_file = substring(tt, 0, dotPos);
	roiManager("save selected", dir + base_file + '_processed_roi.zip');
	
	
	run("Set Measurements...", "area redirect=None decimal=3");	
	run("Clear Results");
	run("Measure");
	saveAs("Results", dir + File.separator() + substring(tt, 0, dotPos) + "_roi_properties.csv");

	/* if we have an ROI and it is not a rectangle, we need to blank the area outside.
	 * A saved rectangle seems to be loaded as a 4-sided polygon, so we need some way of 
	 * allowing for this
	 * Use a check that the area of the ROI is less than the area of the image (width*height)
	 * getResult give area in physcial units. I convert to pixels by calling toUnscaled twice (for area)
	 * The floating point calculation give errors, so make it rn clear if it's less than 99% of the size.
	 * If this sometimes doesn't clear when it should, the effect should be negligible.
	 */
	ROI_area = getResult("Area", 0);
	toUnscaled(ROI_area); toUnscaled(ROI_area);
	
	if (useROI && ROIType != 0 && (ROI_area < (procWidth*procHeight*0.99))) {
		run("Make Inverse");
		run("Clear");
		run("Select None");
	}
	run("Colour Deconvolution", "vectors=[H DAB] hide");

	//Analyse H
	selectWindow(tt+"-(Colour_1)");
	open_roi(dir + base_file + '_processed_roi.zip', true, false);
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
	setForegroundColor(255,255,255);
	roiManager("Fill");
	
	
	
	//Close 3
	selectWindow(tt+"-(Colour_3)");
	close();

	//analyse DAB
	selectWindow(tt+"-(Colour_2)");
	open_roi(dir + base_file + '_processed_roi.zip', true, false);
	setAutoThreshold("Huang");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Make Binary");
	run("Close-");
	open_roi(dir + base_file + '_processed_roi.zip', true, false);
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
	
	//saveAs("Results", dir + File.separator() + base_file + "_all_microglia_stats.csv");
	IdOut = newArray(0);
	SomaArea = newArray(0);
	FeretDiameter = newArray(0);
	CentreXPos = newArray(0);
	CentreYPos = newArray(0);
	TotalArea = newArray(0);
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
			TotalArea = Array.concat(TotalArea, Area);
			CentreXPos = Array.concat(CentreXPos, X);
			CentreYPos = Array.concat(CentreYPos, Y);
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
		// only the x,y version which takes two inputs handles arrays, so use a dummy
		dummy = newArray(lengthOf(SomaArea)); Array.fill(dummy, 0);
		toScaled(SomaArea, dummy); toScaled(SomaArea, dummy);
		
		Array.show("Microglia Properties", IdOut, SomaArea, TotalArea, CentreXPos, CentreYPos, FeretDiameter, MaxBranches, MeanBranches);
		selectWindow("Microglia Properties");
		saveAs("Results", dir + File.separator() + substring(tt, 0, dotPos) + "_microglia_properties.csv");
	}_
	else 
	{
		Dialog.create("Warning: No good microglia found")
		Dialog.addMessage("No suitable microglia found for processing");
		Dialog.show();
	}

}


