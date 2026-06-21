module DataGrabbers
  class AvivaStadium

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "KovZ9177Tn7", venue: :aviva_stadium)
    end

  end
end
