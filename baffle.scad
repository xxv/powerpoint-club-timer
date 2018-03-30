use <paginate.scad>

// The size of a piece of stock material
//stock = [610, 457, 1.58]; // 24x18
//stock = [812, 457, 1.58]; // 32x18
//stock = [2438, 1219, 1.58]; // 96x48
stock = [480, 279, 1.58];   // 11x19
//stock = [300, 300, 1.5875];

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

*preview();

*cut_strips();
cut_top();
*cut_edges();

*cut_strip_short();
*cut_strip_long();

short_strip_rows = [ for (x = [pixel[0] : pixel[0] : display[0] - pixel[0]]) x ];
long_strip_rows  = [ for (x = [pixel[1] : pixel[1] : display[1] - pixel[1]]) x ];

module cut_strips() {
  cut_strip_short();
  translate([display[1] + 5, 0])
    cut_strip_long();
}

module cut_edges() {
  cut_strip(2, [display[0], stock[2], display[2]])
    short_edge_strip();
  translate([0, (display[2] + 2) * 2, 0])
  cut_strip(2, [display[1] + stock[2] * 2, stock[2], display[2]])
    long_edge_strip();
}

module cut_top() {
  projection(cut = true)
    top();
}

module cut_strip_short() {
  cut_strip(len(short_strip_rows), [display[1], stock[2], display[2]])
    short_strip();
}

module cut_strip_long() {
  cut_strip(len(short_strip_rows), [display[0], stock[2], display[2]])
    long_strip();
}

module cut_strip(copies, bounds, spacing = 2) {
  projection(cut = true) {
    y_spacing = bounds[2] + spacing;
    strips_bounds = [bounds[0], copies * y_spacing, bounds[1]];
    paginate(strips_bounds, stock, [pixel[0], y_spacing, 0], first_page_offset=[pixel[0]/2, 0, 0]) {
      for (offset = [ 0 : y_spacing : y_spacing * (copies - 1) ]) {
        translate([0, offset, 0])
          rotate([-90, 0, 0])
            render(convexity = 2)
              children();
      }
    }
  }
}

led_strip_offset = (pixel[0] / 2 - led_strip_width/2) + stock[2] + stock[2]/2;

module preview() {
  for (y = [led_strip_offset : pixel[1] : (display[1] - pixel[1]) + led_strip_offset])
    translate([0, y, 0])
      led_strip(display[0], 30);

  for (x = short_strip_rows) {
      translate([x, stock[2], display[2]])
        rotate([180, 0, 90])
        render(convexity=2)
          short_strip();
  }
  translate([0, stock[2], 0])
    for (y = long_strip_rows) {
      translate([0, y, 0])
        render(convexity=2)
        long_strip();
    }

  short_edge_strip();
    translate([0, display[1] + stock[2], 0])
  short_edge_strip();

  rotate([0,0,90])
  long_edge_strip();
    translate([display[0] + stock[2], 0])
  rotate([0,0,90])
  long_edge_strip();

  color(alpha=0.2)
  cube(display);
  color("green", alpha=0.5)
  translate([-stock[2], 0, display[2]])
    top();
}

module top() {
  cube([display[0] + stock[2] * 2, display[1] + stock[2] * 2, stock[2]]);
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
    cube_with_slots_snap([display[1], stock[2], display[2]], pixel[0], [stock[2], stock[2] * 2, display[2]/2]);
    for (x = [pixel[0] / 2 - led_strip_width/2 + stock[2]/2: pixel[0] : display[1]]) {
      translate([x, -stock[2]/2, display[2]-led_strip_thickness])
        cube([led_strip_width, stock[2] * 2, led_strip_thickness*2]);
    }
  }
}

module long_strip() {
  cube_with_slots_snap([display[0], stock[2], display[2]], pixel[0], [stock[2], stock[2] * 2, display[2]/2]);
}

module short_edge_strip() {
  cube([display[0], stock[2], display[2]]);
}

module long_edge_strip() {
  cube([display[1] + stock[2] * 2, stock[2], display[2]]);
}

module cube_with_slots_snap(cube_size, slot_spacing, slot_size) {
  difference() {
    cube_with_slots(cube_size, slot_spacing, slot_size);
    translate([(cube_size[0]) - (cube_size[0] % slot_spacing), -cube_size[1]/2, -cube_size[2]/2 ])
      cube([slot_spacing + 1, cube_size[1] * 2, cube_size[2] * 2]);
  }
}

module cube_with_slots(cube_size, slot_spacing, slot_size) {
  difference() {
    cube(cube_size);
    for (x = [slot_spacing : slot_spacing : cube_size[0]]) {
      translate([x, -0.5, -1])
        cube(slot_size + [0, 0, 1]);
    }
  }
}
