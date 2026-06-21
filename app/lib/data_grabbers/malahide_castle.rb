module DataGrabbers
  class MalahideCastle

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "KovZ9177Xt7", venue: :malahide_castle)
    end

  end
end
