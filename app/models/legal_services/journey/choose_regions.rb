module LegalServices
  class Journey::ChooseRegions
    include Steppable

    attribute :region_codes, Array
    validates :region_codes, length: { minimum: 1 }

    def regions
      Nuts1Region.where(code: region_codes)
    end

    def lot(lot_number)
      LegalServices::Lot.find_by(number: lot_number)
    end

    def next_step_class
      Journey::Suppliers
    end
  end
end