class User < ApplicationRecord
  VALID_EMAIL_REGEX = Settings.email_regex

  has_many :microposts, dependent: :destroy

  attr_accessor :remember_token, :activation_token, :reset_token

  before_save {email.downcase!}
  before_create :create_activation_digest
  scope :activated, -> { where activated: true }

  validates :name, presence: true, length: { maximum: Settings.name_length }
  validates :email, presence: true, length: { maximum: Settings.email_length }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: Settings.pass_min_length }

  has_secure_password

  def password_reset_expired?
    reset_sent_time < Settings.expired_time.hours.ago
  end

  def active
    update activated: true, activated_at: Time.zone.now
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def remember
    self.remember_token = User.new_token
    update remember_digest: User.digest(remember_token)
  end

  def authenticated? attribute, token
    digest = self.send("#{attribute}_digest")
    return false unless digest.present?
    BCrypt::Password.new(digest).is_password? token
  end

  def forget
    update remember_digest: nil
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update reset_digest: User.digest(reset_token), reset_sent_time: Time.zone.now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def feed
    microposts
  end

  class << self
    def digest string
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
      BCrypt::Password.create string, cost: cost
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  private
    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest activation_token
    end
end
