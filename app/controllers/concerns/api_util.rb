require 'json'

module ApiUtil
  #
  module_function
  def validate_type(base, key, type)
    unless base.is_a?(Hash)
      raise "non Hash value was given"
    end

    unless base.has_key?(key)
      raise "#{key} was not given"
    end
    unless base[key].is_a?(type)
      raise "type of #{key} must be #{type} (but #{base[key].class})"
    end

    return base[key]
  end


  #
  module_function
  def validate_array(base, key, min, max)
    validate_type(base, key, Array)

    unless base[key].length >= min && base[key].length <= max
      raise "a number of #{key} must be [#{min}, #{max}]"
    end

    return base[key]
  end


  #
  module_function
  def get_api_version(params)
    unless params.has_key?("api_version")
      raise "api_version was not given"
    end
    return params["api_version"].to_i
  end


  #
  module_function
  def extract_value(params)
    # ========================================
    # type
    # ========================================
    unless params.has_key?("type")
      raise "'type' field was not given to request"
    end
    unless params["type"] == "json"
      raise "only json format is supported"
    end

    # ========================================
    # value
    # ========================================
    unless params.has_key?("value")
      return nil
    end
    return JSON.parse(validate_type(params, "value", String))
  end
end
