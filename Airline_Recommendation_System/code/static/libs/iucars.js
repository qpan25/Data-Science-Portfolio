
function switch2menu (menu_name) {
  d3.select("#output").style("display", 'none')
  //d3.select("#output").style("display", 'block')

  d3.select("#recomm_param").style("display", menu_name == "home" ? 'block':'none')
  d3.select("#recomm_result").style("display", 'none')

  d3.select("#review_input").style("display", menu_name == "review" ? 'block':'none')
}

function init_model_dialog() {
// Get the modal
var modal = document.getElementById("myModal");

// Get the <span> element that closes the modal
var span = document.getElementsByClassName("close")[0];

// When the user clicks on <span> (x), close the modal
span.onclick = function() {
  modal.style.display = "none";
}

// When the user clicks anywhere outside of the modal, close it
window.onclick = function(event) {
  if (event.target == modal) {
    modal.style.display = "none";
  }
}
}
function let_me_fly () {
    const reviewList = document.getElementById('reviewList');
    const reviews = reviewList.querySelectorAll('li');
    let currentReviewIndex = 0;
    function fadeInOut() {
        reviews[currentReviewIndex].classList.remove('active');
        currentReviewIndex = (currentReviewIndex + 1) % reviews.length;
        reviews[currentReviewIndex].classList.add('active');
        setTimeout(fadeInOut, 2000);
    }
    fadeInOut();
}
function show_me_the_work () {
    sensitivity_fly = null;
    sensitivity = 20;
    var plane = document.getElementById("airplane");
    plane.style.display = "none";
    var modal = document.getElementById("myModal");
    modal.style.display = "block";
}

function update_city_lists(departureCity, arrivalCity) {
  if (departureCity != null && arrivalCity != null) {
      const data = { 'start_city': departureCity, 'end_city': arrivalCity};
      const querystring = encodeQueryData(data);

      d3.json('/StopCities?' + querystring)
      .then( function(list_cities) {
        ss = '<option value="" selected>None Stops</option>'
        list_cities.forEach((ct) => {
          ss += '<option value="'+ ct.Stops + '" >' + ct.Stops + '</option>'
          });
        document.getElementById("stopCity").innerHTML=ss;
      });
  } else if (departureCity != null) {
      const data = { 'start_city': departureCity, 'end_city': arrivalCity};
      const querystring = encodeQueryData(data);

      d3.json('/ArrivalCities?' + querystring)
      .then( function(list_cities) {
        ss = '<option value="" disabled selected>Select Arrival City</option>'
        list_cities.forEach((ct) => {
          ss += '<option value="'+ ct.end_city + '" >' + ct.end_city + '</option>'
          });

        document.getElementById("arrivalCity").innerHTML=ss;

        ss = '<option value="" disabled selected>Select Stop City</option>'
        document.getElementById("stopCity").innerHTML=ss;
      });
  }

}

