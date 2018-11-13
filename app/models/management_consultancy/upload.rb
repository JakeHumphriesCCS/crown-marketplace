module ManagementConsultancy
  class Upload
    def self.create!(suppliers)
      error = all_or_none(Supplier) do
        Supplier.destroy_all

        suppliers.map do |supplier_data|
          create_supplier!(supplier_data)
        end
      end
      raise error if error
    end

    def self.all_or_none(transaction_class)
      error = nil
      transaction_class.transaction do
        yield
      rescue ActiveRecord::RecordInvalid => e
        error = e
        raise ActiveRecord::Rollback
      end
      error
    end

    def self.create_supplier!(data)
      supplier = Supplier.create!(
        id: data['supplier_id'],
        name: data['supplier_name']
      )

      lots = data.fetch('lots', [])
      lots.each do |lot|
        lot_number = lot['lot_number']
        services = lot.fetch('services', [])
        services.each do |service|
          supplier.service_offerings.create!(
            lot_number: lot_number,
            service_code: service
          )
        end
      end
    end
  end
end