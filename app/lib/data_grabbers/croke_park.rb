module DataGrabbers
  class CrokePark

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "KovZ9177XKV", venue: :croke_park)
    end

  end
end
