class ReservationWorker
  include Sidekiq::Worker

  sidekiq_options :retry => false

  attr_accessor :reservation

  def perform(reservation_id, action)
    begin
      @reservation = Reservation.find(reservation_id)
      server = reservation.server
      server.send("#{action}_reservation", reservation)
    rescue Exception => exception
      Rails.logger.error "Something went wrong #{action}-ing the server for reservation #{reservation_id} - #{exception}"
      Raven.capture_exception(exception) if Rails.env.production?
    ensure
      send("after_#{action}_reservation_steps") if reservation
      Rails.logger.info "#{action.capitalize}ed reservation: #{reservation_id} #{reservation}"
    end
  end

  def after_start_reservation_steps
    reservation.provisioned = true
    reservation.save(:validate => false)
  end

  def after_update_reservation_steps
    reservation.inactive_minute_counter = 0
    reservation.save(:validate => false)
  end

  def after_end_reservation_steps
    reservation.ends_at  = Time.current
    reservation.ended    = true
    reservation.duration = reservation.ends_at.to_i - reservation.starts_at.to_i
    reservation.save(:validate => false)
  end

end
