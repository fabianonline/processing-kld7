class Detection {
  public int distance, x, y;
  public float speed, angle, magnitude, radAngle, distPx;
  public boolean freshData;
  
  public Detection(byte[] data) {
    ByteBuffer bb = ByteBuffer.wrap(data);
    bb.order(ByteOrder.LITTLE_ENDIAN);
    distance = bb.getShort();
    speed = bb.getShort() / 100.0;
    angle = bb.getShort() / 100.0;
    magnitude = bb.getShort() / 100.0;
    radAngle = radians(angle);
    distPx = 500.0 / max_distance * distance;
    x = round(w_1_2 + sin(radAngle) * distPx);
    y = round(500 - abs(cos(radAngle)) * distPx);
    freshData = true;
  }
  
  public String toString() {
    return String.format("%d\t%3.1f\t%5.2f\t%4.2f\t%5.2f\t%d\t%d", millis(), distance/100.0, speed, angle, magnitude, x, y);
  }
}

public Detection[] parseDetectionData(byte[] data) {
  int sets = data.length / 8;
  Detection[] results = new Detection[sets];
  for(int i=0; i<sets; i++) {
    results[i] = new Detection(subset(data, i*8, 8));
  }
  return results;
}
