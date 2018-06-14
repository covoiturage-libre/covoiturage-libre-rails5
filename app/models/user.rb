class User < ApplicationRecord
  include Omniauthable

  ROLES = %w(admin).freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login)).present?
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:reset_password_token)
      where(reset_password_token: conditions[:reset_password_token]).first
    else
      unless conditions.is_a? ActiveSupport::HashWithIndifferentAccess or conditions.is_a? Hash
        conditions.permit!
      end
      where(conditions).first
    end
  end

  def admin?
    role == 'admin'
  end

end
