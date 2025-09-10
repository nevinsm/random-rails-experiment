class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      flash.now[:alert] = "Could not update profile."
      render :show, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name)
  end
end


