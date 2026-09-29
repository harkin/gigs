module GigsHelper
  STATUS_LABELS = {
    "sold_out" => "Sold out",
    "limited_availability" => "Few left"
  }.freeze

  # Links come from scraped pages, so only hand the browser a scheme it is
  # safe to follow; anything else (javascript:, data:) is dropped.
  def external_url(url)
    url if url.to_s.match?(%r{\Ahttps?://}i)
  end

  def status_label(status)
    STATUS_LABELS[status]
  end

  # Feeds without a start time store midnight.
  def display_time(event)
    return if event.multi_day?

    time = event.event_date.strftime("%H:%M")
    time unless time == "00:00"
  end

  def event_link(event)
    external_url(event.link_to_buy_ticket) || external_url(event.more_info)
  end

  def day_relative_label(date)
    if date == Date.current
      "Tonight"
    elsif date == Date.current.tomorrow
      "Tomorrow"
    end
  end
end
