class AuditLogger
  def self.log(event_type:, resource:, organization: nil, actor: nil, metadata: {})
    organization ||= Current.organization
    actor ||= Current.user

    return unless organization && actor

    AuditEvent.create!(
      organization: organization,
      actor: actor,
      event_type: event_type,
      resource_type: resource.class.name,
      resource_id: resource.id,
      metadata: normalize_metadata(metadata)
    )
  end

  def self.normalize_metadata(metadata)
    allowed_keys = %i[before after reason ip]
    metadata.symbolize_keys.slice(*allowed_keys)
  end
end


