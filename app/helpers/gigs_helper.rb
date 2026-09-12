module GigsHelper
  THEMES = %w[light dark festival aurora].freeze

  # Some venue feeds ship entity-encoded titles ("Bluey&#8217;s Big Play"),
  # others plain text. Parsing normalises both to text so ERB escapes exactly
  # once on output; stray markup in a scraped title is dropped along the way.
  def event_title(event)
    Nokogiri::HTML.fragment(event.title.to_s).text
  end

  # Links come from scraped pages, so only hand the browser a scheme it is
  # safe to follow; anything else (javascript:, data:) is dropped.
  def external_url(url)
    url if url.to_s.match?(%r{\Ahttps?://}i)
  end

  def status_class_for(event)
    case event.ticket_status
    when "available" then "status-available"
    when "limited_availability" then "status-limited"
    when "sold_out" then "status-sold-out"
    else "status-unknown"
    end
  end

  def status_color_for(event)
    case event.ticket_status
    when "available" then "#22c55e"
    when "limited_availability" then "#f59e0b"
    when "sold_out" then "#ef4444"
    else "#9ca3af"
    end
  end
end
