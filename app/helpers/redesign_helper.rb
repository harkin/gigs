module RedesignHelper
  SOLD_OUT_IN_TITLE = /\s*\(sold out\)\s*/i

  # Two-letter words in an all-caps title are usually initials or acronyms
  # (UK, DJ), except for these.
  SMALL_WORDS = %w[AN AS AT BE BY DO GO HE IN IS IT ME MY NO OF ON OR SO TO UP US WE].to_set.freeze

  STATUS_LABELS = {
    "sold_out" => "Sold out",
    "limited_availability" => "Few left",
  }.freeze

  def display_title(event)
    title_case_shouting(event_title(event).sub(SOLD_OUT_IN_TITLE, " ").strip)
  end

  # Some feeds leave the status unknown but put "(SOLD OUT)" in the title.
  def display_status(event)
    event_title(event).match?(SOLD_OUT_IN_TITLE) ? "sold_out" : event.ticket_status
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

  # Venues format prices every which way ("24.50", "FROM  €14.50", "€15.00").
  # Only the common shapes are tidied; anything else (ranges, "+ bkng fee")
  # passes through as written.
  def display_price(price)
    text = price.to_s.squish
    return if text.empty?

    text = text.sub(/\Afrom /i, "from ")
    text = text.sub(/\A(from )?(\d)/, '\1€\2')
    text.gsub(/(\d)\.00\b/, '\1')
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

  def title_case_shouting(title)
    letters = title.gsub(/[^[:alpha:]]/, "")
    return title if letters.empty? || letters != letters.upcase

    title.split(/(\s+)/).map { |word| keep_as_written?(word) ? word : capitalise_word(word) }.join
  end

  private

  def keep_as_written?(word)
    return true if word.match?(/\d|\./)

    letters = word.gsub(/[^[:alpha:]]/, "")
    letters.length == 2 && !SMALL_WORDS.include?(letters)
  end

  def capitalise_word(word)
    word.downcase.sub(/[[:lower:]]/, &:upcase).gsub(/([-–\/])([[:lower:]])/) { "#{$1}#{$2.upcase}" }
  end
end
