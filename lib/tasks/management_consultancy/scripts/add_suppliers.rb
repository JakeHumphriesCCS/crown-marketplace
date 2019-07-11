require 'roo'
require 'json'
require 'capybara'

def add_suppliers
  suppliers_workbook_filepath = Rails.root.join('storage', 'management_consultancy', 'current_data', 'input', 'Suppliers.xlsx')
  suppliers_workbook = Roo::Spreadsheet.open(suppliers_workbook_filepath, extension: :xlsx)

  headers = {
    name: 'Supplier name',
    contact_email: 'Email address',
    telephone_number: 'Phone number',
    website: 'Website URL',
    address: 'Postal address',
    sme: 'Is an SME?',
    duns: 'DUNS Number',
    clean: true
  }

  mcf_sheet = suppliers_workbook.sheet(0)

  suppliers = mcf_sheet.parse(headers)

  mcf2_sheet = suppliers_workbook.sheet(1)

  suppliers += mcf2_sheet.parse(headers)

  suppliers.delete_if { |supplier| supplier[:duns].nil? }

  suppliers.uniq! { |supplier| supplier[:duns] }

  suppliers.each do |supplier|
    supplier[:sme] = ['YES', 'Y'].include? supplier[:sme].to_s.upcase
    supplier[:id] = SecureRandom.uuid
  end

  File.open(get_mc_output_file_path('suppliers.json'), 'w') do |f|
    f.puts JSON.pretty_generate(suppliers)
  end
end