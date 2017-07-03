//---------------------------Image Replacement Code Begins---------------------------------
//A required Variable for the loadImages() function
loadedImages = null
/**
 * loadImages() accepts a list of file names to load into cache.
 * For each file name it creates a new image object and begins
 * downloading the file into the browser's cache. 
 **/
function loadImages(){
   var img
   if (document.images){
      if (!loadedImages) loadedImages = new Array()
      for (var i=0; i < arguments.length; i++){
         img = new Image()
         img.src = arguments[i]
         loadedImages[loadedImages.length] = img
      }
   }   
}

/**
 * flip(imgName, imgSrc) sets the src attribute of a named
 * image in the current document. The function must be passed
 * two strings. The first is the name of the image in the document
 * and the second is the source to set it to.
 **/
function flip(imgName, imgSrc){
   if (document.images){
      document[imgName].src = imgSrc
   }
}
//Fix Netscape resize bug for mouseDown and mouseUp events.
function forceReload() {
      location.reload()
}
function fixNetscape4(){
   NS4 = document.layers
   NSVer = parseFloat(navigator.appVersion)
   if (NSVer >= 5.0 || NSVer < 4.1) NS4 = false

   if (NS4) onresize = forceReload
}
//---------------------------Image Replacement Code Ends-----------------------------------