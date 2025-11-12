module Identity::Joinable
  extend ActiveSupport::Concern

  def join(account)
    transaction do
      membership = memberships.create!(tenant: account.external_account_id)
      account.users.create!(membership: membership, name: email_address)
    end
  end

  def member_of?(account)
    memberships.exists?(tenant: account.external_account_id.to_s)
  end
end
