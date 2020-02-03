module FacilitiesManagement
  class SupplierDetail < ApplicationRecord
    belongs_to :user, foreign_key: :user_id, inverse_of: :supplier_detail, validate: false
  end
end