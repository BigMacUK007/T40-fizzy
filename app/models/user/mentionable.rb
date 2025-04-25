module User::Mentionable
  extend ActiveSupport::Concern

  included do
    has_many :mentions, dependent: :destroy, inverse_of: :mentionee
  end

  def mentioned_by(mentioner, at:)
    mentions.find_or_create_by! source: at, mentioner: mentioner
  end

  def mentionable_handles
    [ initials, first_name, first_name_with_last_name_initial ].collect(&:downcase)
  end

  private
    def first_name_with_last_name_initial
      "#{first_name}#{last_name&.first}"
    end
end
