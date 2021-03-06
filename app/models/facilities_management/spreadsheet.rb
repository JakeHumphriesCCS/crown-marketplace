class FacilitiesManagement::Spreadsheet
  def initialize(report, current_lot, data)
    @report = report
    @current_lot = current_lot
    @data = data
    create_spreadsheet
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def row(buildings, idx)
    vals = []
    i = 1
    buildings.each do |building|
      str =
        case idx
        when 0
          "Building #{i} - #{building.building_json['name']}"
        when 1
          building.building_json['fm-building-type']
        when 2
          building.building_json['address']['fm-address-line-1']
        when 3
          building.building_json['address']['fm-address-town']
        when 4
          building.building_json['address']['fm-address-county']
        when 5
          building.building_json['address']['fm-address-postcode']
        when 6
          building.building_json['gia']
        end
      vals << str

      i += 1
    end
    vals
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def to_xlsx
    @package.to_stream.read
  end

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Style/ConditionalAssignment
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def create_spreadsheet
    @package = Axlsx::Package.new
    @workbook = @package.workbook

    selected_buildings = @report.user_buildings

    services_selected = selected_buildings.collect { |b| b.building_json['services'] }.flatten # s.collect { |s| s['code'].gsub('-', '.') }
    services_selected.uniq!

    @workbook.add_worksheet(name: 'Building Information') do |sheet|
      # sheet.add_row ['Buildings information']
      i = 0
      [['Buildings information', nil],
       ['Building Type', 'eg. General office - customer facing, non customer facing, call centre operations.'],
       ['Address', ''],
       [nil, nil], [nil, nil], [nil, nil],
       ['GIA', 'Gross Internal Area: Square Metre (GIA) per annum']].each do |label|
        vals = []
        vals << label[0] << label[1] << row(selected_buildings, i)
        vals.flatten!
        sheet.add_row vals
        i += 1
      end
    end

    # selected_services = services_selected.map { |s| s['code'].gsub('-', '.') }
    services = @report.list_of_services # @report.selected_services(selected_services)
    uom_values_for_selected_buildings = @report.uom_values(selected_buildings)

    uoms = CCS::FM::UnitsOfMeasurement.all.group_by(&:service_usage)
    uom2 = {}
    uoms.map { |u| u[0].each { |k| uom2[k] = u[1] } }

    @workbook.add_worksheet(name: 'Service Matrix') do |sheet|
      i = 1
      vals = ['Work Package', 'Service Reference', 'Service Name', 'Unit of Measure']
      selected_buildings.each do |building|
        vals << 'Building ' + i.to_s + ' - ' + building.building_json['name']
        i += 1
      end
      sheet.add_row vals

      work_package = ''
      services.sort_by { |s| [s.work_package_code, s.code[s.code.index('.') + 1..-1].to_i] }.each do |s|
        if work_package == s.work_package_code
          label = nil
        else
          label = 'Work Package ' + s.work_package_code + ' - ' + s.work_package.name
        end

        work_package = s.work_package_code

        vals = [label, s.code, s.name]

        vals_v = []
        vals_h = nil
        uom_labels_2d = []
        selected_buildings.each do |building|
          id = building.building_json['id']
          suv = uom_values_for_selected_buildings.select { |v| v['building_id'] == id && v['service_code'] == s.code }

          any_suv = uom_values_for_selected_buildings.select { |v| v['service_code'] == s.code }

          vals_h = []
          uom_labels = []
          if suv.empty?
            if uom2[s.code]
              uom_labels << uom2[s.code].last.spreadsheet_label
            elsif s.work_package_code == 'A' || s.work_package_code == 'B'
              uom_labels << nil
            elsif s.work_package_code == 'M' || s.work_package_code == 'N'
              uom_labels << 'Percentage of Year 1 Deliverables Value (excluding Management and Corporate Overhead, and Profit) at call-off'
            elsif any_suv.empty?
              uom_labels << 'service (per annum)'
            end

            vals_h << nil
          else
            suv.each do |v|
              if v['spreadsheet_label']
                uom_labels << v['spreadsheet_label']
              elsif uom2[s.code]
                uom_labels << uom2[s.code].last.spreadsheet_label
              end

              vals_h << v['uom_value']
            end
          end
          vals_v << vals_h
          uom_labels_2d << uom_labels
        rescue StandardError
          vals << '=NA()'
        end

        uom_labels_max = uom_labels_2d.max

        max_j = vals_v.map(&:length).max
        if max_j
          (0..max_j - 1).each do |j|
            vals << uom_labels_max[j]

            (0..vals_v.count - 1).each do |k|
              vals << vals_v[k][j]
            end
            sheet.add_row vals

            vals = [nil, s.code, s.name]
          end
        end
        # end
        work_package = s.work_package_code
      end
    end

    @workbook.add_worksheet(name: 'Procurement summary') do |sheet|
      date = sheet.styles.add_style(format_code: 'dd mmm yyyy', border: Axlsx::STYLE_THIN_BORDER)
      left_align = sheet.styles.add_style(alignment: { horizontal: :left })
      ccy = sheet.styles.add_style(format_code: '£#,##0')

      sheet.add_row ['CCS reference number & date/time of production of this document']
      sheet.add_row
      sheet.add_row ['1. Customer details']
      sheet.add_row ['Name']
      sheet.add_row ['Organisation']
      sheet.add_row ['Position']
      sheet.add_row ['Contact details']
      sheet.add_row
      sheet.add_row ['2. Contract requirements']
      sheet.add_row ['Initial Contract length', @report.contract_length_years, 'years'], style: [nil, nil, left_align]
      sheet.add_row ['Extensions']
      sheet.add_row
      sheet.add_row ['Tupe involvement', @report.tupe_flag]
      sheet.add_row
      sheet.add_row ['Contract start date', @report.start_date&.to_date], style: [nil, date]
      sheet.add_row
      sheet.add_row ['3. Price and sub-lot recommendation']
      sheet.add_row ['Assessed Value', @report.assessed_value], style: [nil, ccy]
      sheet.add_row ['Assessed value estimated accuracy'], style: [nil, ccy]
      sheet.add_row
      sheet.add_row ['Lot recommendation', @report.current_lot]
      sheet.add_row ['Direct award option']
      sheet.add_row
      # sheet.add_row ['4. Supplier Shortlist']
      label = '4. Supplier Shortlist'
      @report.selected_suppliers(@current_lot).each do |supplier|
        sheet.add_row [label, supplier.data['supplier_name']]
        label = nil
      end
      sheet.add_row

      # sheet.add_row ['5. Regions summary']
      label = '5. Regions summary'
      FacilitiesManagement::Region.all.select { |region| @data[:posted_locations].include? region.code }.each do |region|
        sheet.add_row [label, region.name]
        label = nil
      end
      sheet.add_row

      # sheet.add_row ['6 Services summary']
      # services = FacilitiesManagement::Service.where(code: @data['posted_services'])
      services = @report.list_of_services
      services.sort_by!(&:name)
      label = '6 Services summary'
      services.each do |s|
        sheet.add_row [label, s.name]
        label = nil
      end
      sheet.add_row
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Style/ConditionalAssignment
  # rubocop:enable Metrics/BlockLength
end
