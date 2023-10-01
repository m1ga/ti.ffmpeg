# Titanium ffmpeg module for iOS

# Github project

[ti.ffmpeg on Github](https://github.com/m1ga/ti.ffmpeg)

This is the iOS counterpart of the ti.ffmpeg module. The iOS version was written by narbs (Christian Clare, Tambit Software).

The Android version was written by m1ga.

# Version of ffmpeg

The ffmpeg xcframework libraries in the platform folder are from the [ffmpeg-kit releases](https://github.com/arthenica/ffmpeg-kit/releases) project.

The current version used in v1.0 is:

ffmpeg-kit-min-6.0-ios-xcframework

This is the min version. Using the min version decreased the module file size to 39.1mb from 62.6mb (full version).

# Example:

The ti.ffmpeg iOS module can be installed by adding the ti.ffmpeg module to tiapp.xml:

``` xml
<module platform="iphone" version="1.0.0">ti.ffmpeg</module>
```

Then require in code. Sample usage is below:

```js
const ffmpeg = require("ti.ffmpeg");

// To output information to the console, use the info method:
ffmpeg.info({
	options: "-encoders"
});

// Specify either a single file name:

let file = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, "video.mp4");

// Or you can specify multiple files, each with their own options:

let inputs = [
    {input: "cover_start.png", option: "-framerate 30 -t 3 -loop 1"},
    {input: "video1.mp4", option: ""},
    {input: "BannerBar.png", option: ""},
];

// If using multiple input files, look up the file path for each file:

var files_in = [];

for (var i = 0; i < inputs.length; i++) {
    var input = inputs[i];
    let file = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, input.input);
    if (file != null && file.exists()) {
        files_in.push({input: file.nativePath, option: input.option});
    } else {
        // Might not be a file but an input audio directive
        files_in.push({input: input.input, option: input.option});
    }
}

let file_out = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, "video_out.mp4");
let file_watermark = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, "watermark.png");

ffmpeg.run({
    // Specify EITHER input OR inputs
	input: file,
    // inputs: files_in,
	output: file_out,
	watermark: file_watermark,
	options: "-filter_complex \"overlay=5:5\" -c:v mpeg4",
	success: function(e) {
        // if (e.success) {
        // ...
        // }
	},
	error: function(e) {
        Ti.API.info("error, success: " + e.success + ', error: ' + e.error);
    },
    log: function(e) {
        Ti.API.info("log: " + e.message);
    },
    progress: function(e) {
        Ti.API.info("progress, frame: " + e.frame + ", size: " + e.size + ", currentTime: " + e.currentTime);
    }
})

```


## Author

- Christian Clare ([@narbs](https://mastodon.social/@narbs) / [@narbs](https://twitter.com/narbs) / [Web](https://www.tambitsoftware.com))

