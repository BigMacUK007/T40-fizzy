class Message < ApplicationRecord
  belongs_to :card, touch: true

  delegated_type :messageable, types: Messageable::TYPES, inverse_of: :message, dependent: :destroy

  after_create -> { messageable.created_via_message }

  scope :chronologically, -> { order created_at: :asc, id: :desc }
end
