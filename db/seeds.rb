Location.destroy_all

Seeds::Organization.all.each(&:import)