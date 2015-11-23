/*

Projecto para el monitoreo comunitario de dengue
Script para analisis de imagenes de ovitrampas

v1: visualización del efecto de la variación del threshold sobre la imagen de la ovitrampa

Proxima etapa: implementar el algoritmo de Otsu para obtener el threshold global

Oda Scatolini - 14/11/2015

odascatolini@gmail.com

*/


PImage source;       // Source image
PImage destination;  // Destination image
int alt_barra = 200;
PFont f;
  
void setup() {
  source = loadImage("paleta.jpg");
  size(source.width * 2, source.height + alt_barra);
  f = createFont("Arial",16,true);
    
  // The destination image is created as a blank image the same size as the source.
  destination = createImage(source.width, source.height, RGB);
}

void draw() {  
  background(0);
  //float   threshold = 150;
  float     black = 0;
  float     white = 0;
  float     perc = 0;
  float     total = source.width * source.height;
  float     soma_brilho=0;
  float     media_brilho=0;

  float threshold = map(mouseX, 0, width, 0, 255);


  // We are going to look at both image's pixels
  source.loadPixels();
  destination.loadPixels();
  
  for (int x = 0; x < source.width; x++) {
    for (int y = 0; y < source.height; y++ ) {
      int loc = x + y*source.width;
      soma_brilho += brightness(source.pixels[loc]);
      
      // Test the brightness against the threshold
      if (brightness(source.pixels[loc]) > threshold) {
        destination.pixels[loc]  = color(255);  // White
        white++;
      }  else {
        destination.pixels[loc]  = color(0);    // Black
        black++;
      }
    }
  }
  perc = (black/total)*100;
  //println("pr=" + black);
  //println("br= " + white);
  //println("cobert= " + perc*100 + "%");
  media_brilho = soma_brilho / total;
 
  

  // We changed the pixels in destination
  destination.updatePixels();
  // Display the destination
  image(source,0,0);
  image(destination,source.width,0);
  
  
  
  float cor=0;
  for (int x = 0; x < width; x++) {
    cor = map(x, 0, width, 0, 255);
    stroke(cor);
    line(x, height - alt_barra, x, height - (0.8*alt_barra));
  } 
  
  textFont(f,16);                  
  fill(255,255,255);                         
  text("pixels pretos: " + black ,10, height - 100);
  text("pixels brancos: " + white ,10,height - 80);
  text("cobertura: " + perc + "%" ,10,height - 60);
  text("threshold: " + threshold ,10,height - 40);
  //text("brilho medio: " + media_brilho ,10,height - 20);
  
  media_brilho = 0;
}
