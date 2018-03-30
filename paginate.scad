/**
 * Paginates any children by slicing them up onto multiple pages.
 *
 * bounds: the bounding box of the children (as OpenSCAD doesn't support
 *         computing that trivially as of this writing)
 * page: 3D bounds of the page
 * snap: interval at which the object can be cut to fit onto pages ([0,0,0] disables)
 * first_page_offset: extra offset when snapping
 * spacing: how far apart the pages will be spaced
 *
 * To aid design of certain types of parametric designs, this can optionally snap
 * page cuts to a grid so that the paged objects can be pieced back together
 * most effectively (along natural boundaries). There is a first_page_offset to
 * allow for putting slightly more material on the first page (if you've got an
 * outer perimeter or something like that).
 *
 * This was designed to make it easier to lasercut large grids, so it only
 * supports pagination of 3D objects in a 2D plane.
 */
module paginate(bounds, page, snap=[0,0,0], first_page_offset=[0, 0, 0], spacing=[10,10,10]) {
  page_offset = page - first_page_offset * 2;
  crop = [bounds[0] > page_offset[0] ? (page_offset[0] - (page_offset[0] % snap[0])) : page[0],
          bounds[1] > page_offset[1] ? (page_offset[1] - (page_offset[1] % snap[1])) : page[1],
          page[2]];

  page_bounds = bounds - first_page_offset * 2;

  pages = [
           max(1, ceil(page_bounds[0]/crop[0])),
           max(1, ceil(page_bounds[1]/crop[1])),
           1 /* only 2D paging for now */
           ];

    echo("Crop: ", crop);
    echo("Pages: ", pages);
    for (page_y = [ 0 : 1 : pages[1] - 1] ) {
      for (page_x = [ 0 : 1 : pages[0] - 1] ) {
        page_offset_x = page_x * crop[0];
        page_offset_y = page_y * crop[1];

        translate([
          spacing[0]  + (spacing[0] + page[0]) * page_x,
          spacing[1]  + (spacing[1] + page[1]) * page_y,
          0
        ]) {
          translate([-page_offset_x, -page_offset_y, 0])
          intersection() {
            translate([page_offset_x, page_offset_y, 0])
              cube(crop + [
                  page_x == 0 ? first_page_offset[0] : 0,
                  page_y == 0 ? first_page_offset[1] : 0,
                  0
                ] + [
                  page_x >= (pages[0] - 1) ? page[0] - crop[0] : 0,
                  page_y >= (pages[1] - 1) ? page[1] - crop[1] : 0,
                  0
                ]);
              translate([
                page_x > 0 ? -first_page_offset[0] : 0,
                page_y > 0 ? -first_page_offset[1] : 0,
                0])
                render()
                  children();
          }

%       translate([0, 0, -page[2] - 0.1])
          color("red", alpha=0.2)
            cube(page);
        }
      }
    }
}


