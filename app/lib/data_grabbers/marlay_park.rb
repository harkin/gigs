module DataGrabbers
  class MarlayPark

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "KovZ9177TJ0", venue: :marlay_park)
    end

  end
end
