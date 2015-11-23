/*

 Projecto para el monitoreo comunitario de dengue
 Script para analisis de imagenes de ovitrampas
 
 v3: divide la imagen em 4 partes, obteneniendo el threshold por cada parte (threshold dinamico)
 
 Proxima etapa: testes com mas imagenes
 
 Oda Scatolini - 21/11/2015
 
 odascatolini@gmail.com
 
 */

PImage img;
PImage imgDest;


PImage[] partImg = new PImage[4];
PImage[] partDest = new PImage[4];

void setup() {
    background(0);
    img = loadImage("paleta.jpg");
    size(img.width * 4, img.height);
    image(img, 0, 0);
    // The destination image is created as a blank image the same size as the source.
    imgDest = createImage(img.width, img.height, RGB);
    for (int i = 0; i < 4; i++) {
        partDest[i] = createImage(img.width/2, img.height/2, RGB);
    }
}

void draw() {

    int total = img.width * img.height; //total image pixels number
    int totalPart = total/4; //divided image pixels number
    int[] hist = histogram(img); 
    drawHist(hist, img, img.width, img.height);
    float threshold = otsu(hist, total);
    //println(threshold);
    stroke(255, 0, 0);
    // Draw a line representing the global threshold
    line(threshold + img.width, 0, threshold + img.width, img.height);
    applyThresholded(img, imgDest, threshold);
    // Display the destination
    image(imgDest, img.width*2, 0);


    divideImage(img);

    // Draw the image portions together
//    image(partImg[0], img.width*4, 0);
//    image(partImg[1], img.width*4.5, 0);
//    image(partImg[2], img.width*4, img.height/2);
//    image(partImg[3], img.width*4.5, img.height/2);

    // Calculates each image portion histogram
    int[] hist0 = histogram(partImg[0]);
    int[] hist1 = histogram(partImg[1]);
    int[] hist2 = histogram(partImg[2]);
    int[] hist3 = histogram(partImg[3]);

    // Calculate each image portion threshold
    float thres0 = otsu(hist0, partImg[0].width * partImg[0].height);
    float thres1 = otsu(hist1, partImg[1].width * partImg[1].height);
    float thres2 = otsu(hist2, partImg[2].width * partImg[2].height);
    float thres3 = otsu(hist3, partImg[3].width * partImg[3].height);

    println(threshold + " :: " + thres0 + " :: " + thres1 + " :: " + thres2 + " :: " + thres3);
    
    // This part intended to show each part histogram, but it is not working 
    // It needs some adjustments in drawHist() to work properly
    //drawHist(hist0, partImg[0], img.width*3, partImg[0].height);
    //drawHist(hist1, partImg[3], img.width*3 + partImg[3].width, partImg[3].height);
    //drawHist(hist2, part[2], img.width*3, img.height);
    //drawHist(hist3, part[3], img.width*3 + part[3].width, img.height);

    // Calculate the destination image parts
    applyThresholded(partImg[0], partDest[0], thres0);
    applyThresholded(partImg[1], partDest[1], thres1);
    applyThresholded(partImg[2], partDest[2], thres2);
    applyThresholded(partImg[3], partDest[3], thres3);
    
    // Display the destination image parts    
    image(partDest[0], img.width*3, 0);
    image(partDest[1], img.width*3.5, 0);
    image(partDest[2], img.width*3, img.height/2);
    image(partDest[3], img.width*3.5, img.height/2);
}

// Calculate the histogram
int[] histogram(PImage image) {
    int[] histo = new int[256];
    for (int i = 0; i < image.width; i++) {
        for (int j = 0; j < image.height; j++) {
            color c = image.pixels[j* image.width + i];
            int bright = int(brightness(c));
            histo[bright]++;
        }
    }
    return(histo);
}


// Draw the histogram (hist, image, position)
void drawHist(int[] hist, PImage image, int x, int y) {
    // Find the largest value in the histogram
    int histMax = max(hist);
    stroke(255);
    for (int i = 0; i < image.width; i ++) {
        // Map i (from 0..img.width) to a location in the histogram (0..255)
        int which = int(map(i, 0, image.width, 0, 255));
        // Convert the histogram value to a location between 
        // the bottom and the top of the picture
        int q = int(map(hist[which], 0, histMax, image.height, 0));
        //        line(i+img.width, img.height, i+img.width, y);
        line(i+x, y, i+x, q);
    }
}

// Otsu's algorithm implementation adapted from
// http://www.labbookpages.co.uk/software/imgProc/otsuThreshold.html
float otsu(int[] histData, int total) {

    float sum = 0;
    for (int t=0 ; t<256 ; t++) sum += t * histData[t];

    float sumB = 0;
    int wB = 0;
    int wF = 0;

    float varMax = 0;
    float threshold = 0;

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

// Calculate the resultant image after the otsu's threshold application
void applyThresholded(PImage image, PImage dest, float threshold) {

    float     black = 0;
    float     white = 0;
    float     perc = 0;
    float     total = image.width * image.height;
    float     soma_brilho=0;
    float     media_brilho=0;

    // We are going to look at both image's pixels
    image.loadPixels();
    dest.loadPixels();

    for (int x = 0; x < image.width; x++) {
        for (int y = 0; y < image.height; y++ ) {
            int loc = x + y*image.width;   
            // Test the brightness against the threshold
            if (brightness(image.pixels[loc]) > threshold) {
                dest.pixels[loc]  = color(255);  // White
                white++;
            }  
            else {
                dest.pixels[loc]  = color(0);    // Black
                black++;
            }
        }
    }
    // We changed the pixels in destination
    dest.updatePixels();
}

// Divide image in 4 portions and store them in partImg[]
void divideImage (PImage image) {  
    partImg[0] = image.get(0, 0, image.width/2, image.height/2);
    partImg[1] = image.get(image.width/2, 0, image.width/2, image.height/2);
    partImg[2] = image.get(0, image.height/2, image.width/2, image.height/2);
    partImg[3] = image.get(image.width/2, image.height/2, image.width/2, image.height/2);
}

