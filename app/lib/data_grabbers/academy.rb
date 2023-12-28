module DataGrabbers
  class Academy

    EVENTS_URL = "https://www.theacademydublin.com/"

    def self.get_events
      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)
      gigs = document.css("div.month, div.gigbg")
      current_month = gigs.css("span.headingfour").first.text
      events = []
      gigs.each do |gig|
        if gig.css("span.headingfour").present?
          current_month = gig.css("span.headingfour").text
        else
          details = gig.css("div.details").text.split("/")
          date = "#{details[0].strip} #{gig.css("div.date").text} #{current_month}"

          events.push(
            {
              title: gig.css("div.bands").text,
              date: Time.parse(date),
              price: details[2]&.strip,
              tickets_available: gig.css("div.soldout").blank?,
              link_to_buy: gig.css("a").attribute("href")&.value,
            }
          )
        end
      end
      events
    end
  end
end