module DataGrabbers
  class Pavilion

    def self.get_events
      Ticketsolve.get_events(subdomain: "paviliontheatre", venue: :pavilion)
    end

  end
end
