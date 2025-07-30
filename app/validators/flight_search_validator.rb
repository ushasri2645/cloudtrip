
  class FlightSearchValidator
    attr_reader :errors, :params

    def initialize(params)
      @params = params
      @errors = []
    end

    def valid?
      validate_required(:source, "Source is missing")
      validate_required(:destination, "Destination is missing")
      validate_required(:date, "Date is missing")
      validate_different_source_and_destination
      parsed_date.present? && errors.empty?
    end

    def source
      params[:source].to_s.strip.downcase
    end

    def destination
      params[:destination].to_s.strip.downcase
    end

    def class_type
      params[:class_type].presence&.strip&.downcase || "economy"
    end

    def passengers
      (params[:passengers] || 1).to_i
    end

    def parsed_date
      @parsed_date ||= begin
        Date.parse(params[:date].to_s)
      rescue ArgumentError
        errors << "Invalid date format"
        nil
      end
    end

    private

    def validate_required(key, message)
      errors << message if params[key].blank?
    end

    def validate_different_source_and_destination
      if params[:source].present? && params[:destination].present? &&
         params[:source].casecmp?(params[:destination])
        errors << "Source and Destination must be different"
      end
    end
  end
