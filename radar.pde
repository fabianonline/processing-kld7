import processing.serial.*;

class Radar {
  static final byte REQUEST_TYPE_PDAT = 0x04;
  static final byte REQUEST_TYPE_TDAT = 0x08;
  static final byte BASE_FREQUENCY_LOW = 0x00;
  static final byte BASE_FREQUENCY_MIDDLE = 0x01;
  static final byte BASE_FREQUENCY_HIGH = 0x02;
  static final byte MAXIMUM_SPEED_12_5 = 0x00;
  static final byte MAXIMUM_SPEED_25 = 0x01;
  static final byte MAXIMUM_SPEED_50 = 0x02;
  static final byte MAXIMUM_SPEED_100 = 0x03;
  static final byte MAXIMUM_RANGE_5 = 0x00;
  static final byte MAXIMUM_RANGE_10 = 0x01;
  static final byte MAXIMUM_RANGE_30 = 0x02;
  static final byte MAXIMUM_RANGE_100 = 0x03;
  static final byte TRACKING_FILTER_TYPE_STANDARD = 0x00;
  static final byte TRACKING_FILTER_TYPE_FAST_DETECTION = 0x01;
  static final byte TRACKING_FILTER_TYPE_LONG_VISIBILITY = 0x02;
  static final byte DETECTION_DIRECTION_RECEDING = 0x00;
  static final byte DETECTION_DIRECTION_APPROACHING = 0x01;
  static final byte DETECTION_DIRECTION_BOTH = 0x02;
  static final byte DIGITAL_OUTPUT_DIRECTION = 0x00;
  static final byte DIGITAL_OUTPUT_ANGLE = 0x01;
  static final byte DIGITAL_OUTPUT_RANGE = 0x02;
  static final byte DIGITAL_OUTPUT_SPEED = 0x03;
  static final byte DIGITAL_OUTPUT_MICRO_DETECTION = 0x04;
  static final byte RETRIGGER_OFF = 0x00;
  static final byte RETRIGGER_ON = 0x01;
  
  Serial serial;
  public Radar(k_ld7 parent, String port) {
    serial = new Serial(parent, port, 115200, 'E', 8, 1.0);
    sendCommandAndWaitForResponse("INIT", new byte[]{0x00, 0x00, 0x00, 0x00});
  }
  
  public void stop() {
    serial.stop();
  }
  
  private void sendCommand(String command, byte[] bytes) {
    if (logSerial) System.out.printf("Sending command %s...\n", command);
    serial.write(command);
    int len = (bytes == null) ? 0 : bytes.length;
    serial.write(new byte[] {(byte)(len & 0xFF), (byte)((len >> 8) & 0xFF), (byte)((len >> 16) & 0xFF), (byte)((len >> 24) & 0xFF)});
    if (len > 0) serial.write(bytes);
  }
  
  private void sendCommandAndWaitForResponse(String command, byte[] bytes) {
    sendCommand(command, bytes);
    while(!readResponse().equals("RESP")) {try{Thread.sleep(100);}catch(Exception e){}};
  }
  
  private byte[] readBytes(int count) {
    byte[] result = serial.readBytes(count);
    if (logSerial) {
      for (int i=0; i<count; i++) {
        System.out.printf("0x%02X ", result[i]);
      }
      System.out.println();
    }
    return result;
  }
  
  public String readResponse() {
    if (logSerial) System.out.printf("readResponse(): %d bytes available\n", serial.available());
    if (serial.available() < 8) {
      return "";
    }
    String command = new String(readBytes(4));
    byte[] l = readBytes(4);
    int len = l[0] + (l[1]<<8) + (l[2]<<16) + (l[3]<<24);
    if (logSerial) System.out.printf("Receiving %s  with %d Bytes payload...", command, len);
    byte[] payload = readBytes(len);
    if (logSerial) System.out.println(" complete.");
    
    if (command.equals("RESP") && len==1) {
      switch (payload[0]) {
        case 0: break; // OK
        case 1: System.out.println("Unknown command"); break;
        case 2: System.out.println("Invalid parameter value"); break;
        case 3: System.out.println("Invalid RPST version"); break;
        case 4: System.out.println("Uart error (parity, framing, noise)"); break;
        case 5: System.out.println("Sensor busy"); break;
        case 6: System.out.println("Timeout error"); break;
        default: System.out.printf("Unknown error code %d\n", payload[0]); break;
      }
    } else if (command.equals("PDAT")) {
      if (len > 0) {
        detections = parseDetectionData(payload);
      }
      waitingForData = false;
      dataSets++;
    } else if (command.equals("TDAT")) {
      if (len > 0) {
        detections = parseDetectionData(payload);
      }
      waitingForData = false;
      dataSets++;
    } else if (command.equals("RPST")) {
      for(byte b : payload) {
        System.out.printf("%02X ", b);
      }
      System.out.println();
    }
      
    return command;
  }
  
  public void requestDataFrame(byte type) {
    sendCommand("GNFD", new byte[] {type, 0, 0, 0});
  }
  
  public Radar setBaseFrequency(byte type) { sendCommandAndWaitForResponse("RBFR", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setMaximumSpeed(byte type) { sendCommandAndWaitForResponse("RSPI", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setMaximumRange(byte type) { sendCommandAndWaitForResponse("RRAI", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setThresholdOffset(byte value) { sendCommandAndWaitForResponse("THOF", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setTrackingFilterType(byte type) { sendCommandAndWaitForResponse("TRFT", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setVibrationSuppression(byte value) { sendCommandAndWaitForResponse("VISU", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setMinimumDetectionDistance(byte type) { sendCommandAndWaitForResponse("MIRA", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setMaximumDetectionDistance(byte type) { sendCommandAndWaitForResponse("MARA", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setMinimumDetectionAngle(byte value) { sendCommandAndWaitForResponse("MIAN", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setMaximumDetectionAngle(byte value) { sendCommandAndWaitForResponse("MAAN", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setMinimumDetectionSpeed(byte value) { sendCommandAndWaitForResponse("MISP", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setMaximumDetectionSpeed(byte value) { sendCommandAndWaitForResponse("MASP", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setDetectionDirection(byte type) { sendCommandAndWaitForResponse("DEDI", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setRangeThreshold(byte value) { sendCommandAndWaitForResponse("RATH", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setAngleThreshold(byte value) { sendCommandAndWaitForResponse("ANTH", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setSpeedThreshold(byte value) { sendCommandAndWaitForResponse("SPTH", new byte[]{value, 0, 0, 0}); return this;}
  public Radar setDigitalOutput1(byte type) { sendCommandAndWaitForResponse("DIG1", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setDigitalOutput2(byte type) { sendCommandAndWaitForResponse("DIG2", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setDigitalOutput3(byte type) { sendCommandAndWaitForResponse("DIG3", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setHoldTime(int value) { sendCommandAndWaitForResponse("DIG1", new byte[]{(byte)(value & 0xFF), (byte)((value >> 8) & 0xFF), 0, 0}); return this;}
  public Radar setMicroDetectionRetrigger(byte type) { sendCommandAndWaitForResponse("MIDE", new byte[]{type, 0, 0, 0}); return this;}
  public Radar setMicroDetectionSensitivity(byte type) { sendCommandAndWaitForResponse("MIDS", new byte[]{type, 0, 0, 0}); return this;}
}
