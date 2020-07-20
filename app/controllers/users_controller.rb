class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # メールでの認証確認をする以前は下記の処理だった（saveメソッドがtrueだったら、ログインをさせてメッセージを表示させる）
      # log_in @user
      # flash[:success] = "Welcome to the Sample App!"
      # redirect_to @user

      # メールでの認証を経てからログインさせるコードは以下（send_activation_emailメソッドを使ってメールを送信している）
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password,
                                 :password_confirmation)
  end

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

  # 正しいユーザーかどうか確認
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user? @user
  end

  # 管理者かどうか確認
  def admin_user
    redirect_to(root_url) unless current_user.admin?
  end

end
