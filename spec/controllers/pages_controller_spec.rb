require 'spec_helper'

describe PagesController do

  describe "#recent_reservations" do
    it "should assign the recent reservations variable" do
      reservation = create :reservation
      get :recent_reservations
      assigns(:recent_reservations).should include(reservation)
    end
  end

  describe '#statistics' do
    it "should assign the top 10 hash" do
      Statistic.should_receive(:top_10_users).and_return(:foo)
      Statistic.should_receive(:top_10_servers).and_return(:bar)
      get :statistics
      assigns(:top_10_users_hash).should eql(:foo)
      assigns(:top_10_servers_hash).should eql(:bar)
    end
  end

  describe "#switch_theme" do

    it "toggles between themes by setting a cookie" do
      get :switch_theme
      cookies[:theme].should == "black"
      get :switch_theme
      cookies[:theme].should == "white"
    end

  end

  describe '#not_found' do

    it "should show the not found page" do
      get :not_found
      response.should render_template("pages/not_found")
      response.status.should == 404
    end

  end


  describe '#error' do
    it "should show the error page" do
      get :error
      response.should render_template("pages/error")
      response.status.should == 500
    end

  end

end
