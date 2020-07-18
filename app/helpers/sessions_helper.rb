module SessionsHelper

  # 渡されたユーザーでログインするヘルパーメソッド
  def log_in(user)
    session[:user_id] = user.id
  end

  # sessionが有効になっているかを確認し、有効になっているユーザー（ログイン状態のユーザー）の値を返すメソッド
  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  # ユーザーがログイン（current_userメソッドの返り値がnilじゃなかったら）していればtrue、その他ならfalseを返す
  def logged_in?
    !current_user.nil?
  end

  # 現在のユーザーをログアウトする
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end
  
end
