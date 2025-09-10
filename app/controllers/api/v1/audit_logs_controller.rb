class Api::V1::AuditLogsController < Api::V1::BaseController
  def index
    authorize :audit, policy_class: AuditPolicy

    events = AuditEvent.for_org(Current.organization.id).order(created_at: :desc)
    events = events.where(actor_id: params[:actor_id]) if params[:actor_id].present?
    events = events.where(event_type: params[:event_type]) if params[:event_type].present?
    events = events.where(resource_type: params[:resource_type]) if params[:resource_type].present?
    events = events.where(resource_id: params[:resource_id]) if params[:resource_id].present?
    if params[:from].present?
      events = events.where("created_at >= ?", Time.zone.parse(params[:from]).beginning_of_day)
    end
    if params[:to].present?
      events = events.where("created_at <= ?", Time.zone.parse(params[:to]).end_of_day)
    end

    total = events.count
    events = paginate(events.includes(:actor))

    render json: {
      events: events.map { |e| serialize_event(e) },
      meta: pagination_meta(total: total, page: (params[:page] || 1).to_i, per: ((params[:per] || 25).to_i.clamp(1, 100)))
    }
  end

  private

  def serialize_event(event)
    {
      id: event.id,
      event_type: event.event_type,
      actor_id: event.actor_id,
      resource_type: event.resource_type,
      resource_id: event.resource_id,
      created_at: event.created_at.iso8601
    }
  end
end


