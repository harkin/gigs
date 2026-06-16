module DataGrabbers
  class Helix

    def self.get_events
      WixEvents.get_events(host: "www.thehelix.ie", venue: :helix)
    end

  end
end
