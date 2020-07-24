class ApplicationController < ActionController::Base
  include SessionsHelper

  private

  # ログイン済みユーザーかどうか確認
  def logged_in_user
    # もしログインしていなかったら
    unless logged_in?
      # 現在のURL（どこにもともとアクセスしたか）をsessionに一時保有するメソッド
      store_location
      flash[:danger] = "Please log in."
      redirect_to login_path
    end
  end
end
