require 'socket'

unless Socket.respond_to? :hostname
  # :nodoc: Monkey-patch Socket to add hostname method for old Rubies.
  def Socket.hostname
    @__hostname ||= `hostname`.strip
  end
end
