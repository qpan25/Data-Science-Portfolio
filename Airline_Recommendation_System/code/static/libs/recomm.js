// You will need to replace the data loading logic with backend calls

// Load options for dropdowns
function loadDropdownOptions(elementId, data) {
  d3.select(`#${elementId}`)
    .selectAll("option")
    .data(data)
    .enter()
    .append("option")
    .text(d => d)
    .attr("value", d => d);
}
// Function to handle submission
function DoItAgain() {
  d3.select("#recomm_param").style("display", 'block');
  d3.select("#recomm_result").style("display", 'none');
}

function encodeQueryData(data) {
   const ret = [];
   for (let d in data)
     ret.push(encodeURIComponent(d) + '=' + encodeURIComponent(data[d]));
   return ret.join('&');
}

// Function to handle submission
function submitSelections() {
  // Gather user selections
  const departureCity = d3.select("#departureCity").node().value;
  if (departureCity == '') {
    alert("Please select your departure city!");
    return;
  }
  const arrivalCity = d3.select("#arrivalCity").node().value;
  if (arrivalCity == '') {
    alert("Please select your arrival city!");
    return;
  }
  const stopCity = d3.select("#stopCity").node().value;
  const preferredAircraft = d3.select("#preferredAircraft").node().value;
  const cabinService = d3.select("#cabinService").node().value;
  const food = d3.select("#food").node().value;
  const seatComfort = d3.select("#seatComfort").node().value;
  const entertainment = d3.select("#entertainment").node().value;
  const groundService = d3.select("#groundService").node().value;
  const wifi = d3.select("#wifi").node().value;

  // Simulate backend logic (replace this with actual backend communication)
  //simulateBackend(formData);
  d3.select("#wait_recomm").style("display", 'block');
  d3.select("#show_recomm").style("display", 'none');

  d3.select("#recomm_param").style("display", 'none');
  d3.select("#recomm_result").style("display", 'block');

  const data = { 'start_city': departureCity, 'end_city': arrivalCity, 'Stops': stopCity,
                 'Aircraft': preferredAircraft, 'ServiceRating': cabinService, 'FoodRating':food ,
                  'SeatComfortRating': seatComfort, 'EntertainmentRating': entertainment,
                  'GroundServiceRating': groundService,'WifiRating': wifi};
  const querystring = encodeQueryData(data);
 // console.log("querystring: ", querystring);

  d3.json('/Recomm?' + querystring, function(d) {
      return {
        airline: d.airline,
        matchingRate: +d.matchingRate
        }
    }).then( function(airlineData) {
    show_recomm(airlineData)
  });

}

function show_recomm(backendData) {
    d3.select("#wait_recomm").style("display", 'none');
    d3.select("#show_recomm").style("display", 'block');

    // Sort data by matching rate in descending order
    const sortedData = backendData.sort((a, b) => b.matchingRate - a.matchingRate);

    // Display gauge charts
    const gaugeChartsContainer = d3.select("#gaugeCharts");
    gaugeChartsContainer.selectAll("div").remove();
    sortedData.forEach((d, index) => {
        const gaugeContainer = gaugeChartsContainer.append("div")
            .attr("class", "gauge-chart")
            .attr("id", `gaugeChart${index}`);

        gaugeContainer.append("div")
            .style("text-align", "center")
            .style("font-size", "20px")
            .style("margin-bottom", "5px")
            .html( d.airline + ': <a href="javascript:show_output(' + "'" + d.airline + "'" + ')">Details</a>' );

            //.html(`${d.airline}: <a href="${getAirlineLink(d.airline)}" target="_blank">Detail</a>`);

        createGaugeChart(gaugeContainer.node(), d.matchingRate, 0, 100, index);
    });
}

// Function to create a gauge chart
function createGaugeChart(g_container, value, min, max, index) {
    // Define the size and scale of the chart
    const width = 100;
    const height = 100;
    const radius = Math.min(width, height) / 2;

    // Different colors for each gauge
    const colors = ["#161A40", "#3D5A92", "#A1BAEE"];
    const color = d3.scaleLinear()
        .domain([min, max])
        .range([colors[index], colors[index]]);

    // Create an arc function
    const arc = d3.arc()
        .innerRadius(radius - 20)
        .outerRadius(radius)
        .startAngle(-Math.PI / 2);

    // Create the SVG element
    const svg = d3.select(g_container)
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

    // Add the background arc
    svg.append("path")
        .datum({ endAngle: Math.PI / 2 })
        .style("fill", "white")
        .attr("d", arc);

    // Add the foreground arc
    svg.append("path")
        .datum({ endAngle: value / max * Math.PI - Math.PI / 2 })
        .style("fill", color(value))
        .attr("d", arc);

    // Add the value text in the center
    svg.append("text")
        .attr("text-anchor", "middle")
        .attr("dy", "0.4em")
        .style("font-size", "15px")
        .text(`${value}%`);
}

function show_output (airline_name) {
  const data = { 'airline': airline_name};
  const querystring = encodeQueryData(data);
  ss = '<object type="text/html" data="/airline?' + querystring + '" width=100% height=100% ></object>';
  document.getElementById("output").innerHTML=ss;
  d3.select("#output").style("display", 'block')
}
