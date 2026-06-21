module DataGrabbers
  class RoyalHospitalKilmainham

    def self.get_events
      TicketmasterDiscovery.get_events(venue_id: "Z7r9jZaenR", venue: :royal_hospital_kilmainham)
    end

  end
end
