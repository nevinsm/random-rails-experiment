class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :owned_organizations, class_name: "Organization", foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships

  def has_permission?(key, organization:)
    return false if key.blank? || organization.nil?

    # Owners have full permissions within their organizations
    return true if organization.owner_id == id

    membership = memberships.find_by(organization_id: organization.id)
    return false unless membership

    Role
      .joins(:permissions, :membership_roles)
      .where(membership_roles: { membership_id: membership.id })
      .where(permissions: { key: key })
      .exists?
  end

  # Be tolerant to varying session serialization shapes across middleware stacks
  def self.serialize_into_session(record)
    [record.id, (record.respond_to?(:authenticatable_salt) ? record.authenticatable_salt : nil)]
  end

  def self.serialize_from_session(*args)
    Rails.logger.warn("serialize_from_session args_len=#{args.length} args=#{args.inspect}") if Rails.env.test?
    # Case 1: Devise passes id and optional salt
    if args.length <= 2 && !(args.first.is_a?(Array))
      id = args[0]
      salt = args[1]
      user = find_by(id: id)
      return nil unless user
      return user if salt.nil? || !user.respond_to?(:authenticatable_salt) || user.authenticatable_salt == salt
      return nil
    end

    # Case 2: Warden/Devise passed a list of key/value pairs like [ ["id", 1], ["email", ...], ... ]
    if args.all? { |arg| arg.is_a?(Array) && arg.size == 2 }
      attr_hash = args.to_h
      id = attr_hash["id"] || attr_hash[:id]
      return find_by(id: id)
    end

    nil
  end

end
