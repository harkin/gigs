module DataGrabbers
  class GrandSocial

    def self.get_events
      WixEvents.get_events(host: "www.thegrandsocial.ie", venue: :grand_social)
    end

  end
end
