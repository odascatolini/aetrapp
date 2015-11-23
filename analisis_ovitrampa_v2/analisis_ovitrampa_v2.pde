/*

Projecto para el monitoreo comunitario de dengue
Script para analisis de imagenes de ovitrampas

v2: determina el threshold global utilisando el algoritmo de Otsu (https://en.wikipedia.org/wiki/Otsu%27s_method)

Proxima etapa: dividir la imagen para obtener el threshold por partes (threshold dinamico)

Oda Scatolini - 18/11/2015

odascatolini@gmail.com

*/


PImage img;
PImage destination;

void setup() {
  background(0);
  img = loadImage("paleta.jpg");
  size(img.width * 3,img.height);
  image(img, 0, 0);
  // The destination image is created as a blank image the same size as the source.
  destination = createImage(img.width, img.height, RGB);
}

void draw(){
  int total = img.width * img.height; //total image pixels number
  int[] hist = histogram(img); 
  drawHist(hist);
  float threshold = otsu(hist, total);
  println(threshold);
  stroke(255,0,0);
  line(threshold + img.width, 0, threshold + img.width, img.height);
  displayThresholded(img, threshold);
}

// Calculate the histogram
int[] histogram(PImage img) {
  int[] hist = new int[256];
  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      int bright = int(brightness(get(i, j)));
      hist[bright]++; 
    }
  }
  return(hist);
}


// Draw the histogram
void drawHist(int[] hist) {
   // Find the largest value in the histogram
  int histMax = max(hist);
  stroke(255);
  for (int i = 0; i < img.width; i ++) {
    // Map i (from 0..img.width) to a location in the histogram (0..255)
    int which = int(map(i, 0, img.width, 0, 255));
    // Convert the histogram value to a location between 
    // the bottom and the top of the picture
    int y = int(map(hist[which], 0, histMax, img.height, 0));
    line(i+img.width, img.height, i+img.width, y);
  }
}

// Otsu's algorithm implementation adapted from
// http://www.labbookpages.co.uk/software/imgProc/otsuThreshold.html
float otsu(int[] histData,int total) {
  
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

void displayThresholded(PImage img, float threshold) {
 
  float     black = 0;
  float     white = 0;
  float     perc = 0;
  float     total = img.width * img.height;
  float     soma_brilho=0;
  float     media_brilho=0;

  // We are going to look at both image's pixels
  img.loadPixels();
  destination.loadPixels();
  
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++ ) {
      int loc = x + y*img.width;   
      // Test the brightness against the threshold
      if (brightness(img.pixels[loc]) > threshold) {
        destination.pixels[loc]  = color(255);  // White
        white++;
      }  else {
        destination.pixels[loc]  = color(0);    // Black
        black++;
      }
    }
  }
  // We changed the pixels in destination
  destination.updatePixels();
  // Display the destination
  image(destination,img.width*2,0);
}
