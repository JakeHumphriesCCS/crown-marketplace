class SuppliersController < ApplicationController
  def master_vendors
    @back_path = search_question_path(
      slug: 'managed-service-provider',
      params: managed_service_provider_params
    )
    @suppliers = Supplier.with_master_vendor_rates
  end

  private

  def managed_service_provider_params
    params.permit(:hire_via_agency, :master_vendor)
  end
end
