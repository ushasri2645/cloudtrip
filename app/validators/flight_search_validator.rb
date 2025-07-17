class FlightSearchValidator
  attr_reader :errors, :params

  def initialize(params)
    @params = params
    @errors = []
  end

  def valid?
    validate_presence(:source, "Source is missing")
    validate_presence(:destination, "Destination is missing")
    validate_presence(:date, "Date is missing")
    validate_source_destination_difference
    errors.empty?
  end

  def passengers
    (params[:passengers] || 1).to_i
  end

  def class_type
    params[:class_type].presence || "economy"
  end

  private

  def validate_presence(key, message)
    errors << message if params[key].blank?
  end

  def validate_source_destination_difference
    if params[:source].present? && params[:destination].present? &&
       params[:source].casecmp?(params[:destination])
      errors << "Source and Destination must be different"
    end
  end
end
