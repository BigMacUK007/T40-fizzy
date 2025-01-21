class Notifications::MarkAllReadsController < ApplicationController
  def create
    Current.user.notifications.unread.read_all
  end
end
