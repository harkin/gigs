module DataGrabbers
  class StAnnesPark

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "KovZ917AOCi", venue: :st_annes_park)
    end

  end
end
