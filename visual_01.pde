import http.requests.*;

String ecodermisAlbumId = "waupUVF";
PImage mask, dummy;
PImage eye;

JSONObject response;
PImage earth;

String state = "SHOW";

int lastUpdate = 0;
int lastSkin = 0;

ArrayList<String> links = new ArrayList<String>();
ArrayList<Skin> skins = new ArrayList<Skin>();
ArrayList<Slice> slices = new ArrayList<Slice>();

UniversalSkin uskin;
boolean newUskin = false;
void settings() {
  size(800, 800);//, "processing.opengl.PGraphics3D"
  //fullScreen(P3D);
}

void setup() {
  //size(800, 800, P3D);
  background(0);
  noLoop();
  mask = loadImage("slice.png");
  dummy = loadImage("Pq0XJem.png");
  earth = loadImage("iris-fotograf-4.jpg");
  eye = loadImage("iris-fotograf-4.jpg");
  uskin = new UniversalSkin();

  requestAlbum();
  createSlices();

  //frameRate(25);
  noCursor();
  loop();
}




int updateTime = 10000;
float myScale = 1.0;

void draw() {
  if (millis() > lastUpdate + updateTime ) {
    lastUpdate = millis();
    requestAlbum();
    changeSlices();
  }

  if (millis() > lastSkin + 5E3) {
    newUskin = false;
  }


  background(0);
 
  translate(width/2, height/2);
  scale(myScale);
  uskin.render();
  for (Slice s : slices) {
    s.render();
  }

  if (newUskin) showEye();
}

void showEye() {  
  pushStyle();
  scale(1.15);
  image(eye, 0, 0, width, height);
  popStyle();
}


void requestAlbum() {
  GetRequest get = new GetRequest("https://api.imgur.com/3/album/"+ecodermisAlbumId+"/images?perPage=12");
  get.addHeader("Authorization", "Client-ID 9c48ba5baf1e548");
  get.send(); 
  println("Reponse Content: ");
  response = parseJSONObject(get.getContent());
  processRequest(response);
  //
}

void processRequest(JSONObject response) {  
  JSONArray imgs = response.getJSONArray("data");    
  for (int i = imgs.size() - 1; i > imgs.size() - 20; i--) {   
    JSONObject imgdata = imgs.getJSONObject(i);    
    String link = imgdata.getString("link");
    String desc = imgdata.isNull("description") ? "not_share" : imgdata.getString("description");        
    link = link.replace(".jpg", "l.jpg");  

    if (!isNewImage(link)) {
      continue;
    }


    newUskin = true;
    lastSkin = millis();
      
    if (desc.equals("not_share")) {
      skins.add(new Skin(link, desc));
      changeSlices();
    } else {      
      uskin.addNewSkin(new Skin(link, desc));
    }
  }
}

boolean isNewImage(String link) {
  if (links.indexOf(link) == -1) {
    links.add(link);
    return true;
  } else {
    return false;
  }
}


void createSlices() {
  for (int sl = 0; sl < 12; sl++) {        
    Slice temp = new Slice(sl);
    slices.add(temp);
  }
}

public void changeSlices() {  
  if (skins != null && skins.size() > 0) {
    
    if(skins.size() > 12 ) skins.remove(0); //remuevo los ultimos...
    for(int w = 0; w < slices.size(); w++){
      Skin item = skins.get(w);
    slices.get(w).switchImage(item.img);
    }
    
    //int w = (int) random(slices.size());
    
  }
}

void keyPressed() {
  if (keyCode == UP) {
    myScale = constrain(myScale + 0.1, 0.5, 1.5);
  }
  if (keyCode == DOWN) {

    myScale = constrain(myScale - 0.1, 0.5, 1.5);
  }
  //if (key == ' ') changeSkins();

  //if (key == '1') uskin.addNewSkin(new Skin("01.jpg", ""));
  //if (key == '2') uskin.addNewSkin(new Skin("02.jpg", ""));
  //if (key == '3') uskin.addNewSkin(new Skin("03.jpg", ""));
  //newUskin = true;
  //lastSkin = millis();
}



public class UniversalSkin {

  ArrayList<Skin> skins;
  PGraphics canvas;
  PImage catchMask;

  UniversalSkin() {
    skins = new ArrayList<Skin>();
    catchMask = loadImage("catch_01.png");
    canvas = createGraphics(400, 400);
    canvas.beginDraw();
    canvas.background(0);
    canvas.endDraw();
  }


  void render() {

    pushMatrix();
    pushStyle();

    image(canvas, 0, 0);
    image(catchMask, 0, 0);
    popStyle();
    popMatrix();
  }


  public void addNewSkin(Skin skin) {
    skins.add(skin);
    if (skins.size() > 13) {  // guardo una de mas para evitar posibles null pointer
      Skin trash = skins.remove(0);
      trash = null;
    }
    composite();
  }


  public void composite() {
    if (skins.size() > 4) skins.remove(0);

    canvas.beginDraw();
    canvas.background(255);    
    //canvas.blendMode(ADD);
    //canvas.imageMode(CENTER);
    canvas.tint(255, 200);
    for (Skin s : skins) {  
      canvas.image(s.img, 0, 0, canvas.width, canvas.height);//, s.img.width, s.img.height, 0,0, canvas.width, canvas.height, OVERLAY);
    }
    canvas.endDraw();
  }
}

public class Skin {
  String url;
  String sharing;
  PImage img;

  Skin(String url, String sharing) {
    this.url = url;
    this.sharing = sharing;
    img = loadImage(this.url);
    img.resize(img.width/3, img.height/3);
    println(this);
  }

  String toString() {
    return this.url +" : "+this.sharing + " : " + img.width + " : " +img.height;
  }
}

class Slice {

  int radius = 300 - 50;
  int offset = -0;
  int position = 0;
  PImage img = null;
  PVector loc = new PVector();

  Slice(int position) {
    this.position = position;
    this.img = dummy;
  }

  public void switchImage(PImage newImage) {
    this.img = newImage;
  };


  public void render() {
    this.loc.x = this.radius * sin(radians(this.position * 360 / 12));
    this.loc.y = this.radius * cos(radians(this.position * 360 / 12));
    if (mask != null) {
      pushMatrix();
      imageMode(CENTER);
      translate(this.loc.x, this.loc.y);
      rotate(-radians(180 + this.position * 360 / 12));
      this.img.resize(mask.width, mask.height);
      this.img.mask(mask);
      image(this.img, 0, 0, mask.width, mask.height);

      popMatrix();
    }
  };
}
