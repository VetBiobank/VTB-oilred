/* Macro for calculating Area of oilred staining on microscopy images
 * 
 * Input: Microscopy Images (tif, jpg, png), oilred stained, optional hematoxylin counter stained nuclei
 * Process: color deconvolution to seperate oilred staining and measure stained area
 * measured color-vectors: oilred [1], nuclei [2], background [3]: [r1]=0.145216 [g1]=0.685399 [b1]=0.713540 [r2]=0.629769 [g2]=0.668531 [b2]=0.395546 [r3]=0.578353 [g3]=0.597890 [b3]=0.555008
 * empirical threshold for oilred-staining: [0-200]
 * Outpu: Datasheet (xls|csv) with measured values of area. if scale is set correctly, it refers µm, otherwise it is only for relative measurements
 * SK / VetBiobank / VetCore / Vetmeduni Vienna 2021
 * 
 */

// Create interactive Window to set variables for input/output folder, input/output suffix, scale factor, subfolder-processing
#@ String (visibility=MESSAGE, value="Choose your files and parameter", required=false) msg1
#@ File (label = "Input directory", style = "directory") input_folder
#@ File (label = "Output directory", style = "directory") output_folder
#@ String (label = "File suffix input", description=".mrxs not supported!", choices={".jpg",".png",".tif"}, style="radioButtonHorizontal") suffix_in
#@ String (label = "File output") output_file
#@ String (label = "File suffix output", choices={".xls",".csv"}, style="radioButtonHorizontal") suffix_out
#@ String (visibility=MESSAGE, value="Olympus 500µm: 20x = 2715px; 40x = 5430px") msg2
#@ Integer (label = "Scale 500 µm = X Px", value=20) scale_px
#@ String (label = "Include subfolders", choices={"no","yes"}, style="radioButtonHorizontal") subfolders

// prepare and clear logs, set measurements
run("Set Measurements...", "area mean min integrated limit display redirect=None decimal=1");
newImage("temp", "8-bit white", 1, 1, 1);
run("Measure");
run("Clear Results"); // clear results
print("\\Clear"); // clear log
selectWindow("temp");
run("Close");


processFolder(input_folder);
processSaveResults(output_folder,output_file,suffix_out);


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input_folder) {
	filelist = getFileList(input_folder);
	filelist = Array.sort(filelist);
	for (i = 0; i < filelist.length; i++) {
		
		// process recursion for subfolders if option "Include subfolders" is true
		if(subfolders=="yes"){
		if(File.isDirectory(input_folder + File.separator + filelist[i]))
			processFolder(input_folder + File.separator + filelist[i]);}
			
		// for images with correct suffix proceed with function processFile()
		if(endsWith(filelist[i], suffix_in))
			processFile(input_folder, output_folder, filelist[i]);
		
		run("Close All");
		run("Collect Garbage");
	}
}


// function to open file, color deconvolute and measure area of oilred channel
function processFile(input_folder, output_folder, file) {

open(input_folder + "\\" + file);

// get title of image and rename jpg for results list
imageTitle = getTitle();
plain_title = getTitle();
plain_title = replace(plain_title, "\\" + suffix_in, "");

// set scale for image
run("Set Scale...", "distance=" + scale_px + " known=500 unit=µm global");

// seperate oilred
run("Colour Deconvolution", "vectors=[User values] [r1]=0.145216 [g1]=0.685399 [b1]=0.713540 [r2]=0.629769 [g2]=0.668531 [b2]=0.395546 [r3]=0.578353 [g3]=0.597890 [b3]=0.555008");
selectWindow(imageTitle + "-(Colour_2)");
run("Close");
selectWindow(imageTitle + "-(Colour_3)");
run("Close");
selectWindow(imageTitle + "-(Colour_1)");
rename(plain_title + "-oilred");
run("8-bit");

// set threshold and measure oilred
setThreshold(0, 200);
run("Threshold...");
run("Measure");

}


// function to save results table in predefined output-file
function processSaveResults(output_folder,output_file,suffix_out) {
	selectWindow("Results");
	saveAs("Text", output_folder + "\\"+output_file+suffix_out);
	print("data saved");
}
