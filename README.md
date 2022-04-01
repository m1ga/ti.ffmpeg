# Titanium FFMPEG module for Android

## Installation

add
```
repositories {
	maven { url 'https://jitpack.io' }
}
```
to `app/platform/android/build.gradle`

## Example
```js
const ffmpeg = require("ti.ffmpeg");
ffmpeg.info({
	options: "-encoders"
});

ffmpeg.addEventListener("progress", function(e) {});


var file = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, "video.mp4");
var file_out = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, "video_out.mp4");
var file_watermark = Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, "watermark.png");

ffmpeg.run({
	input: file,
	output: file_out,
  watermark: file_watermark,
	options: "-y -b:v 5M -preset ultrafast -g 1 -filter_complex '[0]scale=512:-1' -an",
	success: function(e) {
		// e.file
		// e.duration
	},
	error: function(e) {
    //
	}
})
```

## Author

- Michael Gangolf ([@MichaelGangolf](https://twitter.com/MichaelGangolf) / [Web](http://migaweb.de))

<span class="badge-buymeacoffee"><a href="https://www.buymeacoffee.com/miga" title="donate"><img src="https://img.shields.io/badge/buy%20me%20a%20coke-donate-orange.svg" alt="Buy Me A Coke donate button" /></a></span>
