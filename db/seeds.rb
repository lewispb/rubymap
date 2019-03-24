Location.destroy_all
Organization.destroy_all

Seeds::Organization.all.each(&:import)