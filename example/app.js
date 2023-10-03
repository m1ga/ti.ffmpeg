
const ffmpeg = require("ti.ffmpeg");

var inputFilename = "file1.mp4";
// var inputFilename = "";
var outputFilename = "output_combined.mp4";
var watermark = "watermark.png";
// var watermark = "";

var options = "-filter_complex \"overlay=5:5\" -c:v mpeg4";

// Sample inputs if using multiple input files (specify inputFilename or inputs)
// The option property can be null
var inputs = [
    {input: "cover_start.png", option: "-framerate 30 -t 3 -loop 1"},
    {input: "video1.mp4", option: ""},
    {input: "video2.mp4"},
    {input: "BannerBar.png", option: ""},
];

var inputFiles = inputs.map(function(inputOption) { return inputOption.input });

let window = Ti.UI.createWindow({
    backgroundColor: "backgroundColor",
    title: "ffmpeg test",
    layout: "vertical",
    extendSafeArea: false,
});

// --- sourceView ---

let sourceView = Ti.UI.createView({ top: "40dp", layout: "horizontal", height: "50dp" });

let sourceLabel1 = Ti.UI.createLabel({ text: "Source filename:", textColor: "textColor", width: "45%", height: "50dp", left: 10 });

sourceView.add(sourceLabel1);

let sourceFilename = Ti.UI.createTextField({ value: inputFilename !== "" ? inputFilename : inputFiles.join(", "), width: "45%", height: "50dp", hintText: "Enter source filename", left: 10, autocapitalization: Titanium.UI.TEXT_AUTOCAPITALIZATION_NONE  });

sourceView.add(sourceFilename);

window.add(sourceView);

// --- targetView ---

let targetView = Ti.UI.createView({ top: "10dp", layout: "horizontal", height: "50dp" });

let targetLabel1 = Ti.UI.createLabel({ text: "Target filename:", textColor: "textColor", width: "45%", height: "50dp", left: 10 });

targetView.add(targetLabel1);

let targetFilename = Ti.UI.createTextField({ value: outputFilename, width: "45%", height: "50dp", hintText: "Enter target filename", left: 10, autocapitalization: Titanium.UI.TEXT_AUTOCAPITALIZATION_NONE  });

targetView.add(targetFilename);

window.add(targetView);

// --- watermarkView ---

let watermarkView = Ti.UI.createView({ top: "10dp", layout: "horizontal", height: "50dp" });

let watermarkLabel1 = Ti.UI.createLabel({ text: "Watermark filename:", textColor: "textColor", width: "45%", height: "50dp", left: 10 });

watermarkView.add(watermarkLabel1);

let watermarkFilename = Ti.UI.createTextField({ value: watermark, width: "45%", height: "50dp", hintText: "Enter watermark filename", left: 10, autocapitalization: Titanium.UI.TEXT_AUTOCAPITALIZATION_NONE });

watermarkView.add(watermarkFilename);

window.add(watermarkView);

// --- optionsView ---
//
let optionsView = Ti.UI.createView({ top: "10dp", layout: "vertical", height: "155dp" });

let optionsLabel1 = Ti.UI.createLabel({ text: "ffmpeg options:", textColor: "textColor", width: "95%", height: "30dp", left: 10 });

optionsView.add(optionsLabel1);

let optionsField = Ti.UI.createTextArea({ value: options, borderWidth: 1, width: "95%", wordwrap: true, height: "120dp", left: 10, font: {fontSize: 20} });

optionsView.add(optionsField);

window.add(optionsView);

// --- logView ---
//
let logView = Ti.UI.createView({ top: "10dp", layout: "vertical", height: "155dp" });

let logLabel1 = Ti.UI.createLabel({ text: "Log:", textColor: "textColor", width: "95%", height: "30dp", left: 10 });

logView.add(logLabel1);

let logField = Ti.UI.createTextArea({ value: "", borderWidth: 1, width: "95%", wordwrap: true, height: "120dp", left: 10, font: {fontSize: 12} });

logView.add(logField);

window.add(logView);

// --- successView ---

let successView = Ti.UI.createView({ top: "10dp", height: "120dp" });

let successLabel = Ti.UI.createLabel({ text: "No result...", font: {fontSize: 14}, textAlign: "left", textColor: "textColor", backgroundColor: "backgroundColor", width: "90%", height: Ti.UI.FILL });

successView.add(successLabel);

window.add(successView);

const button = Ti.UI.createButton({
    top: "30dp",
    title: "Run ffmpeg",
    font: {fontSize: 26}
});

window.add(button);

button.addEventListener("click", function() {

    if (ffmpeg == null) {
        return;
    }

    logField.value = "";
    successLabel.text = "No result...";
    successLabel.backgroundColor = "backgroundColor";

    inputFilename = sourceFilename.value != "" ? sourceFilename.value : inputFilename;
    outputFilename = targetFilename.value != "" ? targetFilename.value : outputFilename;
    watermark = watermarkFilename.value;
    options = optionsField.value;

    let file_in = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, inputFilename);
    let file_out = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, outputFilename);
    let file_watermark = watermark !== "" ? Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, watermark) : "";

    var files_in = [];

    for (var i = 0; i < inputs.length; i++) {
        var input = inputs[i];
        Ti.API.info("input, input: " + input.input + ", option: input.option");
        let file = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, input.input);
        if (file != null && file.exists()) {
            files_in.push({input: file.nativePath, option: input.option});
        } else {
            // Might not be a file but an input audio directive like: anullsrc=r=44100:cl=stereo 
            files_in.push({input: input.input, option: input.option});
        }
    }

    // Same as using -y at end of options to remove output file
    if (file_out.exists()) {
        file_out.deleteFile();
    }

    // Use info() to query ffmpeg
    ffmpeg.info({
        options: "-encoders"
    });

    // Specify either:
    // input OR
    // inputs

    ffmpeg.run({
        input: file_in,
        // inputs: files_in,
        output: file_out,
        watermark: file_watermark,
        options: options,
        success: function(e) {
            Ti.API.info("success: " + e.success);
            if (e.success) {
                successLabel.text = "Run succeeded...";
                successLabel.backgroundColor = "green";
            } else {
                successLabel.text = "Run failed...";
                successLabel.backgroundColor = "red";
            }
        },
        error: function(e) {
            Ti.API.info("error: " + JSON.stringify(e));
            Ti.API.info("error, success: " + e.success + ', error: ' + e.error);
            successLabel.text = "Run failed: " + e.error;
            successLabel.backgroundColor = "red";
        },
        log: function(e) {
            Ti.API.info("log: " + e.message);
            logField.value = logField.value + e.message;
        },
        progress: function(e) {
            Ti.API.info("progress, frame: " + e.frame + ", size: " + e.size + ", currentTime: " + e.currentTime);
        }

    });

});

window.open();


