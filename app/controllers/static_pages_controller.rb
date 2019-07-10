class StaticPagesController < ApplicationController
  def home
    return unless logged_in?
    @micropost  = current_user.microposts.build
    @feed_items = current_user.feed.page(params[:page]).per Settings.posts_per_page
  end

  def help; end

  def contact; end

  def about; end
end
