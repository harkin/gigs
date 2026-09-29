module DataGrabbers
  module PriceCleaner
    module_function

    # Venues format prices every which way ("24.50", "FROM  €14.50", "€15.00").
    # Only the common shapes are tidied; anything else (ranges, "+ bkng fee")
    # passes through as written.
    def tidy(price)
      text = price.to_s.squish
      return if text.empty?

      text = text.sub(/\Afrom /i, "from ")
      text = text.sub(/\A(from )?(\d)/, '\1€\2')
      text.gsub(/(\d)\.00\b/, '\1')
    end
  end
end
