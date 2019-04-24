require('./stylesheets/application.scss')

var $ = require('jquery')
var loadGoogleMapsApi = require('load-google-maps-api')
var MicroModal = require('micromodal/dist/micromodal')

function initializeMap() {
  loadGoogleMapsApi({ key: process.env.GOOGLE_MAPS_API_KEY }).then(function (googleMaps) {
    map = new googleMaps.Map(document.querySelector('.map'), {
      center: {
        lat: 51.454514,
        lng: -2.587910
      },
      zoom: 6
    })

    var infowindow = new googleMaps.InfoWindow();

    // Try HTML5 geolocation.
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(position) {
        var pos = {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        };
        map.setCenter(pos);
      }, function(e) {
        console.log(e);
      });
    } else {
      // Browser doesn't support Geolocation
    }

    map.data.loadGeoJson("locations.json");
    map.data.addListener("click", function(event) {
      var descriptionHtml = event.feature.getProperty("description");
      infowindow.setContent(descriptionHtml);
      infowindow.setPosition(event.feature.getGeometry().get());
      infowindow.setOptions({pixelOffset: new google.maps.Size(0,-30)});
      infowindow.open(map);
    });
  }).catch(function (error) {
    console.error(error)
  })
}

$(document).ready(initializeMap);
$(document).ready(function() {
  MicroModal.init();
});
