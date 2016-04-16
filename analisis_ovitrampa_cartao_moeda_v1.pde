/*

 Projecto para el monitoreo comunitario de dengue
 Script para analisis de imagenes de ovitrampas
 
 
 Oda Scatolini - 16/04/2016
 
 odascatolini@gmail.com
 
 */


PImage original;
PImage circleDetected;
PImage roi;
PImage thresholded;

//Blue Limits
int r = 100; // <
int g = 100; // <
int b = 110; // >


void setup() {
    background(0);
    original = loadImage("20160416_141431.jpg");
    size(original.width * 5, original.height);
    image(original, 0, 0);
    // The destination images are created as blank images the same size as the source.
    circleDetected = createImage(original.width, original.height, RGB);
    roi = createImage(original.width, original.height, RGB);
    thresholded = createImage(original.width, original.height, RGB);
}

void draw() {

    // gets the average brightness from the 10000 brightest pixels in original image  
    // anf fills the "roi" image with it, in order to calculate the threshold later 
    int media = getBrightestPixelsMedia(original);
    roi = createImage(original.width, original.height, RGB);
    roi.loadPixels();
    for (int i = 0; i < roi.pixels.length; i++) {
        roi.pixels[i] = color(0);                            ///// AO INVES DE 0 ERA media
    }
    roi.updatePixels();


    int [] nPixels = new int[2];    // nPixels[0] = total number of pixels inside circle (ROI)
                                    // nPixels[1] = diameter of the circle in pixels
    
    nPixels = findCircle(original, media);
    
    int circleAreaPx = nPixels[0];
    int diameterPx = nPixels[1];

    //println("circle diameter em pixels: " + diameterPx);

    int[] hist = histogram(roi); 

    drawHist(hist);
    int total = original.width * original.height; //total image pixels number
    int threshold = otsu(hist, total);
    //println("threshold: " + threshold);

    // draws the threshold line over the histogram
    stroke(255, 0, 0);
    line(threshold + (original.width*3), 0, threshold + (original.width*3), original.height);

    displayThresholded(roi, threshold);  ///(ou 128 fixo)
    image(thresholded, original.width*4, 0);
     
    int eggsNumber = countEggs(diameterPx, circleAreaPx, thresholded);
}

// Calculate the histogram
int[] histogram(PImage img) { 
    img.loadPixels();
    int[] hist = new int[256];

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++ ) {
            int loc = x + y*img.width;   
            int bright = int(brightness(img.pixels[loc]));
            hist[bright]++;
        }
    }
    return(hist);
}


// Draw the histogram
void drawHist(int[] hist) {
    // Find the largest value in the histogram
    int histMax = max(hist);
    stroke(0, 0, 255);
    for (int i = 0; i < roi.width; i ++) {
        // Map i (from 0..img.width) to a location in the histogram (0..255)
        int which = int(map(i, 0, roi.width, 0, 255));
        // Convert the histogram value to a location between 
        // the bottom and the top of the picture
        int y = int(map(hist[which], 0, histMax, roi.height, 0));
        line(i+(roi.width*3), roi.height, i+(roi.width*3), y);
    }
}

// Otsu's algorithm implementation adapted from
// http://www.labbookpages.co.uk/software/imgProc/otsuThreshold.html
int otsu(int[] histData, int total) {

    float sum = 0;
    for (int t=0 ; t<256 ; t++) sum += t * histData[t];

    float sumB = 0;
    int wB = 0;
    int wF = 0;

    float varMax = 0;
    int threshold = 0;

    for (int t=0 ; t<256 ; t++) {
        wB += histData[t];               // Weight Background
        if (wB == 0) continue;

        wF = total - wB;                 // Weight Foreground
        if (wF == 0) break;

        sumB += (float) (t * histData[t]);

        float mB = sumB / wB;            // Mean Background
        float mF = (sum - sumB) / wF;    // Mean Foreground

        // Calculate Between Class Variance
        float varBetween = (float)wB * (float)wF * (mB - mF) * (mB - mF);

        // Check if new maximum found
        if (varBetween > varMax) {
            varMax = varBetween;
            threshold = t;
        }
    }
    return (threshold);
}

void displayThresholded(PImage img, float threshold) {


    // We are going to look at both image's pixels
    img.loadPixels();
    thresholded.loadPixels();


    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++ ) {
            int loc = x + y*img.width;   
            // Test the brightness against the threshold
            if (brightness(img.pixels[loc]) > threshold) {
                thresholded.pixels[loc]  = color(255);  // White
                //roiWhite++;
            }  
            else {
                thresholded.pixels[loc]  = color( 0);    // Black
            }
        }
    }
    // We changed the pixels in destination
    thresholded.updatePixels();
    
    
}

int[] findCircle(PImage img, int media) {

    /* first, detect the blue circle */
    
    int circleAreaPx = 0;
    int [] nPixels = new int[2];

    img.loadPixels();            // original image
    circleDetected.loadPixels();

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++ ) {
            int loc = x + y*img.width;   
            if (isBlue(img, loc)) {
                circleDetected.pixels[loc]  = color(255, 0, 0);  // if blue detected, mark as red
            }  
            else {
                circleDetected.pixels[loc]  = img.pixels[loc];  // else, keep original
            }
        }
    }

    circleDetected.updatePixels();
    image(circleDetected, img.width*1, 0); // Display the destination image

    /* now, determine the diameter and mount the "roi" image */

    float centerX = img.width/2;
    float centerY = img.height/2;
    float maxX = img.width/2;
    float maxY = img.height/2;
    float minX = img.width/2;
    float minY = img.height/2;
    float maxYx = img.width/2;
    float minYx = img.width/2;
    int loc = 0;
    int y = 0;

    //vertical limits scan to the up/right
    for (int currentX = img.width/2; currentX<img.width; currentX++) {

        for (int currentY = img.height/2; currentY>0; currentY--) {
            loc = currentX + currentY*img.width;
            y = currentY;

            if (!(isBlue(img, loc))) {
                roi.pixels[loc] = img.pixels[loc];
                circleAreaPx++;

                if (currentY < minY) {
                    minY = currentY; 
                    minYx = currentX;
                }
            } 
            else {
                break;
            }
        }
        if ((y == img.height/2) & isBlue(img, loc)
            ) {
            break;
        }
    }

    //vertical limits scan to the up/left
    for (int currentX = img.width/2; currentX>0; currentX--) {
        for (int currentY = img.height/2; currentY>0; currentY--) {
            loc = currentX + currentY*img.width;
            y = currentY;      
            if (!(isBlue(img, loc))) {
                roi.pixels[loc] = img.pixels[loc];
                circleAreaPx++;
               
                if (currentY < minY) {
                    minY = currentY; 
                    minYx = currentX;
                }
            } 
            else {
                break;
            }
        }
        if ((y == img.height/2) & isBlue(img, loc)
            ) {
            break;
        }
    }

    //vertical limits scan to the down/right
    for (int currentX = img.width/2; currentX<img.width; currentX++) {
        for (int currentY = img.height/2; currentY<img.height; currentY++) {
            loc = currentX + currentY*img.width;
            y = currentY;
            if (!(isBlue(img, loc))) {
                roi.pixels[loc] = img.pixels[loc];
                circleAreaPx++;
                
                if (currentY > maxY) {
                    maxY = currentY; 
                    maxYx = currentX;
                }
            } 
            else {
                break;
            }
        }
        if ((y == img.height/2) & isBlue(img, loc)
            ) {
            break;
        }
    }

    //vertical limits scan to the down/left
    for (int currentX = img.width/2; currentX>0; currentX--) {
        for (int currentY = img.height/2; currentY<img.height; currentY++) {
            loc = currentX + currentY*img.width;
            y = currentY;
            if (!(isBlue(img, loc))) {
                roi.pixels[loc] = img.pixels[loc];
                circleAreaPx++;
                
                if (currentY > maxY) {
                    maxY = currentY;
                    maxYx = currentY;
                }
            } 
            else {
                break;
            }
        }
        if ((y == img.height/2) & isBlue(img, loc)
            ) {
            break;
        }
    }

    // Display roi
    roi.updatePixels();
   // roiRedBg.updatePixels();
    image(roi, img.width*2, 0);
   // image(roiRedBg, img.width*5, 0);

    // Draws the diameter
    strokeWeight(1);
    stroke(255, 0, 0);
    line(0, maxY, img.width*2, maxY);
    line(0, minY, img.width*2, minY);
    strokeWeight(1);
    stroke(0, 0, 255);
    line(minYx + img.width, minY, maxYx + img.width, maxY);

    int diameterPx =  int(maxY - minY); // diameter in pixels
    
    nPixels[0] = circleAreaPx;
    nPixels[1] = diameterPx;

    //println("circle area in pixels: " +  nPixels[0] + " circle diameter in pixels: " + nPixels[1]);

    return  nPixels;
}


boolean isBlue (PImage img, int loc) {

    if ( 
    //azul
    (blue(img.pixels[loc]) > b &  //100
    red(img.pixels[loc]) < r &  //105
    green(img.pixels[loc]) < g   //105
    ) ||

        (
    blue(img.pixels[loc]) > red(img.pixels[loc]) &
        blue(img.pixels[loc]) >  green(img.pixels[loc]) &
        abs(red(img.pixels[loc]) -  green(img.pixels[loc])) < 25 &
        abs(blue(img.pixels[loc]) -  green(img.pixels[loc])) >25 &
        abs(blue(img.pixels[loc]) -  red(img.pixels[loc])) >25  /// adicionei depois
    )


    // if the circle were drawn with a red pen
    //                 (blue(img.pixels[loc]) <130 &  //100
    //                 red(img.pixels[loc]) > 140 &  //105
    //                 green(img.pixels[loc]) < 130   //105
    //                 ) ||
    //                 
    //                 (
    //                 red(img.pixels[loc]) > blue(img.pixels[loc]) &
    //                 red(img.pixels[loc]) >  green(img.pixels[loc]) &
    //                 abs(green(img.pixels[loc]) -  blue(img.pixels[loc])) < 25 &
    //                 abs(red(img.pixels[loc]) -  green(img.pixels[loc])) >25
    //                  &
    //                 abs(red(img.pixels[loc]) -  blue(img.pixels[loc])) >25
    //                 )


    ) {
        return true;
    }
    else 
    {
        return false;
    }
}


/* gets the average brightness from the 10000 brightest pixels in original image  
 in order to fill the "roi" image empty area with it to calculate the threshold later.
 (if we fill it with white we could have an undesired threshold bias) */

int getBrightestPixelsMedia(PImage img) {
    int pixel = 0;
    int[] brightestPixels = new int[img.width * img.height];

    for (int i = 0; i < img.width; i ++) {
        for (int j = 0; j < img.height; j++) {
            brightestPixels[pixel] = int(brightness(get(i, j)));
            pixel++;
        }
    }

    brightestPixels = reverse(sort(brightestPixels));
    int media = 0;
    int nPixels = 10000; // 100x100 brightest pixels

    for (int i=0; i < nPixels; i++) {
        media += brightestPixels[i];
    }

    media = media / nPixels; 

    //println("media: " + media);
    return(media);
}


int countEggs(int diameterPx, int circleAreaPx, PImage img) {


    // R$ 1,00 coin diameter = 28mm
    // R$ 1,00 coin area = 615.752 mmˆ2
    // egg area in pixel = 0,3157 mmˆ2 (see notebook)

    int totalImgPx = 0;
    int totalWhitePx = 0;
    int totalBlackPx = 0;

    img.loadPixels();

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++ ) {
            int loc = x + y*img.width;  
            if (brightness(img.pixels[loc]) == 0) { totalBlackPx++; } 
            if (brightness(img.pixels[loc]) == 255) { totalWhitePx++; } 
            totalImgPx++;
            }
    }
    
    
    int outCircleTotalPx = totalImgPx - circleAreaPx;
    
    int inCircleBlackPx = totalBlackPx - outCircleTotalPx;

    //println("white pixels = " + totalWhitePx + " black pixels = " + inCircleBlackPx);
    

    // Calibrating eggSizeInPx

    // 615.752 mmˆ2  (coin area)         ~             circleAreaPx
    //  0,3157 mmˆ2  (1 egg)             ~                eggInPx


    float eggInPx = (0.3157 * circleAreaPx / 615.752) * 2; // number of pixels per egg in the sample - (*2: here we will need more samples to calibrate)
    

    // println( "1 egg = " + eggInPx + " pixels");

    int eggsNumber = (inCircleBlackPx / int(eggInPx));

    println( eggsNumber + " ovos");


    return(eggsNumber);
} 

