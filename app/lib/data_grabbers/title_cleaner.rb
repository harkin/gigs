module DataGrabbers
  module TitleCleaner
    module_function

    # Titles are often "<Promoter> presents <Artist>"; drop the promoter so only
    # the act remains. Titles without that lead-in are left as-is.
    def strip_promoter(title)
      title.sub(/\A.*?\bpres(?:ents?)?\b:?\s+/i, "")
    end

  end
end
