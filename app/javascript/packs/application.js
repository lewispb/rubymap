/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

require('./stylesheets/application.scss')
$ = require('jquery')

const loadGoogleMapsApi = require('load-google-maps-api')

function initializeMap() {
  loadGoogleMapsApi({ key: process.env.GOOGLE_MAPS_API_KEY }).then(function (googleMaps) {
    map = new googleMaps.Map(document.querySelector('.map'), {
      center: {
        lat: 40.7484405,
        lng: -73.9944191
      },
      zoom: 8
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
      var myHTML = event.feature.getProperty("description");
      infowindow.setContent("<div style='width:200px;'>"+myHTML+"</div>");
      infowindow.setPosition(event.feature.getGeometry().get());
      infowindow.setOptions({pixelOffset: new google.maps.Size(0,-30)});
      infowindow.open(map);
    });
  }).catch(function (error) {
    console.error(error)
  })
}

$(document).ready(initializeMap);