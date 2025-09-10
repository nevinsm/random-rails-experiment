class AuditEvent < ApplicationRecord
  belongs_to :organization
  belongs_to :actor, class_name: "User"

  validates :event_type, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true

  scope :for_org, ->(org_id) { where(organization_id: org_id) }
end


