use <paginate.scad>;
use <flat_pack_joints/boxmaker.scad>;

// The size of a piece of baffle_stock material
baffle_stock = [480, 279, 1.58];   // 11x19

// Housing material thickness (mm)
thickness = 3;

// the size an individual pixel needs to be
pixel = [33.334, 33.334, 50];

display_in_px = [3, 2, 1];
display = [pixel[0] * display_in_px[0], pixel[1] * display_in_px[1], pixel[2]];

led_strip_width = 10;
led_strip_thickness = 0.5;
apa102 = [5, 5, 1.5];

usb_cutout = [8, 12];
//usb_cutout_offset = 11.4;
usb_cutout_offset = 15.4;

clear_acrylic_top = 3;
// inset the baffle so it can be held in place by the walls
baffle_inset = [1, 1, 0];
// extra width in etch to make baffle join with wood
baffle_etch_extra = 0.5;
lip = clear_acrylic_top/2 + baffle_etch_extra;

button_hole_r = 6;
button_clearance = 1;
button_position = [pixel[0]/2, button_hole_r + button_clearance];
button_holder_h = 10;
button_holder_w = pixel[0] - baffle_inset[0] - baffle_stock[2]/2;
// distance between button hole and holder
button_holder_distance = 8;
button_holder_clearance = button_position[1] - button_holder_h/2;


short_strip_rows = [ for (x = [pixel[0] : pixel[0] : display[0] - pixel[0]]) x ];
long_strip_rows  = [ for (x = [pixel[1] : pixel[1] : display[1] - pixel[1]]) x ];


*cut_top();
cut_strips();

*button_holder();


enclosure();


/////////////////////////////////////////////////////////////////////

module etchings(offsets, width, extra) {
  etch_inset = [0.1, 0];
  slot_w = baffle_stock[2] + baffle_etch_extra;
  front_w = clear_acrylic_top + baffle_etch_extra;

  for (x = offsets)
    translate([x - slot_w/2 - baffle_inset[0], etch_inset[0]])
      square([slot_w, display[2]]);
  translate([-extra/2, display[2]] + etch_inset)
    square([width + extra, front_w] - etch_inset * 2);
}

module layout_2d_inside_etch(box_inner, thickness) {
  layout_2d(box_inner, thickness) {
    children(0);
    children(1);
    rotate([0, 180])
      children(2);
    rotate([0, 180])
      children(3);
    rotate([0, 180])
      children(4);
    rotate([0, 180])
      children(5);
  }
}

module enclosure() {
  // Finger width (mm)
  finger_width = thickness * 2;

  box_inner = display - baffle_inset * 2  + [0, 0, lip];

  // Finger width (X, Y, Z, TopX, TopY) (mm)
  fingers = [finger_width, finger_width, finger_width, 0, 0];

  // BEGIN 2D LAYOUT
  //layout_2d_inside_etch(box_inner, thickness) {
  // END 2D LAYOUT

  // BEGIN 3D PREVIEW
  translate([0, 0, 0] - baffle_inset)  preview(); button_holder_preview(); color("green", alpha=0.5) layout_3d(box_inner, thickness) {
  // END 3D PREVIEW

    empty();
    // back
    difference() {
      side_xy(box_inner, thickness, fingers);
      translate([-thickness - 0.01, box_inner[1] - usb_cutout_offset - usb_cutout[1]])
        square(usb_cutout + [thickness, 0]);
      translate([30, 54])
        rotate([0, 0, -90])
          import("branding.dxf");
    }
    // bottom
    difference() {
      side_yz(box_inner, thickness, fingers);
      etchings(long_strip_rows, box_inner[1], 0);
      translate([box_inner[1] - thickness - button_holder_distance, button_holder_clearance]) {
        square([thickness, button_holder_h/3]);
        translate([0, button_holder_h * 2/3])
          square([thickness, button_holder_h/3]);

      }
    }
    // top
    difference() {
      side_yz(box_inner, thickness, fingers);
      etchings(long_strip_rows, box_inner[1], 0);
    }
    difference() {
      side_xz(box_inner, thickness, fingers);
      etchings(short_strip_rows, box_inner[0], baffle_inset[0] * 2);
      translate(button_position)
        circle(r=button_hole_r);
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

module button_holder_preview() {
  color("red")
  translate([0, thickness + button_holder_distance, button_holder_clearance])
    rotate([90, 0, 0])
      linear_extrude(height=thickness)
        button_holder();
  translate([5, 12.5, 0])
  rotate([0, -90, 0])
  cube([38, 18, 5]);
}

module top() {
  cube([display[0], display[1], clear_acrylic_top]);
}

module button_holder() {
  difference() {
    square([button_holder_w, button_holder_h]);
    translate([button_position[0], button_holder_h/2])
      square([button_holder_h + 2, 2], center=true);
    }

  translate([-thickness, 0])
    square([thickness, button_holder_h/3]);
  translate([-thickness, button_holder_h * (2/3)])
    square([thickness, button_holder_h/3]);

  translate([button_holder_w, 0])
    square([baffle_stock[2], button_holder_h/3]);
  translate([button_holder_w, button_holder_h * (2/3)])
    square([baffle_stock[2], button_holder_h/3]);
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
