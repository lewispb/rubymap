class LocationsController < ApplicationController
  def index
    @locations = Location.eager_load(:organization).order("organizations.name")
  end
end
