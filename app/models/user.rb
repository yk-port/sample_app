class User < ApplicationRecord
  attr_accessor :remember_token, 
                :activation_token,
                :reset_token
  before_save :downcase_email
  # 下記のようにブロック付きメソッドで記述することも可能だが、通常は上記のようにメソッドにして呼び出す方法が主流
  # before_save { self.email = self.email.downcase }
  before_create :create_activation_digest

  # association
  has_many :microposts, dependent: :destroy
  has_many :active_relationships,  class_name: 'Relationship',
                                  foreign_key: 'follower_id', 
                                    dependent: :destroy
  has_many :passive_relationships, class_name: 'Relationship',
                                  foreign_key: 'followed_id',
                                    dependent: :destroy
  has_many :following,                through: :active_relationships,
                                       source: :followed
  has_many :followers,                through: :passive_relationships,
                                       source: :follower

  validates :name, presence: true,
                   length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  
  has_secure_password
  validates :password, presence: true,
                       length: { minimum: 6 },
                       allow_nil: true

  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す（cookiesに保存するためのトークン）
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためにrememberトークンをハッシュ化し、その値をデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    self.update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す。
  def authenticated?(attribute, token)
    # remember_digestやactivation_digestの値は、第一引数のattributeで受け取った引数をベースに動的に作成する
    digest = self.send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    self.update_attribute(:remember_digest, nil)
  end

  # アカウントを有効にする（activatedとactivated_atのカラムを変更する）
  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

  # 有効化用のメールを送信する
  # UserMailerクラスのaccount_activationメソッドの返り値に対して、メールを送信する指示にあたるdeliver_nowメソッドを当てている
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # パスワード再設定用のdigestとreset_sent_atの値を更新するメソッド
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,   User.digest(reset_token))
    update_attribute(:reset_sent_at,  Time.zone.now)
  end
  
  # 再設定用のメールを送信する
  # UserMailerクラスのpassword_resetメソッドの返り値に対して、メールを送信する指示にあたるdeliver_nowメソッドを当てている
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # パスワード再設定の期限が切れている場合はtrueを返す
  def password_reset_expired?
    self.reset_sent_at < 2.hours.ago
  end

  # ユーザーのステータスフィードを返す
  def feed
    following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: self.id)
  end

  # ユーザーをフォローする
  def follow(other_user)
    following << other_user
  end

  # ユーザーをフォロー解除する
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end


  private

  # メールアドレスをすべて小文字にする
  def downcase_email
    self.email = self.email.downcase
  end

  # 有効化トークンとダイジェストを作成および代入する
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
