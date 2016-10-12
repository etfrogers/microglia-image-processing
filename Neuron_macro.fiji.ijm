macro "Process DAB Neurons" {
	//currently scale is set to inches. This is meaningless, so let's 
	//remove the scale and use pixels instead
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

	tt = getTitle();
	//print(tt)
	inWidth = getWidth;
	inHeight = getHeight;
	dir = getDirectory("image");
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
	run("Analyze Particles...", "size=100-Infinity display exclude clear add");
	close();
	IJ.renameResults("TempResults"); 
	
	run("Set Measurements...", "integrated redirect='" + tt + "Body mask' decimal=3");
	roiManager("measure")
	SomaArea = newArray(nResults);
	
	for (ii = 0; ii < nResults; ii++) {
		SomaArea[ii] = getResult("IntDen", ii)/255;
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
	done = false;
	for (ii = 0; ii < nResults; ii++) {
		ID = ii+1;
		X = getResult("X", ii);
		Y = getResult("Y", ii);
		Area = getResult("Area", ii);
		Width = getResult("Width", ii);
		Height = getResult("Height", ii);
		density = Area/(Width*Height);
		
		if (SomaArea[ii] < 100) {
			col = 'red';
		}
		else {
			col = 'yellow';
			if (!done) {
				roiManager("select", ii)
				run("Create Mask");
				close;
				//done = true;
				
			}
		}
		roiManager("select", ii)
		Overlay.addSelection(col)
		setColor(col);
		//Overlay.drawRect(getResult("BX", ii), getResult("BY", ii), Width, Height)
		setColor('yellow');
		//Overlay.drawString(ID+"\n"+density, X, Y, 0)
	}
	Overlay.show();
	
}