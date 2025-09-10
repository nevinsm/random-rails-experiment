class Api::V1::BaseController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  include SetsCurrentOrganization

  before_action :authenticate_user!
  before_action :set_current_user
  skip_before_action :set_current_organization
  before_action :set_api_current_organization

  # Use cookie session + CSRF, but skip for JSON requests to simplify API clients
  protect_from_forgery with: :exception
  skip_forgery_protection if: -> { request.format.json? }

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def set_current_user
    Current.user = current_user
    PaperTrail.request.whodunnit = current_user&.id&.to_s
  end

  def render_forbidden
    render json: { error: "forbidden" }, status: :forbidden
  end

  def paginate(scope)
    page = params[:page].to_i
    page = 1 if page <= 0
    per = params[:per].to_i
    per = 25 if per <= 0 || per > 100
    scope.offset((page - 1) * per).limit(per)
  end

  def pagination_meta(total:, page:, per:)
    { page: page, per: per, total: total }
  end

  def set_api_current_organization
    return unless current_user

    organization = find_organization_from_params || find_organization_from_user
    ensure_membership!(current_user, organization) if organization
    Current.organization = organization
  end
end


