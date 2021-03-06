require 'spec_helper'

describe LogWorker do

  let(:user)          { create :user, :uid => '76561197960497430' }
  let(:reservation)   { create :reservation, :user => user, :logsecret => '1234567' }
  let(:server)        { create :server }
  let(:extend_line)   { '1234567L 03/29/2014 - 13:15:53: "Arie - serveme.tf<3><STEAM_0:0:115851><Red>" say "!extend"' }
  let(:troll_line)    { '1234567L 03/29/2014 - 13:15:53: "TRoll<3><STEAM_0:0:12345><Red>" say "!end"' }
  let(:end_line)      { '1234567L 03/29/2014 - 13:15:53: "Arie - serveme.tf<3><STEAM_0:0:115851><Red>" say "!end"' }
  subject(:logworker) { LogWorker.perform_async(line) }

  before do
    Rails.cache.clear
    Reservation.should_receive(:includes).with(:user).and_return { Reservation }
    Reservation.should_receive(:find).with(reservation.id).and_return { reservation }
    reservation.stub(:server => server)
  end

  describe "ending reservation" do

    it "triggers the end worker" do
      server.should_receive(:rcon_say)
      ReservationWorker.should_receive(:perform_async).with(reservation.id, "end")
      LogWorker.perform_async(end_line)
    end

    it "doesn't trigger when someone else tries to end" do
      server.should_not_receive(:rcon_say)
      ReservationWorker.should_not_receive(:perform_async).with(reservation.id, "end")
      LogWorker.perform_async(troll_line)
    end

  end

  describe "extending reservation" do

    it "triggers extension directly and notifies the server" do
      reservation.should_receive(:extend!).and_return { true }
      server.should_receive(:rcon_say)
      LogWorker.perform_async(extend_line)
    end

    it "notifies when extension wasn't possible" do
      reservation.should_receive(:extend!).and_return { false }
      server.should_receive(:rcon_say).with("Couldn't extend your reservation: you can only extend when there's less than 1 hour left and no one else has booked the server.")
      LogWorker.perform_async(extend_line)
    end

  end

end
