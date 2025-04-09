# frozen_string_literal: true

class UserRegistrationsController < Devise::RegistrationsController
  before_action :check_permissions, only: [:edit, :update]
  skip_before_action :require_no_authentication

  def create
    build_resource(spree_user_params)
    if resource.save
      set_user_group(resource) if current_store&.enforce_group_upon_signup
      set_flash_message(:notice, :signed_up)
      sign_in(:spree_user, resource)
      session[:spree_user_signup] = true
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords(resource)
      respond_with(resource) do |format|
        format.html { render :new }
      end
    end
  end

  protected

  def translation_scope
    'devise.user_registrations'
  end

  def check_permissions
    authorize!(:create, resource)
  end

  private

  def spree_user_params
    params.require(:spree_user).permit(Spree::PermittedAttributes.user_attributes | [:email])
  end

  # Sets the user group for a user if they don't have one assigned
  # This method checks if there's a user and if they don't have a user group on sign up
  # If these conditions are met, it assigns the default cart user group from the current store
  # If enforce_group_upon_signup is enabled on the store settings
  def set_user_group(user)
    if user && user.user_group.nil?
      user_group = current_store.default_cart_user_group
      user.update(user_group: user_group) if user_group
    end
  end
end
