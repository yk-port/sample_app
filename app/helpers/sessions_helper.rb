module SessionsHelper

  # 渡されたユーザーでログインするヘルパーメソッド
  def log_in(user)
    session[:user_id] = user.id
  end

  # sessionが有効になっているかを確認し、有効になっているユーザー（ログイン状態のユーザー）の値を返すメソッド
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user&.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end 
    end
  end

  # 渡されたユーザーがカレントユーザーであればtrueを返す
  def current_user?(user)
    user && user == current_user
  end

  # ユーザーがログイン（current_userメソッドの返り値がnilじゃなかったら）していればtrue、その他ならfalseを返す
  def logged_in?
    !current_user.nil?
  end

  # 現在のユーザーをログアウトする
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  # ユーザーのセッションを永続的に保持するためにブラウザのcookiesとDBのremember_digestに情報を記憶させる
  def remember(user)
    # rememberメソッド…ランダムな文字列でrememberトークンが作られ、その値をハッシュ化し、DBのremember_digestに保存されるメソッド
    user.remember
    # cookiesに暗号化したuser_idとremember_tokenの値を書き込む ※signedメソッドは数字を暗号化するためのメソッド
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # 永続的セッションを破棄する
  def forget(user)
    # forgetメソッド…remember_digestの値をnilにするメソッド
    user.forget
    # ブラウザのcookiesの中身を削除する処理
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # 記憶したURL（もしくはデフォルト値）にリダイレクト
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # アクセスしようとしたURLを覚えておく
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end
