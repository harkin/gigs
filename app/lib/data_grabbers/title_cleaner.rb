module DataGrabbers
  module TitleCleaner
    module_function

    SOLD_OUT = /\s*\(sold out\)\s*/i

    # Two-letter words in an all-caps title are usually initials or acronyms
    # (UK, DJ), except for these.
    SMALL_WORDS = %w[AN AS AT BE BY DO GO HE IN IS IT ME MY NO OF ON OR SO TO UP US WE].to_set.freeze

    # Titles are often "<Promoter> presents <Artist>"; drop the promoter so only
    # the act remains. Titles without that lead-in are left as-is.
    def strip_promoter(title)
      title.sub(/\A.*?\bpres(?:ents?)?\b:?\s+/i, "")
    end

    # Some feeds ship entity-encoded titles ("Bluey&#8217;s Big Play"), others
    # plain text. Parsing normalises both to plain text, dropping any markup.
    def text(title)
      Nokogiri::HTML.fragment(title.to_s).text
    end

    # Some feeds leave the status unknown but put "(SOLD OUT)" in the title.
    def sold_out?(text)
      text.match?(SOLD_OUT)
    end

    def tidy(text)
      title_case_shouting(text.sub(SOLD_OUT, " ").squish)
    end

    def clean(title)
      tidy(text(title))
    end

    def title_case_shouting(title)
      letters = title.gsub(/[^[:alpha:]]/, "")
      return title if letters.empty? || letters != letters.upcase

      title.split(/(\s+)/).map { |word| keep_as_written?(word) ? word : capitalise_word(word) }.join
    end

    def keep_as_written?(word)
      return true if word.match?(/\d|\./)

      letters = word.gsub(/[^[:alpha:]]/, "")
      letters.length == 2 && !SMALL_WORDS.include?(letters)
    end

    def capitalise_word(word)
      word.downcase.sub(/[[:lower:]]/, &:upcase).gsub(/([-–\/])([[:lower:]])/) { "#{$1}#{$2.upcase}" }
    end
  end
end
