class Refresh

  def self.refresh_events
    ::DataGrabbers::Olympia.get_events
    ::DataGrabbers::Academy.get_events
    ::DataGrabbers::Point.get_events
  end
end