class LocationsController < ApplicationController
  def index
    @locations = Location.includes(:organization).all
  end
end
