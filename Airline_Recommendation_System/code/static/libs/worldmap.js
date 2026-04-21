var city_radius = 2.5;
var route_pt_radius = 5;
var label_left = 10
var label_top = 10

function apply_projection() {
  path = d3.geoPath().projection(projection);
  map.selectAll("path").attr("d", path);

  path1 = d3.geoPath().projection(projection).pointRadius(city_radius);
  cities.selectAll("path").attr("d", path1);

  path3 = d3.geoPath().projection(projection).pointRadius(route_pt_radius);
  routes.selectAll("path").attr("d", path3);

  function refresh_route_label(pt_type) {
    if ( label_pts[pt_type + '_point'] != null && label_pts[pt_type + '_label'] != null) {
        label_pt = label_pts[pt_type + '_point'].node().getBBox()
        label_pts[pt_type + '_label']
            .attr('x', label_pt.x + label_left)
            .attr('y', label_pt.y + label_top)
            ;
    }
  }
  refresh_route_label('starting')
  refresh_route_label('ending')
  refresh_route_label('stop')
}

function rotateMap(endX) {
  projection.rotate([map_rotated + (endX - initX) * 360 / (s * width),0,0]);
  apply_projection();
}

function zoomended(){
  if(s !== 1) return;
  //rotated = rotated + ((d3.mouse(this)[0] - initX) * 360 / (s * width));
  map_rotated = map_rotated + ((mouse[0] - initX) * 360 / (s * width));
  mouseClicked = false;
}

function zoomed() {
  var t = [d3.event.transform.x,d3.event.transform.y];
  s = d3.event.transform.k;
  var h = 0;

  t[0] = Math.min(
    (width/height)  * (s - 1),
    Math.max( width * (1 - s), t[0] )
  );

  t[1] = Math.min(
    h * (s - 1) + h * s,
    Math.max(height  * (1 - s) - h * s, t[1])
  );

  map.attr("transform", "translate(" + t + ")scale(" + s + ")");
  cities.attr("transform", "translate(" + t + ")scale(" + s + ")");
  routes.attr("transform", "translate(" + t + ")scale(" + s + ")");

  //adjust the stroke width based on zoom level
  d3.selectAll(".boundary").style("stroke-width", 1 / s);

  mouse = d3.mouse(this);

  if(s === 1 && mouseClicked) {
    //rotateMap(d3.mouse(this)[0]);
    rotateMap(mouse[0]);
    return;
  }

}
function draw_global_map (error, city_data, world_map) {
  //console.log("flights: ",flights)
  //countries
  map.append("g")
    .attr("class", "boundary")
    .selectAll("boundary")
    .data(topojson.feature(world_map, world_map.objects.countries).features)
    .enter().append("path")
    .attr("d", path);

  //graticule
  let graticule = d3.geoGraticule();
  map.append("g")
    .attr("class", "graticule")
    .selectAll("graticule")
    .data(graticule.lines())
    .enter().append("path")
    .attr("d", path);

  //draw cities
  cities.append('g')
    .attr('class', 'cities')
    .selectAll('path')
    .data(topojson.feature(city_data, city_data.objects.cities).features)
    .enter()
    .append('path')
    .attr('class', 'cities')
    .attr('id', (d) => d.id)
    .attr('d', path)
}

function enableRotation() {
    d3.timer(function (elapsed) {
      sensitivity_fast = 2000;
      const rotate = projection.rotate();
      var sensitivity = sensitivity_slow;

      if (sensitivity_fly != null) {
          sensitivity = sensitivity_fly;
      }
      else if (rotate_center != null) {
          dis = Math.abs(rotate[0] - rotate_center)
          limit = sensitivity_fast * 2 / projection.scale()
          if ( dis < limit  ) {
            return
          }
          //console.log("limit: ",limit);
          sensitivity = sensitivity_fast;
      }

      const k = sensitivity / projection.scale()
      projection.rotate([
        rotate[0] + 1 * k,
        rotate[1]
      ])

      apply_projection();

    },100);
}

// define any other global variables
function load_basemap(files) {
    Promise.all(files).then( ([city_data, world_map]) => {
        // enter code to call ready() with required arguments
        draw_global_map(null, city_data, world_map);
        enableRotation();
   })
}

var route_pts = {starting_point:null, ending_point:null, stop_point:null};
var label_pts = {starting_point:null, ending_point:null, stop_point:null,
                starting_label:null, ending_label:null, stop_label:null};

function reset_route_points(starting_point, ending_point, stop_point) {
  route_pts = {starting_point:starting_point, ending_point:ending_point, stop_point:stop_point};
}

function draw_route_point(pt_type, pt, path3){
    if (pt != null ) {
        map_pt = routes.append('path')
           .datum({type: 'Point', coordinates: pt.geometry.coordinates})
           .attr('class', pt_type + '_point')
           .attr('id', (d) => d.id)
           .attr('d', path3);
        //console.log("node BBox: ", map_pt.node().getBBox())
        label_pt = map_pt.node().getBBox()
        map_label = routes.append("text")
            .attr('class', pt_type + '_label')
            .attr('x', label_pt.x + label_left)
            .attr('y', label_pt.y + label_top)
            .attr('text-anchor','start')
            .text(pt.id);
        label_pts[pt_type + '_point'] = map_pt
        label_pts[pt_type + '_label'] = map_label
    }
}

function draw_route_path(pt1, pt2, path3){
    if ((pt1 != null) && (pt2 != null)) {
        routes.append('path')
           .datum({type: 'LineString', coordinates: [pt1.geometry.coordinates, pt2.geometry.coordinates]})
           .attr('class', 'route')
           .attr('d', path3)
    }
}

function draw_route(){
    label_pts = {starting_point:null, ending_point:null, stop_point:null,
                starting_label:null, ending_label:null, stop_label:null};
    routes.selectAll('path').remove();
    routes.selectAll('text').remove();

    //console.log("route_pts: ",route_pts);

    path3 = d3.geoPath().projection(projection).pointRadius(route_pt_radius);

    draw_route_point('starting', route_pts.starting_point, path3)
    draw_route_point('ending', route_pts.ending_point, path3)
    draw_route_point('stop', route_pts.stop_point, path3)

    if (route_pts.stop_point == null) {
      draw_route_path(route_pts.starting_point, route_pts.ending_point, path3)
      point_pairs = [route_pts.starting_point, route_pts.ending_point]
    } else {
      draw_route_path(route_pts.starting_point, route_pts.stop_point, path3)
      draw_route_path(route_pts.stop_point, route_pts.ending_point, path3)
      point_pairs = [route_pts.starting_point, route_pts.stop_point, route_pts.ending_point]
    }

    show_flights(path3, point_pairs)
}

function rotate_to_city(city_file, class_name, city_name) {
    sensitivity_fly = null;
    d3.json(city_file)
        .then(function(cities) {
        const ftr_cities = topojson.feature(cities, cities.objects.cities).features;

        const pt_cities = ftr_cities.filter(function (d) { return d.id === city_name; });

        if (pt_cities.length > 0) {
            const coor = pt_cities[0].geometry.coordinates;
            route_pts[class_name] = pt_cities[0];
            rotate_center = parseInt(coor[0]) * -1;
            if (rotate_center < 0) { rotate_center = rotate_center + 360;  }
            //console.log("rotate_center: ",rotate_center);
            draw_route();
        }
    });
}

var plane_in_transit = false;

function transition (plane, route) {
    const l = route.node().getTotalLength()
    plane.transition()
        .duration(l * 50)
        .attrTween('transform', delta(plane, route.node()))
        .on('end', () => { route.remove(); })
        .remove()
}

function delta (plane, path) {
    const l = path.getTotalLength()
    return function (i) {
      return function (t) {
        const centre = plane.node().getBBox();
        const p = path.getPointAtLength(t * l)
        const t2 = Math.min(t + 0.05, 1)
        const p2 = path.getPointAtLength(t2 * l)
        const x = p2.x - p.x
        const y = p2.y - p.y
        const r = 90 - Math.atan2(-y, x) * 180 / Math.PI
        const s = Math.min(Math.sin(Math.PI * t) * 0.9, 0.4)
        return 'translate(' + p.x + ',' + p.y + ') scale(' + s + ') rotate(' + r + ", " + (centre.x + centre.width * s * 0.5) + ", " + (centre.y + centre.height * s * 0.4) + ")";
      }
    }
}

function display_flight (pt_coors, path3) {
    //console.log("flight:", origin, destination)

    const route = routes.append('path')
                   .datum({type: 'LineString', coordinates: pt_coors})
                   .attr('class', 'route')
                   .attr('style', 'display:none')
                   .attr('d', path3)

    const plane = routes.append('path')
                  .attr('class', 'plane')
                  .attr('d', 'm25.21488,3.93375c-0.44355,0 -0.84275,0.18332 -1.17933,0.51592c-0.33397,0.33267 -0.61055,0.80884 -0.84275,1.40377c-0.45922,1.18911 -0.74362,2.85964 -0.89755,4.86085c-0.15655,1.99729 -0.18263,4.32223 -0.11741,6.81118c-5.51835,2.26427 -16.7116,6.93857 -17.60916,7.98223c-1.19759,1.38937 -0.81143,2.98095 -0.32874,4.03902l18.39971,-3.74549c0.38616,4.88048 0.94192,9.7138 1.42461,13.50099c-1.80032,0.52703 -5.1609,1.56679 -5.85232,2.21255c-0.95496,0.88711 -0.95496,3.75718 -0.95496,3.75718l7.53,-0.61316c0.17743,1.23545 0.28701,1.95767 0.28701,1.95767l0.01304,0.06557l0.06002,0l0.13829,0l0.0574,0l0.01043,-0.06557c0,0 0.11218,-0.72222 0.28961,-1.95767l7.53164,0.61316c0,0 0,-2.87006 -0.95496,-3.75718c-0.69044,-0.64577 -4.05363,-1.68813 -5.85133,-2.21516c0.48009,-3.77545 1.03061,-8.58921 1.42198,-13.45404l18.18207,3.70115c0.48009,-1.05806 0.86881,-2.64965 -0.32617,-4.03902c-0.88969,-1.03062 -11.81147,-5.60054 -17.39409,-7.89352c0.06524,-2.52287 0.04175,-4.88024 -0.1148,-6.89989l0,-0.00476c-0.15655,-1.99844 -0.44094,-3.6683 -0.90277,-4.8561c-0.22699,-0.59493 -0.50356,-1.07111 -0.83754,-1.40377c-0.33658,-0.3326 -0.73578,-0.51592 -1.18194,-0.51592l0,0l-0.00001,0l0,0z')

    transition(plane, route);
}

var intervalID = null;

function show_flights (path3, flight_pts) {
    //routes = [['AA','BB'],['BB','CC'],['CC','DD'],['DD','EE']]
    if (intervalID != null) {
        clearInterval(intervalID );
        intervalID = null;
    }

    if (flight_pts.length >= 2) {
        planes_take_off();

        intervalID = setInterval(planes_take_off, 6000)
    }

    function planes_take_off () {
      for(let i=1; i<flight_pts.length; i++) {
        if(flight_pts[i-1] && flight_pts[i]) {
            pt_coors = [flight_pts[i-1].geometry.coordinates, flight_pts[i].geometry.coordinates];
            display_flight(pt_coors, path3 )
        }
      }
    }
}
