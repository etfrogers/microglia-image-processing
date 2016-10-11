macro "Process DAB Neurons" {
	//currently scale is set to inches. This is meaningless, so let's 
	//remove the scale and use pixels instead
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

	tt = getTitle();
	dir = getDirectory("image");
	run("Colour Deconvolution", "vectors=[H DAB] hide");
	selectWindow(tt+"-(Colour_1)");
	close();
	selectWindow(tt+"-(Colour_3)");
	close();
	selectWindow("TN347_1.tif-(Colour_2)");
	setAutoThreshold("Huang");
	//run("Threshold...");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	//run("Close");
	run("Make Binary");
	run("Close-");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack redirect=" + tt + " decimal=3");
	run("Analyze Particles...", "size=200-Infinity display exclude clear add");
	close();
	selectWindow(tt);
	roiManager("Show None");
	roiManager("Show All");
	dotPos = indexOf(tt, '.');
	if (dotPos != lengthOf(tt)-4) {
		Dialog.create("Warning: bad file extension")
		Dialog.addMessage("Expected single . in filename and 3 character extension.\nAssuming filename is " + substring(tt, 0, dotPos));
		Dialog.show();
	}
	saveAs("Results", dir + "\\" + substring(tt, 0, dotPos) + "_roi_stats.csv");
		
}