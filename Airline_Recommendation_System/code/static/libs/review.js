 // You will need to replace the data loading logic with backend calls

function load_review_city_options(city_file) {
    // Load cities data from cities.json or any applicable database
  d3.json(city_file).then( function(city_data) {
    loadDropdownOptions("#rv_departureCity", city_data.objects.cities.geometries);
    loadDropdownOptions("#rv_arrivalCity", city_data.objects.cities.geometries);
  });

  d3.json('/Airlines?').then( function(airlines) {
      //console.log("airlines: ", airlines);

      var selector = d3.select("#rv_airline")
      var opts = selector.selectAll('option')
        .data(airlines)
        .enter()
        .append('option')
        .attr('value', function (d) {
          return d.id
        })
        .text(function (d) {
          return d.Airline
        });
  });

}

// Load options for dropdowns
function loadDropdownOptions(elementId, city_data) {
  //console.log("data: ", data)
  var selector = d3.select(elementId)
  var opts = selector.selectAll('option')
    .data(city_data)
    .enter()
    .append('option')
    .attr('value', function (d) {
      return d.id
    })
    .text(function (d) {
      return d.id
    });
}

// Function to handle submission of the review
function submitReview() {
  const reviewTextArea = document.getElementById("reviewTextArea");
  const reviewText = reviewTextArea.value;

  // Validate the review length
  if (reviewText.length <= 1000) {
    // Process the review (can send it to the backend here)
    console.log("Review submitted:", reviewText);
    alert("Review submitted! Thank you!");
  } else {
    alert("Review should be within 1000 characters.");
  }
}