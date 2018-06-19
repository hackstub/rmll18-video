document.getElementById('player').outerHTML = `
<video id="player" width="698px"
controls poster="assets/images/banner.png">
<p>Ça marche pas :(</br>Reportez vous sur les autres options de stream citées ci dessous</p>
</video>`;

var video = document.getElementById('player');
if(Hls.isSupported()) {
    var hls = new Hls();
    hls.loadSource('https://stream.passageenseine.fr/index.m3u8');
    hls.attachMedia(video);
    hls.on(Hls.Events.MANIFEST_PARSED,function() {
    });
}
// hls.js is not supported on platforms that do not have Media Source Extensions (MSE) enabled.
// When the browser has built-in HLS support (check using `canPlayType`), we can provide an HLS manifest (i.e. .m3u8 URL) directly to the video element throught the `src` property.
// This is using the built-in support of the plain video element, without using hls.js.
    else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = 'https://stream.passageenseine.fr/index.m3u8';
        video.addEventListener('canplay',function() {
        });
}
