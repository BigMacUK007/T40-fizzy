class JoinCodesController < ApplicationController
  disallow_account_scope
  allow_unauthenticated_access

  before_action :set_join_code
  before_action :ensure_join_code_is_valid

  layout "public"

  def new
  end

  def create
    identity = Identity.find_or_create_by!(email_address: params.expect(:email_address))

    unless identity.member_of?(@join_code.account)
      @join_code.redeem do |account|
        identity.join(account)
      end

      magic_link = identity.send_magic_link
      flash[:magic_link_code] = magic_link&.code if Rails.env.development?

      session[:return_to_after_authenticating] = new_users_join_url(script_name: @join_code.account.slug)
      redirect_to session_magic_link_path
    else
      redirect_to landing_url(script_name: @join_code.account.slug)
    end
  end

  private
    def set_join_code
      # TODO:PLANB: this find should be scoped by account
      #      2025-11-12 [Stanko]: I think that we don't have to scope this by account as the code
      #                           is globally unique and indexed. Except if we need to scope it
      #                           for some other reason?
      @join_code ||= Account::JoinCode.active.find_by(code: code)
    end

    def ensure_join_code_is_valid
      head :not_found unless @join_code&.active?
    end

    def tenant
      params.expect(:tenant)
    end

    def code
      params.expect(:code)
    end
end
