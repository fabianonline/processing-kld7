import java.nio.ByteBuffer;
import java.nio.ByteOrder;

// Maximum distance displayed.
int max_distance = 3000;

// The serial port used.
String port = "/dev/tty.usbserial-00000000";

// Request method
// PDAT returns all detected points, including reflections and noise
// TDAT tries to track the strongest signal and returns only one point per request
byte request_method = Radar.REQUEST_TYPE_TDAT;

int w_1_2 = 383;
boolean waitingForData = false;
boolean logSerial = false;
int dataSets = 0;
PrintWriter tsv;
Radar radar;
Detection[] detections;

void settings() {
  size(w_1_2*2, 500);
}

void setup() {
  frameRate(10);
  radar = new Radar(this, port);
  radar
    .setMaximumSpeed(Radar.MAXIMUM_SPEED_100)
    .setMaximumRange(Radar.MAXIMUM_RANGE_30)
    .setThresholdOffset((byte)20)
    .setTrackingFilterType(Radar.TRACKING_FILTER_TYPE_FAST_DETECTION)
    .setMaximumDetectionDistance((byte)100)
    .setRangeThreshold((byte)0)
    .setSpeedThreshold((byte)100)
    .setHoldTime(1);
  
  tsv = createWriter("log.tsv");
  
  background(200);
  fill(255);
  distanceArc(max_distance, PIE);
  noFill();
  for (int i = 1000; i<max_distance; i+=1000) {
    distanceArc(i, OPEN);
  }
  tsv.println("timestamp\tdistance\tspeed\tangle\tmagnitude\tx\ty");
  System.out.println("timestamp\tdistance\tspeed\tangle\tmagnitude\tx\ty");
}

void stop() {
  radar.stop();
  tsv.close();
}

void draw() {
  fill(200);
  rect(0, 0, 20, 20);
  if (dataSets % 4 == 0) {
    circle(5, 5, 5);
  }
  if (dataSets % 4 == 1) {
    circle(10, 5, 5);
  }
  if (dataSets % 4 == 2) {
    circle(10, 10, 5);
  }
  if (dataSets % 4 == 3) {
    circle(5, 10, 5);
  }
  
  radar.readResponse();
  drawData();
  
  if (!waitingForData) {
    try { Thread.sleep(10); } catch(InterruptedException e) {}
    requestData();
  }
}

void drawData() {
  if (detections!=null && detections.length > 0) { //<>//
    for (Detection d: detections) {
      if (d.freshData) {
        System.out.println(d.toString());
        tsv.println(d.toString());
        tsv.flush();
        drawPoint(d.x, d.y, d.speed, d.magnitude);
        d.freshData = false;
      }
    }
  }
}

void distanceArc(int distance, int mode) {
  arc(w_1_2, 500, 500.0/max_distance*distance*2, 500.0/max_distance*distance*2, radians(-40 - 90), radians(40 - 90), mode);
}

void requestData() {
  radar.requestDataFrame(request_method);
  waitingForData = true;
}



void drawPoint(int x, int y, float speed, float magnitude) {
  int dia;
  if (magnitude < 20) {
    noFill();
    dia = 2;
  } else {
    fill(220 - (magnitude-20)*10);
    dia = 15;
  }
  circle(x, y, dia);
  fill(0);
  textAlign(CENTER, BOTTOM);
  //text(speed, x, y-7);
}
