module DataGrabbers
  class NationalStadium

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "KovZ9177TZf", venue: :national_stadium)
    end

  end
end
