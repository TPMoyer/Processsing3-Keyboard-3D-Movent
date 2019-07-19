import g4p_controls.*;
import org.apache.log4j.*;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.Point;
import java.awt.MouseInfo;

float angle;
PImage world;
//int num;

PShape teapot0; /* legacy teapot */
float[] xyzsAR;
float[] normalsAR;
float[] texCoordsAR;
int[] trianglesIndexsAR;

PShape teapot1; /* teapot with reduced number of data */
float[] xyzs;
float[] normals;
float[] texCoords;
int[] trianglesIndexs;
/* Can turn any (even dis-connected) set of triangles into a single triangle strip. 
 * Almost certainly with fewer indices.  
 * But will leave that for another day. 
 */
//int[] triangleStripIndexs;  

/* toggles to cary the effects of GUI clicks back to my code */
boolean showThickAxies=false;
boolean showTeapot=true;
boolean showHello=true;

/* Wanted to have focus go to main window after making a selection in the gui window.
 * per https://discourse.processing.org/t/is-it-possible-to-open-a-second-window-in-processing-3-4-using-g4p/5888/7
 * went with the robot class to push a mouse click.  
 * Bit hack'y but sometimes a programmer's gotta do what a programmers gotta do. 
 */
Robot robot; 
Point mainWindowXY=new Point(600,550); /* use variable for the surface X,Y so that the robot class can click on an inside-the-window location */

/* Thank you Jake Seigel for the processing log4j connectivity!    
 * I'm a logggerDebugger and this was key to being able to 
 * dig myself out of several/many  holes/traps/mistakes/typos:   https://jestermax.wordpress.com/2014/06/09/log4j-4-you/    */ 
Logger log = Logger.getLogger("Master"); 

void setup() {
  size(640,480, P3D);
  /* set to wherever is a convenient viewing location on your system. Numbers are X,Y pixel offsets from UL screen corner */
  surface.setLocation((int)mainWindowXY.getX(),(int)mainWindowXY.getY()); 
  initLog4j();
  font0 = createFont("Monospaced.bold", 16); /* used by ck.thickLabledAxies()  */
  textFont(font0); 
  colorMode(RGB, 1);
  createGUI();
  option1.setSelected(false);
  //ck.setCameraNear(.01);ck.setCameraFar(40.); /* Allowed precise (close in) movement when using this app to digitize the classic teapot */
  ck.setCameraNear(.1);ck.setCameraFar(500.); /* Should prevent most folks from having the teapot become invisible because it is outside the Frustum */
  perspective(PI/3.0, width/height, ck.getCameraNear(), ck.getCameraFar());
  try{
    robot = new Robot();
  } catch (AWTException e) {
    e.printStackTrace();
  }
  /* This is bigger than the full view of the teapot needs, but the app demo's keyboard movement, so folks will zoom in. */ 
  world=loadImage(".\\data\\world.topo.bathy.200407.3x4096x2048_B35.jpg"); 
 
  /* the classic teapot */ 
  //getJsonTeapot();
  //teapot0=createTeapot0();
  
  getMinimalistJsonTeapot();
  teapot1=createTeapot1();
  
  PGL pgl = null;
  
  /*     x   y   z    pitch       roll       yaw     */
  ck.set(0,-30.6,6,radians(0),radians(0),radians(90));
  //ck.set(0,-30.0,0.,radians(0),radians(0),radians(90));
  //ck.set(    0.000,  -30.000,   20.671,    radians(   0.000),   radians(   0.000),   radians(  90.000));

  
  printCamera();
}

void draw() {
  
  ck.drawMethods();
  scale(1.,1.,-1.); /* set Y axis conformal to USA Math, USA Physics, and OpenGL:  X Pos to the right , Y Pos Away, Z Pos is up */
  background(0.5); /* different from full white, so that if anything is ever inadvertantly drawn white, it will still be visible */
  lights();
  ck.drawCrossHairs();
   
  label1.setText(String.format(
    "XYZ (%9.3f,%9.3f,%9.3f)   Pitch,Roll,Yaw (%8.3f,%8.3f,%8.3f)  %4.0f distance/sec  %6.2f°/sec",
    ck.xyz.x,
    ck.xyz.y,
    -ck.xyz.z,
    degrees(-ck.pry.x),
    degrees(ck.pry.y),
    degrees(ck.pry.z),
    ck.deltaXYZ,
    degrees(ck.deltaPRY) 
   ));
    
  if(showThickAxies){  
    pushMatrix();
      scale(.065);
      //scale(ck.xMod(.01,.1));
      ck.thickLabledAxies();
    popMatrix();
  }
  if(showTeapot){
    pushMatrix();
      //rotateY(ck.thetaMod(-PI,PI));
      pushMatrix();
      //  translate(ck.xMod(-5,5),0,0);
      //  //rotateY(1.936677-PI/2); /* tilt teapot so that spout defining almost-ellipse-the-second is vertical *? 
      //  shape(teapot0); /* be sure to un-comment the getJsonTeapot() and createTeapot0() methods in setup() */ 
      popMatrix();
      shape(teapot1);
    popMatrix();
  }  
  if(showHello)sayHello();   
  angle += 0.01;
}


PShape createTeapot0() {
  textureMode(NORMAL);
  PShape sh = createShape();
  sh.beginShape(TRIANGLES);
  //sh.noStroke();
  sh.texture(world);
  int numTriangles=trianglesIndexsAR.length/3;
  /**/log.debug("see numTriangles as "+numTriangles);
  for (int ii=0;ii<numTriangles;ii++) {
    for(int jj=0;jj<3;jj++){
      //log.debug(String.format("%5d %5d %5d",ii,jj,trianglesIndexsAR[3*ii+jj]));
      sh.normal(normalsAR[3*trianglesIndexsAR[3*ii+jj]  ],
                normalsAR[3*trianglesIndexsAR[3*ii+jj]+1],
                normalsAR[3*trianglesIndexsAR[3*ii+jj]+2]
               );
      sh.vertex(xyzsAR     [3*trianglesIndexsAR[3*ii+jj]  ],
                xyzsAR     [3*trianglesIndexsAR[3*ii+jj]+1],
                xyzsAR     [3*trianglesIndexsAR[3*ii+jj]+2],
                //texCoordsAR[2*trianglesIndexsAR[3*ii+jj]  ]-(1.0<texCoordsAR[2*trianglesIndexsAR[3*ii+jj]  ]?1.:0.),
                //texCoordsAR[2*trianglesIndexsAR[3*ii+jj]+1]-(1.0<texCoordsAR[2*trianglesIndexsAR[3*ii+jj]+1]?1.:0.)
                texCoordsAR[2*trianglesIndexsAR[3*ii+jj]  ],
                texCoordsAR[2*trianglesIndexsAR[3*ii+jj]+1]
               ); 
      //if(ii<30){
      //  log.debug(String.format("old %4d (%8.3f,%8.3f,%8.3f) (%6.3f,%6.3f,%6.3f) (%5.3f,%5.3f)",
      //    ii,
      //    xyzsAR[3*trianglesIndexsAR[3*ii+jj]  ],
      //    xyzsAR[3*trianglesIndexsAR[3*ii+jj]+1],
      //    xyzsAR[3*trianglesIndexsAR[3*ii+jj]+2],
      //    normalsAR[3*trianglesIndexsAR[3*ii+jj]  ],
      //    normalsAR[3*trianglesIndexsAR[3*ii+jj]+1],
      //    normalsAR[3*trianglesIndexsAR[3*ii+jj]+2],
      //    texCoordsAR[2*trianglesIndexsAR[3*ii+jj]  ],
      //    texCoordsAR[2*trianglesIndexsAR[3*ii+jj]+1]
      //  ));
      //}
    }
  }
  sh.endShape();
  return sh;
}
PShape createTeapot1() {
  textureMode(NORMAL);
  PShape sh = createShape();
  sh.beginShape(TRIANGLES);
 // sh.noStroke();
  sh.texture(world);
  int numTriangles=trianglesIndexs.length/3;
  /**/log.debug("see numTriangles as "+numTriangles);
  for (int ii=0;ii<numTriangles;ii++) {
    for(int jj=0;jj<3;jj++){
      //log.debug(String.format("%5d %5d %5d",ii,jj,trianglesIndexs[3*ii+jj]));
      sh.normal(normals[3*trianglesIndexs[3*ii+jj]  ],
                normals[3*trianglesIndexs[3*ii+jj]+1],
                normals[3*trianglesIndexs[3*ii+jj]+2]
               );
      sh.vertex(xyzs     [3*trianglesIndexs[3*ii+jj]  ],
                xyzs     [3*trianglesIndexs[3*ii+jj]+1],
                xyzs     [3*trianglesIndexs[3*ii+jj]+2],
                texCoords[2*trianglesIndexs[3*ii+jj]  ],
                texCoords[2*trianglesIndexs[3*ii+jj]+1]
               );      

      //if(ii<30){
        //log.debug(String.format("min %4d (%8.3f,%8.3f,%8.3f) (%6.3f,%6.3f,%6.3f) (%5.3f,%5.3f)",
        //  ii,
        //  xyzs[3*trianglesIndexs[3*ii+jj]  ],
        //  xyzs[3*trianglesIndexs[3*ii+jj]+1],
        //  xyzs[3*trianglesIndexs[3*ii+jj]+2],
        //  normals[3*trianglesIndexs[3*ii+jj]  ],
        //  normals[3*trianglesIndexs[3*ii+jj]+1],
        //  normals[3*trianglesIndexs[3*ii+jj]+2],
        //  texCoords[2*trianglesIndexs[3*ii+jj]  ],
        //  texCoords[2*trianglesIndexs[3*ii+jj]+1]
        //));
      //}
    }
  }
  sh.endShape();
  return sh;
}
void sayHello(){
  String hw="Hello World";
  float orbitRadius0=94.;
  //orbitRadius0=ck.xMod(65.,100);
  float orbitHeight0=120.;
  //orbitHeight0=ck.yMod(0,145);
  float orbitRadius1=106.;
  //orbitRadius1=ck.xMod(95.,140);
  float orbitHeight1=36.;
  //orbitHeight1=ck.yMod(-45,100);
  float deltaTheta=.1;
  //deltaTheta=ck.xMod(0,.1);
  
  pushMatrix();
    scale(.1);
    fill(0.,1.,0.);
    for(int jj=0;jj<3;jj++){
      pushMatrix();     
        rotateZ(angle+jj*2*PI/3);
        for(int ii=0;ii<hw.length();ii++){
          pushMatrix();
            float theta=ii*deltaTheta;
            translate(orbitRadius0*sin(theta),orbitRadius0*cos(theta),orbitHeight0);
            rotateZ(-theta);
            rotateX(radians(300)); /* tilted in for Northern hemisphere */
            //rotateX(ck.thetaMod());
            text(hw.substring(ii,ii+1),0.,0.,0.);   
          popMatrix();
        }     
       popMatrix();
    }
    for(int jj=0;jj<3;jj++){
      pushMatrix();     
        rotateZ(angle+jj*2*PI/3+PI/3);
        for(int ii=0;ii<hw.length();ii++){
          pushMatrix();
            float theta=ii*deltaTheta;
            translate(orbitRadius1*sin(theta),orbitRadius1*cos(theta),orbitHeight1);
            rotateZ(-theta);
            rotateX(radians(60)); /* tilted in for Southern hemisphere */
            //rotateX(ck.thetaMod());
            text(hw.substring(ii,ii+1),0.,0.,0.);   
          popMatrix();
        }     
       popMatrix();
    }
  popMatrix();
}  