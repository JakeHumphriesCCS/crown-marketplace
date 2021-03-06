module ManagementConsultancy
  class SuppliersController < FrameworkController
    helper :telephone_number
    before_action :fetch_suppliers, only: %i[index download]
    before_action :set_back_path

    def index
      @journey = Journey.new(params[:slug], params)
      @back_path = @journey.previous_step_path
      @lot = Lot.find_by(number: params[:lot])
      @suppliers = Kaminari.paginate_array(@all_suppliers).page(params[:page])
    end

    def show
      @supplier = Supplier.find(params[:id])
      @lot = Lot.find_by(number: params[:lot])
      @rate_card = @supplier.rate_cards.where(lot: params[:lot]).first
    end

    def download
      respond_to do |format|
        format.html
        format.xlsx do
          spreadsheet_builder = ManagementConsultancy::SupplierSpreadsheetCreator.new(@all_suppliers, params)
          spreadsheet = spreadsheet_builder.build
          render xlsx: spreadsheet.to_stream.read, filename: "shortlist_of_management_consultancy_suppliers.xlsx_#{DateTime.now.getlocal.strftime '%d-%m-%Y'}", format: 'application/vnd.openxmlformates-officedocument.spreadsheetml.sheet'
        end
      end
    end

    private

    def fetch_suppliers
      @all_suppliers = Supplier.offering_services_in_regions(
        params[:lot],
        params[:services],
        params[:region_codes]
      ).order(:name)
    end

    def set_back_path
      @back_path = :back
    end
  end
end
