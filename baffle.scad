use <paginate.scad>;
use <flat_pack_joints/boxmaker.scad>;

// The size of a piece of baffle_stock material
//stock = [610, 457, 1.58]; // 24x18
//stock = [812, 457, 1.58]; // 32x18
//stock = [2438, 1219, 1.58]; // 96x48
baffle_stock = [480, 279, 1.58];   // 11x19
//baffle_stock = [300, 300, 1.5875];

// the size an individual pixel needs to be
pixel = [33.334, 33.334, 50];

// the full size of the display
//display = [2440, 502, pixel[2]];

//display_in_px = [73, 15, 1];
display_in_px = [3, 2, 1];
display = [pixel[0] * display_in_px[0], pixel[1] * display_in_px[1], pixel[2]];

led_strip_width = 10;
led_strip_thickness = 0.5;
apa102 = [5, 5, 1.5];

clear_acrylic_top = 3;
lip = clear_acrylic_top/2;
// inset the baffle so it can be held in place by the walls
baffle_inset = [1, 1, 0];

short_strip_rows = [ for (x = [pixel[0] : pixel[0] : display[0] - pixel[0]]) x ];
long_strip_rows  = [ for (x = [pixel[1] : pixel[1] : display[1] - pixel[1]]) x ];


*preview();

*cut_strips();
*cut_top();
*cut_edges();


enclosure();


// Material thickness (mm)
thickness = 3;

/////////////////////////////////////////////////////////////////////

module etchings(offsets, width, extra) {
  etch_inset = [0.1, 0];
  for (x = offsets)
    translate([x - baffle_stock[2]/2 - baffle_inset[0], etch_inset[0]])
      square([baffle_stock[2], display[2]]);
  translate([-extra/2, display[2]] + etch_inset)
    square([width + extra, clear_acrylic_top] - etch_inset * 2);
}

module enclosure() {
  // Finger width (mm)
  finger_width = thickness * 2;

  box_inner = display - baffle_inset * 2  + [0, 0, lip];

  // Finger width (X, Y, Z, TopX, TopY) (mm)
  fingers = [finger_width, finger_width, finger_width, 0, 0];

  // BEGIN 2D LAYOUT
  //layout_2d(box_inner, thickness) {
  // END 2D LAYOUT

  // BEGIN 3D PREVIEW
  translate([0, 0, 0] - baffle_inset)  preview(); color("green", alpha=0.5) layout_3d(box_inner, thickness) {
  // END 3D PREVIEW

    empty();
    side_xy(box_inner, thickness, fingers);
    difference() {
      side_yz(box_inner, thickness, fingers);
      etchings(long_strip_rows, box_inner[1], 0);
    }
    difference() {
      side_yz(box_inner, thickness, fingers);
      etchings(long_strip_rows, box_inner[1], 0);
    }
    difference() {
      side_xz(box_inner, thickness, fingers);
      etchings(short_strip_rows, box_inner[0], baffle_inset[0] * 2);
    }
    difference() {
      side_xz(box_inner, thickness, fingers);
      etchings(short_strip_rows, box_inner[0], baffle_inset[0] * 2);
    }
  }
}

module cut_strips() {
  cut_strip_short();
  translate([display[1] + 2, 0, 0])
    cut_strip_long();
}

module cut_edges() {
  cut_strip(2, [display[0], baffle_stock[2], display[2]])
    short_edge_strip();
  translate([0, (display[2] + 2) * 2, 0])
  cut_strip(2, [display[1] + baffle_stock[2] * 2, baffle_stock[2], display[2]])
    long_edge_strip();
}

module cut_top() {
  projection(cut = true)
    top();
}

module cut_strip_short() {
  cut_strip(len(short_strip_rows), [display[1], baffle_stock[2], display[2]])
    short_strip();
}

module cut_strip_long() {
  cut_strip(len(long_strip_rows), [display[0], baffle_stock[2], display[2]])
    long_strip();
}

module cut_strip(copies, bounds, spacing = 2) {
  y_spacing = bounds[2] + spacing;
  strips_bounds = [bounds[0], copies * y_spacing, bounds[1]];
  for (offset = [ 0 : y_spacing : y_spacing * (copies - 1) ]) {
    translate([0, offset, 0])
        render(convexity = 2)
          children();
  }
}

led_strip_offset = (pixel[0] / 2 - led_strip_width/2) + baffle_stock[2]/2;

module preview() {
  for (y = [led_strip_offset : pixel[1] : (display[1] - pixel[1]) + led_strip_offset])
    translate([0, y, 0])
      led_strip(display[0], 30);

  for (x = short_strip_rows) {
      translate([x, 0, display[2]])
        rotate([90, 180, -90])
          translate([0, 0, -baffle_stock[2]/2])
            linear_extrude(height=baffle_stock[2])
              short_strip();
  }
  translate([0, 0, 0])
    for (y = long_strip_rows) {
      translate([0, y, 0])
        rotate([90, 0, 0])
          translate([0, 0, -baffle_stock[2]/2])
            linear_extrude(height=baffle_stock[2])
              long_strip();
    }

  *translate([0, 0, display[2]])
    top();
}

module top() {
  cube([display[0], display[1], clear_acrylic_top]);
}

module led_strip(length, led_per_meter) {
  led_spacing=1000/led_per_meter;
  color("white") {
    cube([length, led_strip_width, led_strip_thickness]);
    for (x = [0 : led_spacing: length - led_spacing]) {
      translate([led_spacing/2 + x,(led_strip_width/2-apa102[1]/2), led_strip_thickness])
      cube(apa102);
    }
  }
}

module short_strip() {
  difference() {
    square_with_slots([display[1], display[2]], pixel[0], [baffle_stock[2], display[2]/2]);
    for (x = [pixel[0] / 2 - led_strip_width/2 + baffle_stock[2]/2: pixel[0] : display[1]]) {
      translate([x, display[2]-led_strip_thickness])
        square([led_strip_width, led_strip_thickness*2]);
    }
  }
}


module long_strip() {
  square_with_slots([display[0], display[2]], pixel[0], [baffle_stock[2], display[2]/2]);
}

module short_edge_strip() {
  cube([display[0], baffle_stock[2], display[2]]);
}

module long_edge_strip() {
  cube([display[1] + baffle_stock[2] * 2, baffle_stock[2], display[2]]);
}

module square_with_slots(square_size, slot_spacing, slot_size) {
  difference() {
    square(square_size);
    for (x = [slot_spacing : slot_spacing : square_size[0] - slot_size[0]]) {
    translate([x - slot_size[0]/2, 0])
      square(slot_size);
    }
  }
}
