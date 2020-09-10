$fn=32;


///////////////////////////////////////////////////////////////////////////
// Multiple part definitions...  DO NOT MODIFY...
// Set "MODE" to the part you want rendered

MODE_FRONT= 0;     // frontShell (SCREW HOLES)
MODE_BACK = 1;       // BACK
MODE_ALL = 2;
MODE_STRAP = 3;
MODE_LOGO = 4;
MODE_LABEL = 5;
MODE_LETTERS = 6;


///////////////////////////////////////////////////////////////////////////
// Customizable values...


// Which part to render. SEE MODE_* DEFINITIONS, ABOVE
MODE = 0; // [0:FRONT SHELL, 1:BACK SHELL, 2:ASSEMBLED, 3:STRAP, 4:LOGO, 5:LABEL, 6:LETTERS]

// Inbuilt supports for the cartrige shell overhangs.
SUPPORT_TABS = true;            // true or false


// Word on the label. Should be 8 letters maximum
LABEL_TEXT = "PLUSCART"; //8

// Side-wall thickness.
WALL = 2.4;

// Front/back wall thickness
WALLZ = 2;

///////////////////////////////////////////////////////////////////////////

FRONT_LOGO = true;
BACK_LOGO = false;
STRAP_TOL = 0.3;



BOXX = 81.5;
BOXY = 98.2;
BOXZ = 18.275;



ANGX = 18.91;
ANGY = 1.6;
ANGY2 = 2.8;
ANGX2 = 5;

ROUNDBOXRADIUS = 1.5;


LATCH_UP = 3;

SQ = (BOXX-5)/9;
SQ2 = SQ+1;
YOFF = 15;
RD = 1;

SPACERZ = 10;
SPACERX = 3;
SPACERY = 10;
SPACER_OFFSET = -7.2;
SPACERLIP=0;
CONSTRAINER_TOL = 0.05;


SLOTBARX = BOXX-2*WALL;
SLOTBARY = 3.8;
SLOTBARZ = BOXZ/2-WALLZ;
//
BOARD_THICKNESS = 1.6;

SLOTINDENTZ = BOARD_THICKNESS;

SLOTX = 36.5;

SUPPORTBOXX = SLOTX-3;
SUPPORTBOXY = 19;
SUPPORTBOXRADIUS = 2;
SUPPORTBOXRADIUS2 = 1;
SUPPORTBOXWALL = 1.2;

SLOTSTMX = 64;

STRAP_WIDTH = SQ;
STRAP_THICK = 1.2;
STRAP_INDENT = SQ+1;
STRAP_HOOK = WALLZ/2+0.75;




// More information: https://danielupshaw.com/openscad-rounded-corners/


module roundedcube(size = [1, 1, 1], center = false, radius = 0.5, apply_to = "all") {
	// If single value, convert to [x, y, z] vector
	size = (size[0] == undef) ? [size, size, size] : size;

	translate_min = radius;
	translate_xmax = size[0] - radius;
	translate_ymax = size[1] - radius;
	translate_zmax = size[2] - radius;

	diameter = radius * 2;

	obj_translate = (center == false) ?
		[0, 0, 0] : [
			-(size[0] / 2),
			-(size[1] / 2),
			-(size[2] / 2)
		];

	translate(v = obj_translate) {
		hull() {
			for (translate_x = [translate_min, translate_xmax]) {
				x_at = (translate_x == translate_min) ? "min" : "max";
				for (translate_y = [translate_min, translate_ymax]) {
					y_at = (translate_y == translate_min) ? "min" : "max";
					for (translate_z = [translate_min, translate_zmax]) {
						z_at = (translate_z == translate_min) ? "min" : "max";

						translate(v = [translate_x, translate_y, translate_z])
						if (
							(apply_to == "all") ||
							(apply_to == "xmin" && x_at == "min") || (apply_to == "xmax" && x_at == "max") ||
							(apply_to == "ymin" && y_at == "min") || (apply_to == "ymax" && y_at == "max") ||
							(apply_to == "zmin" && z_at == "min") || (apply_to == "zmax" && z_at == "max")
						) {
							sphere(r = radius);
						} else {
							rotate = 
								(apply_to == "xmin" || apply_to == "xmax" || apply_to == "x") ? [0, 90, 0] : (
								(apply_to == "ymin" || apply_to == "ymax" || apply_to == "y") ? [90, 90, 0] :
								[0, 0, 0]
							);
							rotate(a = rotate)
							cylinder(h = diameter, r = radius, center = true);
						}
					}
				}
			}
		}
	}

}


module top(){
    
    //import("top.stl");
    
    difference(){
        union(){
    
            translate([0,0,BOXZ/2]) {
                difference(){
                    roundedcube(size=[BOXX,BOXY,BOXZ],center=true,radius=ROUNDBOXRADIUS);
                    translate([0,-0.4,0])
                        roundedcube(size=[BOXX-2*WALL,BOXY-2*WALL,BOXZ-2*WALLZ],center=true);

                    translate([-BOXX/2-1,-BOXY/2-1,2])
                        cube([BOXX+2,BOXY+2,BOXZ]);
                    
                    translate([-BOXX/2+WALL,-BOXY/2-5,-BOXZ/2+WALLZ])
                        cube([BOXX-2*WALL,10,BOXZ]);

                }

            }

            rightAngle(BOXZ/2+2,false);

            translate([-BOXX/2+WALL,-BOXY/2,WALLZ])
                cube([1.2,14,BOXZ/2+2-WALLZ]);
            translate([BOXX/2-WALL-1.2,-BOXY/2,WALLZ])
                cube([1.2,14,BOXZ/2+2-WALLZ]);





    }

    labelSlot();

    if (BACK_LOGO)
        logo();

    //label();


    //translate([0,0,BOXZ+2])
    //rotate([0,180,0]) {
        
    //        xylatch(0.4, true);
    //}

    //versionx();

    translate([-BOXX/2+WALL/2,-BOXY/2,WALLZ])
        rotate([0,0,-15])
        cube([4,12,BOXZ/2+2]);

    translate([0,0,BOXZ/2+WALLZ*2])
    rotate([0,180,0])
       translate([-BOXX/2+WALL/2,-BOXY/2,WALLZ-1])
        rotate([0,0,-15])
        cube([4,12,BOXZ/2+1]);

    if (SUPPORT_TABS)
        allstraps(STRAP_TOL);

    /*    for (y=[0,1]) {
//    for (x=[-1,1]){    
    translate([x*(BOXX/2-WALL/2)-WALL/2,BOXY/2-5.8-WALL-y*58-5,BOXZ/2+2-1])
        cube([3,10,1.5]);
    }}
*/

    }
    
    difference(){

    xylatch(2,0, true);
    translate([0,0,BOXZ+4])
    rotate([0,180,0])
        xylatch(2,0.2, false);
    }

    

    //allstraps(0);
    strapsupportx();
}


module allstraps(tol){
        
        for(y=[0,1])
            translate([0,-20.5+40*y,(BOXZ+2)/2])
    for(x=[-1,1])
        translate([x*BOXX/2,0,0])
            rotate([0,0,90*(x+1)-90]) {
                strap2(tol);
//                translate([0,0,0])
//                    strapsupport();
            }
    
}


module strapsupportx(tol=0){
        
        for(y=[0,1])
            translate([0,-20.5+40*y,0])
    for(x=[-1,1])
        translate([x*BOXX/2+0.6*x,0,0])
            rotate([0,0,90*(x+1)-90]) {
                    strapsupport();
            }
    
}



module xylatch(zfix,adjust,top){
    
    for (y=[0,1]) {
        for (x=[-1,1]){
            translate([x*(BOXX/2-WALL-2.25),y*65-23,WALLZ])
                //rotate([0,0,(x+1)*90])
                    roundlatch(3.8+adjust,BOXZ/2+zfix-WALLZ,top);
        }
    }
}

 

module label(){

    translate([0,BOXY/2-1.4,0]){

        translate([-(BOXX-45)-WALL*2,0,0])
            cube([BOXX-WALL*2-0.8,0.4,BOXZ-0.5]);

        }
}

module letters(){

    translate([0,BOXY/2-1.4,0]){

        translate([BOXX-54.9,0,4.5])
            rotate([-90,180,0])
                scale([1.25,1,1])
                    linear_extrude(0.4)
                            text(LABEL_TEXT,font="SF Atarian System",size=10);

        }

}


module labelSlot(){

    translate([-(BOXX-WALL*2)/2,BOXY/2-1.6,WALLZ/2])
        cube([BOXX-WALL*2,0.8,BOXZ]);

    translate([-(BOXX-WALL*2)/2+WALL/2,BOXY/2-1.4,WALLZ])
        cube([BOXX-WALL*2-WALL,1.4,BOXZ]);

    //}

//    translate([-(BOXX-WALL*2)/2,BOXY/2-1.2,WALLZ/2])
//        cube([BOXX-WALL*2,1.2,BOXZ]);

/*        translate([BOXX-8,1,5])
            rotate([-90,180,0])
                scale([0.75,1,1])
                    linear_extrude(0.8)
                        text("PlusCart",font="Demun Lotion",size=10);
*/

}

module roundedPillar(width,length,height,radius,radius2,wall) {

    difference(){
        solidPillar(width,length,height,radius);
        if (wall>0) {
            translate([0,0,-1])
                solidPillar(width-2*wall,length-2*wall,height+2,radius2);
        }
    }
}

module solidPillar(width,length,height,radius){
        linear_extrude(height)
            hull(){
                for(x=[-1,1])
                    for(y=[-1,1]) {
                        translate([-x*(width-2*radius)/2,-y*(length-2*radius)/2,-height/2])
                            circle(r=radius);
                    }
                }
}




module rightAngle(z,pin,top=false) {
    

    if (pin){
        
        // Front shell
        // Section that holds the cart itself

        translate([0,-4.2,WALLZ])
            difference(){
                
                union(){
                
                    translate([-SLOTBARX/2,0,0])
                        cube([SLOTBARX,SLOTBARY,SLOTBARZ]);

                    translate([0,-SUPPORTBOXY/2+SUPPORTBOXRADIUS])
                        roundedPillar(
                            SUPPORTBOXX,
                            SUPPORTBOXY,
                            SLOTBARZ-SLOTINDENTZ,
                            SUPPORTBOXRADIUS,
                            SUPPORTBOXRADIUS2,
                            SUPPORTBOXWALL
                        );
                }

                translate([-SLOTX/2,-1,SLOTBARZ-SLOTINDENTZ])
                    cube([SLOTX,SLOTBARY+2,SLOTBARZ+2]);
   
            }
            

    } else {
       
        translate([0,-4.2,WALLZ])
            difference(){
                
                union(){
                
                    translate([-SLOTBARX/2,0,0])
                        cube([SLOTBARX,SLOTBARY,SLOTBARZ+2]);

                    translate([0,-SUPPORTBOXY/2+SUPPORTBOXRADIUS])
                        roundedPillar(
                            SUPPORTBOXX,
                            SUPPORTBOXY,
                            SLOTBARZ+2,
                            SUPPORTBOXRADIUS,
                            SUPPORTBOXRADIUS2,
                            SUPPORTBOXWALL
                        );
                }

                // STM board insert
                translate([-SLOTSTMX/2,1.2,-1])
                    cube([SLOTSTMX,SLOTBARY-1.2+1,SLOTBARZ+4]);
   
            }

     }
}



module frontShell(){
// BOTTOM (=frontShell, with screw holes)
    
    //import("bottom.stl");

    difference(){

    
        union(){
            
            translate([0,0,BOXZ/2]) {
                difference(){
            
                    roundedcube(size=[BOXX,BOXY,BOXZ],center=true,radius=ROUNDBOXRADIUS);
                    translate([0,-0.4,0])
                        roundedcube(size=[BOXX-2*WALL,BOXY-2*WALL,BOXZ-2*WALLZ],center=true);

                    // slice off top of box, leaving a tray
                    translate([-BOXX/2-1,-BOXY/2-1,0])
                        cube([BOXX+2,BOXY+2,BOXZ/2]);
                    
                    // slice off front of tray = cart insert hole
                    translate([-BOXX/2+WALL,-BOXY/2-5,-BOXZ/2+WALLZ])
                        cube([BOXX-2*WALL,10,BOXZ]);

                    // LED window
                    translate([BOXX/2-12.5,-BOXY/2+BOXY-16.5,-BOXZ/2+0.4]){
                        cylinder(r1=2,r2=6,h=2);
                    }

                }
            }   
        
            rightAngle(BOXZ/2-1-ROUNDBOXRADIUS/2, true);
            
            
            // The Y-axis constrainers around the middle bar

            translate([0,-4.2+SLOTBARY/2,0])
                for (x=[-1,1])
                    for (y=[-1,1])
                        translate([x*(BOXX/2-WALL-SPACERX/2-CONSTRAINER_TOL),
                            y*(SPACERY/2+SLOTBARY/2+CONSTRAINER_TOL),
                            WALLZ+(BOXZ/2+1)/2-1]) {
                            rotate([0,0,(x+1)*90])
                                cube([SPACERX,SPACERY,BOXZ/2+SPACERLIP],center=true);
                            
                                translate([0,0,SPACERLIP+SPACERX+1.6])
                            rotate([90,0,0])
                                cylinder(r=SPACERX/2,h=SPACERY,center=true);
                                
                                }
            translate([-BOXX/2+WALL,-BOXY/2,WALLZ])
                cube([1.2,14,BOXZ/2-WALLZ]);
            translate([BOXX/2-WALL-1.2,-BOXY/2,WALLZ])
                cube([1.2,14,BOXZ/2-WALLZ]);


        
            }
            
            

//    translate([0,0,BOXZ+2])
//    rotate([0,180,0]) {
        
//            xylatch(0.4);
//}



            //versionx();

    labelSlot();
//    label();
 
    if (FRONT_LOGO)
        logo();
            
    
    translate([-BOXX/2+WALL/2,-BOXY/2,WALLZ])
        rotate([0,0,-15])
        cube([4,12,BOXZ/2]);

    translate([0,0,BOXZ/2+WALLZ*2])
    rotate([0,180,0])
       translate([-BOXX/2+WALL/2,-BOXY/2,WALLZ])
        rotate([0,0,-15])
        cube([4,12,BOXZ/2]);

    if (SUPPORT_TABS)
        allstraps(STRAP_TOL);

    }
    xylatch(0,0, false);
    strapsupportx();
    //allstraps(0);

    //translate([0,0,WALLZ/2])
    //    label();
    
}


if (MODE == MODE_FRONT){
    frontShell();
}


module roundlatch(rd,ht,top=false){
    
/*    
    if (!top){
       
        // male pin...
        
        cylinder(r1=rd, r2=rd/2,h=ht-1);
        cylinder(r=rd/2,h=ht+3);
        translate([0,0,ht+2.35])
            scale([1,1,0.75])
                sphere(r=rd/2+0.3);
    }

    else {
        
        // female receptor
        
        difference(){
            cylinder(r=rd,h=ht-1);
            translate([0,0,-1]) {
                cylinder(h=ht+2, r1=2);
                translate([0-5,0,WALLZ/2])
                    cube([10,1,ht]);
            }
        }
    }
*/    
    
}

module latch(rd,ht,rot, tol=0){
    
    translate([0.55,0,ht])
        rotate([90,40,0])
            cube([2*(rd+tol),2*(rd+tol),10+2*tol],center=true);
 
    translate([0.3,-5,0])
        cube([3.75,10+2*tol,ht+(2*(rd+tol)/sqrt(2))]);
    
}




// TOP

if (MODE == MODE_BACK){
    
    top();
//    frontShell();

}


if (MODE==MODE_ALL){

        top();
    translate([0,0,BOXZ+2])
        rotate([0,180,0]) {
            frontShell();
            logo(0.8);
        }
    allstraps(0);
    
    //color("red")
        translate([WALL/2+WALL/2+0.2,0.2,WALLZ/2])
            label();
        translate([WALL/2+WALL/2+0.2,0.2,WALLZ/2])
            letters();
}



    
if (MODE==MODE_STRAP){

/*    rotate([0,90,0])
    translate([-STRAP_WIDTH/2,0,0])
        strap(0,0.75,0.2,true);
*/
    rotate([0,-90,0])
        strap2(0.02);
    
    //rotate([0,90,0])
    //translate([-STRAP_WIDTH/2,0,0])
    //    strap(0.8);
}

if (MODE == MODE_LABEL){
    translate([0,0,-BOXY/2])
    rotate([90,0,0])
        label();
}
if (MODE == MODE_LETTERS){
    translate([0,0,-BOXY/2])
    rotate([90,0,0])
        letters();
}


if (MODE == MODE_LOGO){
    logo(0.8);
}


module logo(tolx=0){
    
    L = [[0,1,0,0,0,1,0],
         [1,0,0,1,0,0,1],
         [1,0,1,1,1,0,1],
         [1,0,0,1,0,0,1],
         [0,1,0,0,0,1,0]];
    
    translate([-19,-2,0])
    scale([0.75,0.75,1])
    for (x=[0:6])
        for (y=[0:4]) {

            if (L[y][x]!=0)
                translate([x*SQ,y*SQ,0])
                    //difference(){
                        
                        linear_extrude(0.4)
                        hull(){
                            for (cx=[-1,1])
                                for (cy=[-1,1])
                                    translate([cx*(SQ2/2-RD-tolx),cy*(SQ2/2-RD-tolx),0])
                                        circle(r=RD);
                            }
                            
                        
                        
                    //cube([SQ+0.4,SQ+0.4,0+L[y][x]*0.4],center=true);           
                    //cube([SQ+0.1-1,SQ+0.1-1,0+L[y][x]*0.8],center=true);           
                    //}
                    //cylinder(d=SQ*15/14,h=0.2+L[y][x]*0.4);
        }
    
/*    for (rd=[1:8])
        translate([0,YOFF,0]){
            difference(){
                cylinder(r=rd*8+23,h=0.4,$fn=8);
                translate([0,0,-1])
                    cylinder(r=rd*8+19,h=2,$fn=8);
            }
        }
*/
/*    translate([0,0,0.4])
    rotate([0,180,0])
    linear_extrude(0.4) {
        
        translate([-26,10,0])
            text("(+)",font="Arial Rounded MT Bold:style=bold",size=24);
        
    }
    */
    
        
    
    
}


module strap(tol,longer=0,thinner=0,tab=false){

        translate([(STRAP_WIDTH+tol)/2,0,0])
    rotate([90,0,180])

    difference(){
        translate([0,0,0])
        cube([STRAP_WIDTH+tol,BOXZ+2+tol+longer-2*thinner,STRAP_INDENT-2*thinner]);
        translate([-1,STRAP_THICK-thinner,STRAP_THICK+tol-thinner]) {
            cube([STRAP_WIDTH+2,BOXZ+longer+2-2*STRAP_THICK,STRAP_INDENT-2*STRAP_THICK-2*tol]);
            translate([-1,STRAP_HOOK,1])
                cube([STRAP_WIDTH+2,longer+BOXZ+2-2*STRAP_THICK-2*STRAP_HOOK,STRAP_INDENT+2]);

        }
    }

    if (tab) {

        translate([STRAP_INDENT/2-STRAP_THICK/2+tol-thinner+0.10,6,-STRAP_THICK-thinner+(BOXZ+2+tol+longer-2*thinner)/2+2])
        rotate([0,90,0]) {
            translate([-5,-4.9,-0.2])
            cube([10,10,0.4]);
        }
    }


}


module strap2(tol=0){

    translate([-STRAP_WIDTH/2-tol,STRAP_INDENT+tol,0/*+STRAP_WIDTH*/])
    rotate([0,90,0]) {
        union() {
            difference(){
                roundedPillar(
                    BOXZ+2+2*tol,
                    STRAP_INDENT*2+2*tol,
                    STRAP_WIDTH+tol*2,
                    ROUNDBOXRADIUS,
                    ROUNDBOXRADIUS/2,
                    STRAP_THICK+tol*2
                );
                translate([-(BOXZ+2+tol*2)/2-1,0,-1])
                    cube([BOXZ+4+tol*2,STRAP_INDENT+tol*2+1,STRAP_WIDTH+tol*2+2]);
            }
            color("green")

            translate([-5,-10+STRAP_THICK+0.6,0])
                cube([10,10,0.2]);
        }

    translate([0,-(STRAP_THICK+tol*2)/2,0])
    for (x=[-1,1])
        rotate([0,0,90*(x+1)])
            translate([(BOXZ+2+tol*2)/2-(STRAP_THICK+tol*2)-0.7,0,(STRAP_WIDTH+tol*2)/2])

                cube([STRAP_HOOK+tol*2,STRAP_THICK+tol*2,STRAP_WIDTH+tol*2],center=true);

/*        for(x=[-1,1])
            translate([x*((BOXZ+2+tol*2)/2-STRAP_HOOK+tol*2),-STRAP_THICK+tol*2,0])
            rotate([0,0,(x+1)*180])
                translate([-(STRAP_HOOK+STRAP_THICK+tol*2)/2,0,0])
                    cube([STRAP_HOOK+STRAP_THICK+tol*2,STRAP_THICK+tol*2,STRAP_WIDTH+tol*2]);
  */      
    }

}




module strapsupport(tol=0){

    if (SUPPORT_TABS) {
//        scale([0.9,1,1])
            translate([(STRAP_WIDTH-0.5+tol)/2,5,(STRAP_THICK+STRAP_TOL-0.2)/2])
 //       rotate([90,0,180]){
    
            translate([-(STRAP_WIDTH-STRAP_TOL)/2,STRAP_THICK/2-3.6,0])
            cube([STRAP_WIDTH-STRAP_TOL,STRAP_WIDTH-STRAP_TOL+5,STRAP_THICK+STRAP_TOL-0.2],center=true);

//        difference(){
//            cube([STRAP_WIDTH-0.5+tol,BOXZ+2+tol,STRAP_INDENT+tol]);
//            translate([-1,STRAP_THICK,STRAP_THICK]) {
//                cube([STRAP_WIDTH+2,BOXZ+2-2*STRAP_THICK,STRAP_INDENT-2*STRAP_THICK]);
               
//            }
//        translate([-1,STRAP_THICK-0.2,-3+STRAP_THICK+0.4])
//            cube([STRAP_WIDTH+2,BOXZ+10,STRAP_INDENT+2]);
//        }
//        }
        
        translate([0,-5,0])
        cylinder(r=7,STRAP_THICK+STRAP_TOL-0.2);
    }
}



module versionx(){
    
        translate([35.9,BOXY/2-0.4,5]) {
            rotate([-90,180,0])
        scale([0.75,1,1])
        linear_extrude(0.4){
            text(LABEL_TEXT,font="SF Atarian System",size=10);
        }
    }
}



/*translate([-37,BOXY/2,BOXZ-2.5])
        rotate([-90,0,0])
    linear_extrude(0.8)
    scale([0.7,1,1])
text("PlusCart",font="Demun Lotion",size=11);
*/
