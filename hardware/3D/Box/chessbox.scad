// Chess Box for Atari 2600 
// Andrew Davie, August 2020

$fn=64;                         // Smoothness of curves

// To create the 3 separate models, set MODE to 0/1/2 and render/save.
// These models are presented with a "+" for alignment when slicing/printing.

// DO NOT CHANGE MODE TYPES
MODE_TILES_BLACK = 1;
MODE_TILES_WHITE = 0;
MODE_BOX = 2;
MODE_BORDER = 3;
MODE_ALL = 4;
MODE_HINGE = 5;
MODE_PIECES = 6;

// DO CHANGE THIS TO THE ONE YOU WANT...
MODE = 2;

// Constants for size adjustments

BOX_WIDTH = 189;
BOX_LENGTH = 137*2;
BOX_HEIGHT = 21.4;
SURROUND = 4;                   // thickness of edge around board

BOARDER = 2;                  // outer border width around squares
BOARDER_Z = 0.4;                // depth of border

CORNER_RADIUS_INTERNAL = 2;     // Internal curve of box outer round edge
CORNER_RADIUS_EXTERNAL = 6;     // External curve of box outer round edge

UPPER_LAYER_THICKNESS = 0.4;
SQUARES_THICKNESS = 0.4;

BOX_WALL_THICKNESS = 5;
DIVIDER_Y = BOX_WALL_THICKNESS*2;       // The crosspiece between board halves

HINGE_WIDTH = 10;
HINGE_COUNT = 4;

MAG_RADIUS = 6/2+0.1;
MAG_HEIGHT = 6+0.1;

STEP = (BOX_WIDTH/(HINGE_COUNT+1));

// Size of an Atari Cartridge for the insert holder/well

CART_X = 84;
CART_Y = 100;
CART_Z = 19;
CART_WALL = 3;

// Other config constants (calculated or internal - do not modify)

ZAZZ = 1;                   // for fixing quick-view inaccuracies in plane masking

BSQ = (BOX_WIDTH-(2*SURROUND))/8;
GRID_SIZE = BSQ * 8;
HIGHLIGHT_SIZE = GRID_SIZE+BOARDER*2;


// And now the magic...

function bit_set(b, n) = floor(n / pow(2, b)) % 2;


module curvedBlock(width, length, height, edgeRoundness=6) {

    // Builds a solid with curved corners
    // Based around origin
    
    translate([-width/2,-length/2,0])
        linear_extrude(height)
            hull(){
                translate([edgeRoundness,edgeRoundness,0])
                    circle(r=edgeRoundness);
                translate([width-edgeRoundness,edgeRoundness,0])
                    circle(r=edgeRoundness);
                translate([width-edgeRoundness,length-edgeRoundness,0])
                    circle(r=edgeRoundness);
                translate([edgeRoundness,length-edgeRoundness,0])
                    circle(r=edgeRoundness);
            }
}

module grip(radius,length){
    
    translate([0,-length/2,0]) {
        sphere(r=radius);
        rotate([-90,0,0])
            cylinder(r=radius,h=length);
        translate([0,length,0])
            sphere(r=radius);
    }
}



module highlightSquare() {

    // The thin border square around the squares
    // Drawn around origin

    if (BOARDER > 0)
        difference() {
            translate([-HIGHLIGHT_SIZE/2, -HIGHLIGHT_SIZE/2, 0])
                cube([HIGHLIGHT_SIZE, HIGHLIGHT_SIZE, BOARDER_Z]);
            translate([-GRID_SIZE/2, -GRID_SIZE/2,-ZAZZ/2])
                cube([GRID_SIZE, GRID_SIZE, ZAZZ]);  
        }

    translate([0,0,-0.2])
        pieces();

}


module boardSquares(size, height, sizeAdjust, blackWhite) {

    // The 8x8 grid of squares
    // Drawn around origin
    
    translate([-size*4, -size*4, 0])
        for (x = [0:7])
            for(y = [0:7])
                translate([x*size-sizeAdjust/2, y*size-sizeAdjust/2, 0])
                    if (bit_set(0, x+y) == blackWhite)
                        cube([BSQ+sizeAdjust, BSQ+sizeAdjust, height]);
}


module boxProper() {
   
    // The main box
    difference(){

        union(){
            translate([0,-BOX_LENGTH/4,0])
            union() {
                difference(){
     
                    //curvedBlock(BOX_WIDTH, BOX_LENGTH/2, BOX_HEIGHT/2, CORNER_RADIUS_EXTERNAL);

                    translate([-BOX_WIDTH/2, -BOX_LENGTH/4, 0])
                        roundedcube([BOX_WIDTH, BOX_LENGTH/2, BOX_HEIGHT/2],radius=2);

                    // hollow out the block internals
                    
                    translate([0, 0, SQUARES_THICKNESS+UPPER_LAYER_THICKNESS])
                        curvedBlock(BOX_WIDTH-BOX_WALL_THICKNESS*2, BOX_LENGTH/2-BOX_WALL_THICKNESS*2,
                            BOX_HEIGHT/2+ZAZZ, CORNER_RADIUS_INTERNAL);
                }
            
                //divider();


            }
            translate([0,-CART_Y/2-BOX_WALL_THICKNESS,0])
                cartCradle();
  

        }

//            translate([0,0,-0.2])
//                pieces();

    translate([-(BOX_WIDTH/2-BOX_WALL_THICKNESS),
        -(BOX_LENGTH/2-BOX_WALL_THICKNESS),0])
        magnetx(1);
    translate([(BOX_WIDTH/2-BOX_WALL_THICKNESS),
        -(BOX_LENGTH/2-BOX_WALL_THICKNESS),0])
        magnetx(1);
        
        highlightSquare();

        // Remove the board squares (other colour)
        boardSquares(BSQ, SQUARES_THICKNESS, -2, 0);
        boardSquares(BSQ, SQUARES_THICKNESS, -2, 1);
        
    translate([0,-BOX_LENGTH/2,BOX_HEIGHT/2])
        rotate([0,0,90])
            grip(2,30);
        
        // Inserts for hinges
        for (hinge = [1:HINGE_COUNT]){
            translate([-BOX_WIDTH/2+(hinge)*STEP, 0, 0])
                hingeMask(0.1);
        }

    
    //translate([-BOX_WIDTH/2-1,0,BOX_HEIGHT/2-1.25])
    //    rotate([45,0,0])
    //        cube([BOX_WIDTH+2, 20, 20]);


             
    // Hole for filament hinge pin
    translate([-BOX_WIDTH/2-1,-BOX_WALL_THICKNESS/2-0.1,BOX_HEIGHT/2-BOX_WALL_THICKNESS/2-0.1])
        rotate([0,90,0])
            cylinder(r=1,h=BOX_WIDTH);


        
    }

    translate([-(BOX_WIDTH/2-BOX_WALL_THICKNESS),
        -(BOX_LENGTH/2-BOX_WALL_THICKNESS),1])
        magnetx();
    translate([(BOX_WIDTH/2-BOX_WALL_THICKNESS),
        -(BOX_LENGTH/2-BOX_WALL_THICKNESS),1])
        magnetx();


}

module hingeMask(tol){
    
    // Inserts for hinges
        
    translate([HINGE_WIDTH/2,-BOX_WALL_THICKNESS/2,BOX_HEIGHT/2-BOX_WALL_THICKNESS/2]) {
        hinge(HINGE_WIDTH, BOX_WALL_THICKNESS/2+tol, 0, BOX_WALL_THICKNESS+2*tol);
        rotate([90,0,0])
            hinge(HINGE_WIDTH, BOX_WALL_THICKNESS/2+tol, 0, BOX_WALL_THICKNESS+2*tol);
    }
    
}
    

module halfMask() {
            
    // mask out 1/2 with a cube
    translate([-BOX_WIDTH/2-ZAZZ/2,0,-ZAZZ/2])
        cube([BOX_WIDTH+ZAZZ,BOX_WIDTH,BOX_HEIGHT+ZAZZ]);
}


module divider() {
    
    //translate([-BOX_WIDTH/2, -DIVIDER_Y/2, 0])
    //    cube([BOX_WIDTH, DIVIDER_Y, BOX_HEIGHT/2]);
}


module cartCradle() {
    
    translate([0,0,SQUARES_THICKNESS+UPPER_LAYER_THICKNESS]) {
        difference(){
            curvedBlock(CART_X+CART_WALL, CART_Y+CART_WALL, BOX_HEIGHT/2-SQUARES_THICKNESS-UPPER_LAYER_THICKNESS, 2);
            translate([0,0,-1])
                curvedBlock(CART_X, CART_Y, BOX_HEIGHT/2-SQUARES_THICKNESS-UPPER_LAYER_THICKNESS+2, 1);
        }
        
        // The small cross-beam dividing the black/white pieces
        // Kind of tricky to calculate, so kludged
        translate([-CART_WALL/4,-CART_Y/2,0])
            rotate([0,0,180])
                cube([CART_WALL/2, BOX_LENGTH/2-CART_Y-CART_WALL*2,
                    BOX_HEIGHT/2-SQUARES_THICKNESS-UPPER_LAYER_THICKNESS]);

    }
}

module hinge(height, radius, hole, length) {

    rotate([-90,0,90])
        difference(){
            
            linear_extrude(height)
                hull(){
                    circle(r=radius);
                    translate([length,0,0])
                        circle(r=radius);
                }    
                            
            cylinder(r=hole, h=height);
            translate([length,0,0])
                cylinder(r=hole, h=height);
        }
}

module magnetx(solid=0) {
 
    if (solid==1)
        translate([0,0,BOX_HEIGHT/2-MAG_HEIGHT+1])
            cylinder(r=MAG_RADIUS, h=MAG_HEIGHT);
        
    if (solid == 0)
        difference(){
            cylinder(r=MAG_RADIUS+1, h=BOX_HEIGHT/2-1);
                translate([0,0,BOX_HEIGHT/2-MAG_HEIGHT+1])
                    cylinder(r=MAG_RADIUS, h=MAG_HEIGHT);
    }
}


module alignCross() {
    
    // An alignment mark for slicer positioning

    color("red") {
        translate([-5,14.9,0])
            cube([10,0.2,0.2]);
        translate([-0.1,10,0])
            cube([0.2,10,0.2]);
    }
}


// HERE STARTS THE ACTUAL RENDERERS
// SWITCHED BY "MODE"

// Draw the main box half only
if (MODE == MODE_BOX || MODE == MODE_ALL) {
    difference(){
        boxProper();
        //halfMask();
    }
    alignCross();

        //roundedcube([50,50,10], radius=2);

}

// Draw just the 2nd-colour squares
if (MODE == MODE_TILES_BLACK || MODE == MODE_ALL) {
    
    // Draw the odd-squares only
    difference(){
        boardSquares(BSQ, SQUARES_THICKNESS, -2, MODE);
        halfMask();
    }
    alignCross();
}

// Draw just the 2nd-colour squares
if (MODE == MODE_TILES_WHITE || MODE == MODE_ALL) {
    
    // Draw the odd-squares only
    difference(){
        boardSquares(BSQ, SQUARES_THICKNESS, -2, MODE);
        halfMask();
    }
    alignCross();
}


// Draw the board margin
if (MODE == MODE_BORDER || MODE == MODE_ALL) {
    
    // The surround border for the squares
    difference(){
        highlightSquare();
        halfMask();
    }
    alignCross();
}

if (MODE == MODE_HINGE) {
        rotate([0,90,0])
            hinge(HINGE_WIDTH, BOX_WALL_THICKNESS/2, 1.5, BOX_WALL_THICKNESS);
        
}



// More information: https://danielupshaw.com/openscad-rounded-corners/

// Set to 0.01 for higher definition curves (renders slower)
$fs = 0.8;

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


    if (MODE == MODE_PIECES) {
        pieces();
        alignCross();
    }

module pieces(){    
        //color("red")
        translate([93,-BOX_LENGTH/2+9,0.4])
        rotate([0,180,0])
        scale([1.45,1.45,1])
        linear_extrude(0.2) {
        text("\u265C\u265D\u265B\u265A\u265E\u265F",font="Arial Unicode MS",size=16);
//        translate([46,0,0])
//        rotate([0,180,0])
//        text("\u265E",font="Arial Unicode MS",size=16);
        }
}


module piece_K(){
}
    
