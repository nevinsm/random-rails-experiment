class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization
  include SetsCurrentOrganization
  include PermissionCheck

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_current_user
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private

  def set_current_user
    Current.user = current_user
    PaperTrail.request.whodunnit = current_user&.id&.to_s
  end

  def user_not_authorized
    respond_to do |format|
      format.html do
        render template: "errors/forbidden", status: :forbidden
      end
      format.any { head :forbidden }
    end
  end
end
