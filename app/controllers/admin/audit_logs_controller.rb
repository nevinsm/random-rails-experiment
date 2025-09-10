class Admin::AuditLogsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :audit, policy_class: AuditPolicy

    events = AuditEvent.for_org(Current.organization.id).order(created_at: :desc)

    # Filters
    if params[:actor_id].present?
      events = events.where(actor_id: params[:actor_id])
    end
    if params[:event_type].present?
      events = events.where(event_type: params[:event_type])
    end
    if params[:resource_type].present?
      events = events.where(resource_type: params[:resource_type])
    end
    if params[:resource_id].present?
      events = events.where(resource_id: params[:resource_id])
    end
    if params[:from].present?
      events = events.where("created_at >= ?", Time.zone.parse(params[:from]).beginning_of_day)
    end
    if params[:to].present?
      events = events.where("created_at <= ?", Time.zone.parse(params[:to]).end_of_day)
    end

    @events = events.includes(:actor).limit(500)
  end
end


