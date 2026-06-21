module DataGrabbers
  class IveaghGardens

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "KovZ9177Ty0", venue: :iveagh_gardens)
    end

  end
end
